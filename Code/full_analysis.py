from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Estimate every model and descriptive series used in the SURA-format revision."""
from pathlib import Path
import json
import runpy
import sys
import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.stats import norm
from scipy.special import expit
from statsmodels.miscmodels.ordinal_model import OrderedModel
from statsmodels.tools.numdiff import approx_fprime

base=Path(__file__).parent
state=runpy.run_path(str(base/'analysis.py'))
main,child,tsp=state['main'],state['child'],state['t']
design=state['design']
controls=state['primary_controls']
out={'models':{},'ordered':{},'descriptive':{},'figures':{},'summary':state['results']}
def scalar(x):return x.item() if isinstance(x,np.generic) else x
def collect(fit):
    result={'n':int(fit.nobs),'terms':{}}
    for term in fit.params.index:
        result['terms'][term]={'b':float(fit.params[term]),'se':float(fit.bse[term]),'p':float(fit.pvalues[term])}
    if hasattr(fit,'rsquared'):result['r2']=fit.rsquared
    return result
def fit(key,y,df=main,x='ce_good',cov=controls,linear=False,cluster='communityID'):
    d=df.dropna(subset=[y,x,cluster]+cov).copy()
    X=design(d,[x]+cov)
    mod=sm.OLS(d[y],X) if linear else sm.Probit(d[y],X)
    kw={'cov_type':'cluster','cov_kwds':{'groups':d[cluster]}}
    res=mod.fit(**kw) if linear else mod.fit(disp=False,**kw)
    out['models'][key]=collect(res)
    return d
emo=fit('emotional_ols','affect',linear=True)
emo['affect6']=(emo.affect>=6).astype(float)
fit('emotional_probit','affect6',emo)
for cutoff in [2,4,6,8,9]:
    emo['cut']=(emo.affect>=cutoff).astype(float)
    fit(f'emotional_{cutoff}','cut',emo)
health=fit('health_fair','fair')
for outcome in ['good','top']:fit('health_'+outcome,outcome)
for outcome in ['fair','good']:fit('offspring_'+outcome,outcome,child)

def ordered(key,df,y):
    d=df.dropna(subset=[y,'ce_good','communityID']+controls)
    original=design(d,['ce_good']+controls).drop(columns='const')
    mean,sd=original.mean(),original.std()
    scaled=(original-mean)/sd
    mod=OrderedModel(d[y],scaled,distr='logit')
    res=mod.fit(method='bfgs',disp=False,maxiter=500,cov_type='cluster',cov_kwds={'groups':d.communityID})
    if not res.mle_retvals['converged']:raise RuntimeError('Ordered model failed')
    dims=original.shape[1]
    terms={}
    for name in ['ce_good','age','age_2','female','education_group_2.0','education_group_3.0','education_group_4.0','education_group_5.0','urban_nbs']:
        j=original.columns.get_loc(name)
        binary=name not in ['age','age_2']
        def effects(beta):
            if binary:
                low,high=scaled.copy(),scaled.copy()
                if name.startswith('education_group'):
                    for term in original.columns:
                        if term.startswith('education_group'):
                            low[term]=(0-mean[term])/sd[term]
                            high[term]=(0-mean[term])/sd[term]
                low[name]=(0-mean[name])/sd[name];high[name]=(1-mean[name])/sd[name]
                return (mod.predict(beta,high)-mod.predict(beta,low)).mean(axis=0)
            cuts=mod.transform_threshold_params(beta)
            eta=scaled.to_numpy()@beta[:dims]
            cdf=expit(cuts[None,:]-eta[:,None])
            density=cdf*(1-cdf)
            return ((density[:,:-1]-density[:,1:])*beta[j]/sd[name]).mean(axis=0)
        b=effects(res.params.to_numpy())
        jac=approx_fprime(res.params.to_numpy(),effects,centered=True)
        var=jac@res.cov_params().to_numpy()@jac.T
        se=np.sqrt(np.maximum(np.diag(var),0))
        terms[name]=[{'b':float(a),'se':float(s),'p':float(2*norm.sf(abs(a/s)))} for a,s in zip(b,se)]
    out['ordered'][key]={'n':len(d),'terms':terms}
emo['ordered_score']=pd.cut(emo.affect,[-1,2,4,6,8,10],labels=[1,2,3,4,5]).astype(int)
ordered('emotional',emo,'ordered_score')
ordered('health',health,'rating')
for suffix in ['', '_total']:
    x='TSP'+suffix
    fit(x,'fair',tsp,x,state['controls']+['temperature'+suffix],cluster='city_eng')
    from full_iv import fit_full_iv
    out['models']['iv_'+x]=fit_full_iv(tsp,x,design(tsp,['temperature'+suffix]+state['controls']),['sea_level'+suffix,'wind_speed'+suffix],'city_eng')
def describe(df,col):
    x=df[col].dropna()
    return [len(x),float(x.mean()),float(x.std()),float(x.min()),float(x.max())]
out['descriptive']['rows']=[
 ['Emotional response count',*describe(emo,'affect')],
 ['Emotional count ≥ 6',*describe(emo,'affect6')],
 ['Health fair or better',*describe(health,'fair')],
 ['Childhood neighborhood',*describe(health,'ce_good')],
 ['TSP of the birth year',*describe(tsp,'TSP')],
 ['Weighted TSP index',*describe(tsp,'TSP_total')],
 *[[label,*describe(health,c)] for label,c in [('Age','age'),('Age square','age_2'),('Female','female'),('Education group','education_group')]],
 *[[label,*describe(tsp,c)] for label,c in [('Birth-year temperature','temperature'),('Weighted temperature','temperature_total')]],
 ['Urban',*describe(health,'urban_nbs')],
 *[[label,*describe(tsp,c)] for label,c in [('Birth-year pressure','sea_level'),('Weighted pressure','sea_level_total'),('Birth-year wind speed','wind_speed'),('Weighted wind speed','wind_speed_total')]]]
health['rating_group']=pd.cut(health.rating,[0,2,3,5],labels=[1,2,3]).astype(int)
out['figures']['health_shares']=pd.crosstab(health.ce_good,health.rating_group,normalize='index').values.tolist()
out['figures']['health_counts']=health.groupby('ce_good').size().tolist()
for key,groups in [('age',pd.cut(health.age,[44,54,64,np.inf],labels=['45–54','55–64','65+'])),('education',pd.Series(np.where(health.education_group>=4,'Middle school and above','Below middle school'),index=health.index))]:
    g=health.assign(group=groups).groupby(['group','ce_good'],observed=True).fair.agg(['mean','size'])
    out['figures'][key]=[{'group':str(a),'ce_good':int(b),'mean':float(r['mean']),'n':int(r['size'])} for (a,b),r in g.iterrows()]
# Preserve the historical descriptive figures' quartic source but retain a city once in each urban/rural stratum.
from zipfile import ZipFile
with ZipFile(sys.argv[1]) as z:
    with z.open('Qiu/Raw_data/charls_community_tsp_quartic.dta') as handle:
        history=pd.read_stata(handle,convert_categoricals=False)
cols=[f'pollution_{year}' for year in range(1981,1996)]
strata=history.drop_duplicates(['city','urban_nbs']).groupby('urban_nbs')[cols].mean()
out['figures']['urban_rural']={str(int(k)):v.tolist() for k,v in strata.iterrows()}
out['figures']['historical_cities']={}
for name,cn in [('Beijing','北京'),('Harbin','哈尔滨市'),('Chongqing','重庆市'),('Shanghai','上海市')]:
    out['figures']['historical_cities'][name]=history.loc[history.city.eq(cn),cols].iloc[0].tolist()
(results_dir('main')/'full_results.json').write_text(json.dumps(out,indent=2,default=scalar)+'\n')
print('All table coefficients and plot series saved.',flush=True)
