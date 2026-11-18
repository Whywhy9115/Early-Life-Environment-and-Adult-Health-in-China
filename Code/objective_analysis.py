from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Rebuild measured outcomes from the untouched Qiu archive; aggregate outputs only."""
from pathlib import Path
from zipfile import ZipFile
import argparse,json,re,warnings
import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.stats import t,norm
from statsmodels.stats.multitest import multipletests

ap=argparse.ArgumentParser();ap.add_argument('archive',type=Path);args=ap.parse_args()
root=results_dir('objective')
z=ZipFile(args.archive);names={n.lower():n for n in z.namelist() if not n.startswith('__MACOSX')}
def read(path,cols=None):
    with z.open(names[path.lower()]) as f:return pd.read_stata(f,columns=cols,convert_categoricals=False)
def raw(year,name,cols=None):return read(f'Qiu/Raw_data/{year}/{name}.dta',cols)
def labels(path):
    with z.open(names[path.lower()]) as f:
        with pd.io.stata.StataReader(f) as r:return r.variable_labels()
def valid(s,low,high):return s.where(s.between(low,high))
def merge(a,b,on,how='left',validate='1:1'):return a.merge(b,on=on,how=how,validate=validate)

family=raw(2014,'Family_Information',['ID','d5','c4_a'])
family['ce_good']=valid(family.d5,1,4).le(2).astype(float).where(family.d5.between(1,4))
family['finance']=valid(family.c4_a,1,5)
res=raw(2014,'Residence')
life=res[['ID','rbirthyear','rgender','t001b_1_','t001a_1_']].copy()
life['birthyear']=valid(life.rbirthyear,1900,1997)
life['female']=life.rgender.eq(2).astype(float).where(life.rgender.isin([1,2]))
geo=raw(2013,'PSU',['communityID','province_eng','city_eng','urban_nbs'])
geo[['province_eng','city_eng']]=geo[['province_eng','city_eng']].replace('',np.nan)
allwaves={};out={'flow':{},'models':{},'descriptive':{},'quality':{},'huai':{},'sources':{}}
for yr in [2011,2013,2015]:
    b=raw(yr,'biomarkers' if yr==2011 else 'Biomarker')
    if yr==2011:b['ID']=b.householdID+'0'+b.ID.str[-2:]
    assert b.ID.is_unique
    flow={'biomarker_records':len(b)}
    # Keep each measurement's sentinel codes out of all aggregation operations.
    pef=b[['qb002','qb003','qb004']].apply(lambda s:valid(s,30,890))
    sbp=[];dbp=[]
    for sc,dc in [('qa003','qa004'),('qa007','qa008'),('qa011','qa012')]:
        good=b[sc].between(50,300)&b[dc].between(30,200)&b[sc].gt(b[dc])
        sbp.append(b[sc].where(good));dbp.append(b[dc].where(good))
    sbp=pd.concat(sbp,axis=1);dbp=pd.concat(dbp,axis=1)
    measures=pd.DataFrame({'ID':b.ID,'communityID':b.communityID,
      'pef':pef.max(axis=1).where(pef.notna().sum(axis=1)>=2),
      'pef_trials':pef.notna().sum(axis=1),'sbp':sbp.mean(axis=1).where(sbp.notna().sum(axis=1)>=2),
      'dbp':dbp.mean(axis=1).where(dbp.notna().sum(axis=1)>=2),'height':valid(b.qi002,100,210),
      'pef_effort':b.qb005,'bp_compliance':b.qa015,'bp_position':b.qa016,'bp_recent':b.qa017,'height_compliance':b.qi003})
    d=merge(merge(measures,family,'ID'),life,'ID');d=merge(d,geo,'communityID',validate='m:1')
    d['age']=yr-d.birthyear;d['age_c']=d.age-60;d['age_c2']=d.age_c**2
    flow['valid_neighborhood']=int(d.ce_good.notna().sum())
    d=d.loc[d.age.ge(45)&d.ce_good.notna()].copy();flow['age45_neighborhood']=len(d)
    for y in ['pef','sbp','dbp','height']:flow[y+'_available']=int(d[y].notna().sum())
    out['flow'][str(yr)]=flow;allwaves[yr]=d

# Extra current-adult variables are restricted to a secondary 2015 specification.
d15=raw(2015,'Demographic_Background',['ID','bd001_w2_4','bb001','bb001_w3','bb003','bb005'])
d13=raw(2013,'Demographic_Background',['ID','bd001','zbd001','bb001'])
d11=raw(2011,'demographic_background',['ID','householdID','bd001','bb001'])
d11.ID=d11.householdID+'0'+d11.ID.str[-2:]
edu=merge(d15,d13.rename(columns={'bd001':'edu13','zbd001':'z_edu13','bb001':'born13'}),'ID')
edu=merge(edu,d11[['ID','bd001','bb001']].rename(columns={'bd001':'edu11','bb001':'born11'}),'ID')
edu['education']=valid(edu.bd001_w2_4,1,11).fillna(valid(edu.edu13,1,11)).fillna(valid(edu.z_edu13,1,11)).fillna(valid(edu.edu11,1,11))
edu['education_group']=edu.education.map({1:1,2:2,3:3,4:3,5:4,6:5,7:5,8:5,9:5,10:5,11:5})
# A carry-forward birthplace flag is only a provisional local-birth proxy, never a nonmigration proof.
edu['birthplace_proxy']=valid(edu.bb001,1,4).fillna(valid(edu.born13,1,4)).fillna(valid(edu.born11,1,4))
health=raw(2015,'Health_Status_and_Functioning',['ID','da059','da061'])
health['smoking']=np.nan
health.loc[health.da059.eq(2)|health.da061.eq(3),'smoking']=0
health.loc[health.da061.eq(2),'smoking']=1
health.loc[health.da061.eq(1),'smoking']=2
allwaves[2015]=merge(merge(allwaves[2015],edu[['ID','education_group','birthplace_proxy','bb001','bb001_w3','bb003','bb005']],'ID'),health[['ID','smoking']],'ID')
primary=['age_c','age_c2','female','province_eng','finance']
def design(d,cols):
    cats=[c for c in cols if c in ['province_eng','finance','education_group','smoking','year']]
    return sm.add_constant(pd.get_dummies(d[cols],columns=cats,drop_first=True,dtype=float),has_constant='add').astype(float)
def estimate(key,d,y,controls=primary,cluster='communityID'):
    ds=d.dropna(subset=[y,'ce_good',cluster]+controls).copy()
    X=design(ds,['ce_good']+controls)
    assert np.linalg.matrix_rank(X)==X.shape[1],key
    fit=sm.OLS(ds[y],X).fit(cov_type='cluster',cov_kwds={'groups':ds[cluster]},use_t=True)
    G=ds[cluster].nunique();q=t.ppf(.975,G-1)
    b=float(fit.params.ce_good);se=float(fit.bse.ce_good)
    out['models'][key]={'n':len(ds),'clusters':int(G),'cities':int(ds.city_eng.nunique()),'b':b,'se':se,'low':b-q*se,'high':b+q*se,'p':float(2*t.sf(abs(b/se),G-1)),'r2':float(fit.rsquared),'mean':float(ds[y].mean()),'sd':float(ds[y].std()),'standardized_b':b/float(ds[y].std()),'terms':{k:{'b':float(fit.params[k]),'se':float(fit.bse[k])} for k in X.columns}}
    return ds
for yr,d in allwaves.items():
    for y in ['pef','sbp','dbp','height']:
        primary_sample=estimate(f'{yr}_{y}_primary',d,y)
        if yr==2015:
            estimate(y+'_basic',primary_sample,y,['age_c','age_c2','female'])
            estimate(y+'_province',primary_sample,y,['age_c','age_c2','female','province_eng'])
            out['descriptive'][y]=[{'favorable':int(g),'n':len(x),'mean':float(x[y].mean()),'sd':float(x[y].std()),'age':float(x.age.mean()),'female':float(x.female.mean())} for g,x in primary_sample.groupby('ce_good')]
    pvals=[out['models'][f'{yr}_{y}_primary']['p'] for y in ['sbp','dbp','height']]
    for y,p in zip(['sbp','dbp','height'],multipletests(pvals,method='holm')[1]):out['models'][f'{yr}_{y}_primary']['p_holm_supplementary']=float(p)
d=allwaves[2015]
main=estimate('pef_city_cluster',d,'pef',cluster='city_eng')
estimate('pef_three_full_effort',d.loc[d.pef_trials.eq(3)&d.pef_effort.eq(1)],'pef')
estimate('pef_no_endpoints',d.loc[d.pef.gt(30)&d.pef.lt(890)],'pef')
estimate('pef_height_adjusted',d,'pef',primary+['height'])
estimate('pef_adult_adjusted',d,'pef',primary+['height','education_group','urban_nbs','smoking'])
adult=d.dropna(subset=['height','education_group','urban_nbs','smoking'])
estimate('pef_adult_common_base',adult,'pef')
estimate('height_45_64',d.loc[d.age.lt(65)],'height')
estimate('height_fully_compliant',d.loc[d.height_compliance.eq(1)],'height')
for y in ['sbp','dbp']:
    estimate(y+'_strict_protocol',d.loc[d.bp_compliance.eq(1)&d.bp_position.eq(2)&d.bp_recent.eq(5)],y)
lag=merge(d,allwaves[2013][['ID','pef']].rename(columns={'pef':'pef_2013'}),'ID')
estimate('pef_adjusted_2013',lag,'pef',primary+['pef_2013'])
estimate('pef_lag_common_base',lag.dropna(subset=['pef_2013']),'pef')
# Exploratory matched-sample check, added after the initial objective-outcome results.
sr=raw(2015,'Health_Status_and_Functioning',['ID','da001','da002'])
rating=(6-valid(sr.da002,1,5)).fillna((7-valid(sr.da001,1,5)).clip(upper=5))
sr['fair']=rating.ge(3).astype(float).where(rating.notna())
matched=merge(d,sr[['ID','fair']],'ID').dropna(subset=['pef','fair']+primary)
estimate('matched_pef',matched,'pef')
estimate('matched_fair_lpm',matched,'fair')
X=design(matched,['ce_good']+primary)
pr=sm.Probit(matched.fair,X).fit(disp=False,cov_type='cluster',cov_kwds={'groups':matched.communityID})
lo,hi=X.copy(),X.copy();lo['ce_good']=0.;hi['ce_good']=1.
z0,z1=lo@pr.params,hi@pr.params
g=(hi.mul(norm.pdf(z1),axis=0)-lo.mul(norm.pdf(z0),axis=0)).mean().to_numpy()
ame=100*float((norm.cdf(z1)-norm.cdf(z0)).mean());ase=100*np.sqrt(g@pr.cov_params()@g)
crit=t.ppf(.975,matched.communityID.nunique()-1)
out['matched_reporting']={'n':len(matched),'fair_probability_difference_pp':ame,'se':float(ase),'low':float(ame-crit*ase),'high':float(ame+crit*ase),'exploratory':True,'interpretation':'Different outcome patterns do not by themselves establish reporting bias or a statistically significant difference between associations.'}
# Independent least-squares and clustered sandwich calculation for the primary PEF model.
verify=d.dropna(subset=['pef','ce_good','communityID']+primary)
VX=design(verify,['ce_good']+primary);A=VX.to_numpy();Y=verify.pef.to_numpy();beta=np.linalg.lstsq(A,Y,rcond=None)[0]
errors=Y-A@beta;scores=pd.DataFrame(A*errors[:,None]).groupby(verify.communityID.to_numpy()).sum().to_numpy()
G=len(scores);N,K=A.shape;bread=np.linalg.inv(A.T@A)
cov=bread@(scores.T@scores)@bread*(G/(G-1))*((N-1)/(N-K));j=VX.columns.get_loc('ce_good')
ref=out['models']['2015_pef_primary'];assert abs(beta[j]-ref['b'])<1e-8;assert abs(np.sqrt(cov[j,j])-ref['se'])<1e-8
out['independent_check']={'method':'numpy least squares and manually aggregated community score sandwich','b':float(beta[j]),'se':float(np.sqrt(cov[j,j])),'passed':True}
# Sensitivity to the exclusion of invalid but positive readings uses the raw-count audit below.
for yr,d in allwaves.items():
    out['quality'][str(yr)]={'pef_floor':int(d.pef.eq(30).sum()),'pef_ceiling':int(d.pef.eq(890).sum()),'pef_full_effort':int((d.pef.notna()&d.pef_effort.eq(1)).sum()),'pef_3_trials':int((d.pef.notna()&d.pef_trials.eq(3)).sum()),'missing_birthyear_among_life':int(life.birthyear.isna().sum())}
out['overlap']={f'{a}_{b}':len(set(allwaves[a].loc[allwaves[a].pef.notna(),'ID'])&set(allwaves[b].loc[allwaves[b].pef.notna(),'ID'])) for a,b in [(2011,2013),(2013,2015),(2011,2015)]}

# Audit migration and geocoding without releasing individual records.
audit=d.dropna(subset=['pef','ce_good']+primary).copy()
loc=audit.birthplace_proxy.isin([1,2]);moved=audit.t001b_1_.eq(1)
out['huai']={'primary_pef_n':len(audit),'cities':int(audit.city_eng.nunique()),'provinces':int(audit.province_eng.nunique()),'communities':int(audit.communityID.nunique()),'birthplace_proxy_1_or_2':int(loc.sum()),'among_local_proxy_first_residence_moved':int((loc&moved).sum()),'among_local_proxy_first_residence_not_moved':int((loc&audit.t001b_1_.eq(2)).sum()),'among_local_proxy_migration_unknown':int((loc&~audit.t001b_1_.isin([1,2])).sum()),'life_history_first_residence_not_moved':int(audit.t001b_1_.eq(2).sum()),'born_before1950':int(audit.birthyear.lt(1950).sum()),'age1981_min':float((1981-audit.birthyear).min()),'age1981_max':float((1981-audit.birthyear).max())}
city=audit.groupby(['province_eng','city_eng']).agg(n=('ID','size'),communities=('communityID','nunique'),favorable_share=('ce_good','mean')).reset_index()
city.to_csv(root/'city_coverage.csv',index=False)
out['huai']['verified_distance_variable']=False
out['huai']['boundary_local_support']='not estimable without validated respondent locations and policy boundary'
out['huai']['first_stage']='not estimated; no validated running variable'
out['huai']['migration_note']='First-residence move is evidence of a move, not proof of crossing the heating boundary.'
out['huai']['geography_note']='PSU metadata identify prefecture city and province, not respondent county coordinates. Historical pollution is an interpolated community input.'
out['sources']={'archive':str(args.archive),'protocol':'protocol.txt','biomarker_questionnaire':'https://charls.pku.edu.cn/sj/tijianwenjuan2015.pdf','birth_age':'2014 Residence rbirthyear; age = outcome year minus birth year','exposure':'2014 Family_Information D5; 1/2 favorable; 3/4 unfavorable','inference':'OLS community-clustered covariance, G-1 t degrees of freedom; city sensitivity separately reported'}
(root/'objective_results.json').write_text(json.dumps(out,indent=2,allow_nan=False))
for k,v in out['models'].items():print(k,'N=',v['n'],'b=',round(v['b'],4),'CI=',tuple(round(v[c],4) for c in ['low','high']),'p=',round(v['p'],5))
print('HUAI',out['huai'])
