from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Rebuild the paper's aggregate results from the untouched project archive."""
import argparse
import json
from pathlib import Path
from zipfile import ZipFile

import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.special import ndtr
from scipy.stats import norm
from statsmodels.miscmodels.ordinal_model import OrderedModel
from ivprobit import fit_iv

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('archive', type=Path)
parser.add_argument('--output', type=Path, default=results_dir('main')/'estimates.json')
args = parser.parse_args()
archive = ZipFile(args.archive)
names = {n.lower(): n for n in archive.namelist()}
def read(folder, name, columns):
    key = f'Qiu/{folder}/{name}.dta'.lower()
    with archive.open(names[key]) as handle:
        return pd.read_stata(handle, columns=columns, convert_categoricals=False).replace('', np.nan)

def raw(year, name, columns):
    return read(f'Raw_data/{year}', name, columns)

def valid(series, lo, hi):
    return series.where(series.between(lo, hi))

def binary(series, threshold):
    return series.ge(threshold).astype(float).where(series.notna())

common = ['ID', 'age', 'age_2', 'female', 'education_group', 'urban_nbs', 'communityID', 'year']
controls = ['age', 'age_2', 'female', 'education_group', 'urban_nbs']
primary_controls = controls + ['year']
items = [f'dc{i:03}' for i in range(9, 19)]
family = raw(2014, 'Family_Information', ['ID', 'd5', 'c4_a'])
family['ce_good'] = binary(5 - valid(family.d5, 1, 4), 3)
family['finance'] = valid(family.c4_a, 1, 5)
respondents, offspring = [], []
for year in [2011, 2013, 2015, 2018]:
    base = read('Working_data', f'{year}_main_y_x_control', common)
    columns = ['ID', 'householdID', 'da002']
    if year < 2018:
        columns += ['da001', 'dc028'] + items
    health = raw(year, 'Health_Status_and_Functioning', columns)
    if year == 2011:
        health.ID = health.householdID + '0' + health.ID.str[-2:]
    # Common scale: 1 very poor, 2 poor, 3 fair, 4 good, 5 very good or excellent.
    health['rating'] = 6 - valid(health.da002, 1, 5)
    if year < 2018:
        alternate = (7 - valid(health.da001, 1, 5)).clip(upper=5)
        health.rating = health.rating.fillna(alternate)
    else:
        health = health.merge(raw(year, 'Cognition', ['ID', 'dc028'] + items), on='ID', how='outer', validate='1:1')
    health['satisfied'] = binary(6 - valid(health.dc028, 1, 5), 4)
    responses = health[items]
    favorable = responses.eq(1)
    favorable[['dc013', 'dc016']] = responses[['dc013', 'dc016']].eq(4)
    health['affect'] = favorable.sum(axis=1).where(responses.isin([1, 2, 3, 4]).all(axis=1))
    respondents.append(base.merge(health[['ID','rating','satisfied','affect']], on='ID', how='left',validate='1:1'))
    if year >= 2015:
        child = read('Working_data', f'{year}_child_d5', common + ['health_status'])
        child['rating'] = valid(child.health_status, 1, 5)
        offspring.append(child)
def survey(parts):
    df = pd.concat(parts, ignore_index=True).merge(family, on='ID', how='left', validate='m:1')
    df = df.loc[df.age.ge(18)].copy()
    for level, label in [(3, 'fair'), (4, 'good'), (5, 'top')]:
        df[label] = binary(df.rating, level)
    return df
main = survey(respondents)
child = survey(offspring)
results = {'survey': {}, 'samples': {}, 'tsp': {}, 'figure': []}

def design(df, cols):
    categories = [name for name in ['education_group','year','finance','province_eng','cohort'] if name in cols]
    return sm.add_constant(pd.get_dummies(df[cols], columns=categories, drop_first=True, dtype=float),has_constant='add').astype(float)
def interval(estimate, se):
    return dict(estimate=float(estimate), low=float(estimate-1.96*se), high=float(estimate+1.96*se), se=float(se))
def survey_fit(key, df, y, cov=primary_controls, linear=False):
    d = df.dropna(subset=[y,'ce_good','communityID']+cov)
    X = design(d, ['ce_good']+cov)
    options = dict(cov_type='cluster',cov_kwds={'groups':d.communityID})
    if linear:
        model = sm.OLS(d[y],X).fit(**options)
        effect = interval(model.params.ce_good,model.bse.ce_good)
    else:
        model = sm.Probit(d[y],X).fit(disp=False, **options)
        x0, x1 = X.copy(), X.copy()
        x0['ce_good'], x1['ce_good'] = 0., 1.
        xb0, xb1 = x0 @ model.params, x1 @ model.params
        gradient = (x1.mul(norm.pdf(xb1),axis=0)-x0.mul(norm.pdf(xb0),axis=0)).mean()
        effect = interval(100*(ndtr(xb1)-ndtr(xb0)).mean(),100*np.sqrt(gradient @ model.cov_params() @ gradient))
    results['survey'][key] = dict(n=len(d), clusters=d.communityID.nunique(), **effect)
    return d
m = survey_fit('main_fair', main, 'fair')
c = survey_fit('child_fair', child, 'fair')
for key, d in [('main',m),('child',c)]:
    results['samples'][key] = dict(n=len(d), by_year=d.year.value_counts().sort_index().to_dict(),
        id_count=d.ID.nunique(), age=d.age.mean(), female=d.female.mean(), urban=d.urban_nbs.mean(),
        clean=d.ce_good.mean(), fair=d.fair.mean(), communities=d.communityID.nunique())
for outcome in ['good','top','satisfied','affect']:
    survey_fit('main_'+outcome, main, outcome, linear=outcome=='affect')
survey_fit('main_wave2018',main.loc[main.year.eq(2018)],'fair',controls)
survey_fit('main_finance_base',m.dropna(subset=['finance']),'fair')
survey_fit('main_finance', m, 'fair', primary_controls+['finance'])
survey_fit('child_good',child,'good')
for d5,d in m.groupby('d5'):
    results['figure'].append(dict(d5=int(d5),n=len(d),percent=100*d.fair.mean()))

exposures = ['TSP','temperature','sea_level','wind_speed']
tsp = read('Working_data','All_TSP_Meteor',common+['health_status','city_eng','province_eng','byear','birthyear','xchildbirth__']+
           [v+s for v in exposures for s in ['', '_total']])
tsp['cohort'] = tsp[['byear','birthyear','xchildbirth__']].bfill(axis=1).iloc[:,0]
tsp['rating'] = valid(tsp.health_status,1,5)
# Respondent rows carry birthyear. Use their scale-harmonized responses.
ratings = main.dropna(subset=['rating']).set_index(['ID','year']).rating
mask = tsp.birthyear.notna()
index = pd.MultiIndex.from_frame(tsp.loc[mask,['ID','year']])
tsp.loc[mask,'rating'] = ratings.reindex(index).to_numpy()
tsp['fair'] = binary(tsp.rating,3)
needed = ['city_eng','province_eng','cohort','rating','fair','communityID']+controls+[v+s for v in exposures for s in ['', '_total']]
t = tsp.loc[tsp.age.ge(18)].dropna(subset=needed).copy()
results['samples']['tsp']=dict(n=len(t), cities=t.city_eng.nunique(), provinces=t.province_eng.nunique(), communities=t.communityID.nunique(),
    main=int(t.birthyear.notna().sum()), ages=[t.age.min(),t.age.max()], fair=t.fair.mean(), years=t.year.value_counts().to_dict())
for suffix in ['', '_total']:
    x='TSP'+suffix
    weather='temperature'+suffix
    z=['sea_level'+suffix,'wind_speed'+suffix]
    X=design(t,[x,weather]+controls)
    clusters=dict(cov_type='cluster',cov_kwds={'groups':t.city_eng})
    probit=sm.Probit(t.fair,X).fit(disp=False,**clusters)
    out={'probit':interval(probit.params[x],probit.bse[x])}
    # Percent-point difference for a 100-unit change, linear probability model.
    XF=design(t,[x,weather]+controls+['province_eng','cohort'])
    lpm=sm.OLS(t.fair,XF).fit(**clusters,use_t=True)
    ci=lpm.conf_int().loc[x]*10000
    out['fixed_effects']=dict(estimate=lpm.params[x]*10000,low=ci.iloc[0],high=ci.iloc[1])
    scaled=X.drop(columns='const')
    scaled=(scaled-scaled.mean())/scaled.std()
    ordered=OrderedModel(t.rating,scaled,distr='logit').fit(method='bfgs',disp=False,**clusters)
    out['ordered']=interval(ordered.params[x],ordered.bse[x])
    F=design(t,z+[weather]+controls)
    first=sm.OLS(t[x],F).fit(**clusters)
    test=first.f_test(np.eye(len(first.params))[[F.columns.get_loc(v) for v in z]])
    out['first_stage']={'F':float(test.fvalue),'num_df':int(test.df_num),'den_df':int(test.df_denom)}
    out['iv']=fit_iv(t, x, design(t,[weather]+controls),z,'city_eng')
    results['tsp'][x]=out
archive.close()
args.output.write_text(json.dumps(results,indent=2,default=lambda x:x.item() if isinstance(x,np.generic) else str(x))+'\n')
