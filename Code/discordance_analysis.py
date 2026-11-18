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
root=results_dir('discordance')
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
      'pef_position':b.qb006,'pef_effort':b.qb005,'bp_compliance':b.qa015,'bp_position':b.qa016,'bp_recent':b.qa017,'height_compliance':b.qi003})
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
# New follow-up estimates begin here; no TSP or geographic models are fitted.
root=results_dir('discordance')
out={'models':{},'contrasts':{},'audit':{},'sources':{}}
h=raw(2015,'Health_Status_and_Functioning')
sr=h[['ID','proxy']].copy()
rating=(6-valid(h.da002,1,5)).fillna((7-valid(h.da001,1,5)).clip(upper=5))
sr['fair']=rating.ge(3).astype(float).where(rating.notna())
sr['srh_ordered']=rating
ces=h[[f'dc{i:03}' for i in range(9,19)]].apply(lambda s:valid(s,1,4)-1)
ces[['dc013','dc016']]=3-ces[['dc013','dc016']]
sr['cesd']=ces.sum(axis=1,min_count=10)
adlraw=h[[f'db{i:03}' for i in range(10,16)]].apply(lambda s:valid(s,1,4))
mob=h[[f'db{i:03}' for i in range(1,10)]].apply(lambda s:valid(s,1,4))
# DB001=1 routes past DB002 and DB003; DB002=1 routes past DB003.
mob.loc[mob.db001.eq(1),'db002']=mob.loc[mob.db001.eq(1),'db002'].fillna(1)
mob.loc[mob.db001.eq(1)|mob.db002.eq(1),'db003']=mob.loc[mob.db001.eq(1)|mob.db002.eq(1),'db003'].fillna(1)
skip=mob.eq(1).all(axis=1)
adl=adlraw.copy();adl.loc[skip]=adl.loc[skip].fillna(1)
sr['adl']=adl.gt(1).astype(float).where(adl.notna()).sum(axis=1,min_count=6)
sr['adl_observed']=adlraw.gt(1).astype(float).where(adlraw.notna()).sum(axis=1,min_count=6)
out['audit']['adl_documented_skip_filled']=int((skip&adlraw.isna().any(axis=1)).sum())
# Doctor-reported diagnosis is not a medical-record outcome. Corrected prior positives
# with no physician source and confirmed self-awareness-only histories stay unknown.
for i in range(1,15):
 direct=h[f'da007_{i}_'];new=h[f'da007_w2_2_{i}_'];confirm=h[f'da007_w2_1_{i}_']
 prior=h[f'zda007_{i}_'].eq(1)
 aware=h.get(f'zda008_{i}_',pd.Series(np.nan,index=h.index)).eq(1)
 anyprior=prior|aware
 broad=pd.Series(np.nan,index=h.index);strict=broad.copy()
 broad.loc[confirm.eq(1)&anyprior]=1
 broad.loc[confirm.eq(2)&~anyprior]=1
 strict.loc[confirm.eq(1)&prior]=1
 # Current explicit new-diagnosis answers are used on their routed path.
 routed=confirm.eq(1)&~anyprior | confirm.eq(2)&anyprior
 for dst in [broad,strict]:
  dst.loc[routed&new.eq(2)]=0
  dst.loc[new.eq(1)]=1
  dst.loc[direct.isin([1,2])]=direct.loc[direct.isin([1,2])].map({1:1.,2:0.})
 # Current self-awareness is part of broad known disease, never strict physician diagnosis.
 selfnow=h.get(f'da008_{i}_',pd.Series(np.nan,index=h.index))
 broad.loc[selfnow.eq(1)]=1
 sr[f'dx{i}']=strict;sr[f'known{i}']=broad
sr['chronic']=sr[[f'known{i}' for i in range(1,15)]].sum(axis=1,min_count=14)
sr['chronic13']=sr[[f'known{i}' for i in range(1,15) if i!=11]].sum(axis=1,min_count=13)
d=merge(allwaves[2015],sr,'ID')
# Keep matching as in the previous analysis; 2015 smoking state has direct precedence.
d['ever_smoke']=d.smoking.gt(0).astype(float).where(d.smoking.notna())
base=d.dropna(subset=['pef','fair','communityID','ce_good']+primary).copy()
assert len(base)==13720, len(base)
for y in ['fair','pef']:
 base['z_'+y]=(base[y]-base[y].mean())/base[y].std(ddof=1)
base['z_difference']=base.z_fair-base.z_pef
out['audit'].update({'matched_n':len(base),'communities':int(base.communityID.nunique()),'sd_fair':float(base.fair.std()),'sd_pef':float(base.pef.std()),'proxy':{str(k):int(v) for k,v in base.proxy.value_counts(dropna=False).items()},'cesd_available':int(base.cesd.notna().sum()),'chronic_available':int(base.chronic.notna().sum()),'adl_available':int(base.adl.notna().sum()),'effort':{str(k):int(v) for k,v in base.pef_effort.value_counts(dropna=False).items()},'posture':{str(k):int(v) for k,v in base.pef_position.value_counts(dropna=False).items()}})

def matrix(ds,controls):
 cats=[c for c in controls if c in ['province_eng','finance','education_group','smoking','pef_position']]
 X=pd.get_dummies(ds[['ce_good']+controls],columns=cats,drop_first=True,dtype=float)
 X=sm.add_constant(X,has_constant='add').astype(float)
 # Constant extra covariates may occur in very small posture subgroups.
 X=X.loc[:,['const']+[c for c in X if c!='const' and X[c].nunique()>1]]
 assert np.linalg.matrix_rank(X)==X.shape[1]
 return X
fits={}
def fit(key,ds,y,controls=primary):
 ds=ds.dropna(subset=[y,'ce_good','communityID']+controls).copy()
 X=matrix(ds,controls);a=sm.OLS(ds[y],X).fit(cov_type='cluster',cov_kwds={'groups':ds.communityID},use_t=True)
 G=ds.communityID.nunique();crit=t.ppf(.975,G-1);b=float(a.params.ce_good);se=float(a.bse.ce_good)
 out['models'][key]={'n':len(ds),'clusters':int(G),'b':b,'se':se,'low':b-crit*se,'high':b+crit*se,'p':float(2*t.sf(abs(b/se),G-1)),'outcome':y,'controls':controls,'mean':float(ds[y].mean()),'sd':float(ds[y].std())}
 fits[key]=(ds,X,a)
 return out['models'][key]
for y in ['fair','pef','z_fair','z_pef','z_difference']:fit('primary_'+y,base,y)
fit('gap_exclude_proxy',base.loc[base.proxy.eq(0)],'z_difference')
assert abs(out['models']['primary_z_difference']['b']-(out['models']['primary_z_fair']['b']-out['models']['primary_z_pef']['b']))<1e-10
# Independent cross-equation community-score covariance, same correction as paired regression.
def influence(key):
 ds,X,a=fits[key];A=X.to_numpy();e=a.resid.to_numpy();j=X.columns.get_loc('ce_good');bread=np.linalg.inv(A.T@A)
 scores=(A*e[:,None])@bread[:,j]
 g=pd.Series(scores,index=ds.communityID.to_numpy()).groupby(level=0).sum();G=len(g);N,K=A.shape
 return g*np.sqrt(G/(G-1)*(N-1)/(N-K))
def contrast(key,a,b):
 ds0=fits[a][0];ds1=fits[b][0];assert list(ds0.ID)==list(ds1.ID)
 infl=influence(a)-influence(b);se=float(np.sqrt((infl**2).sum()));v=out['models'][a]['b']-out['models'][b]['b'];G=len(infl);q=t.ppf(.975,G-1)
 out['contrasts'][key]={'n':len(ds0),'b':v,'se':se,'low':v-q*se,'high':v+q*se,'p':float(2*t.sf(abs(v/se),G-1))}
contrast('paired_equation_check','primary_z_fair','primary_z_pef')
assert abs(out['contrasts']['paired_equation_check']['se']-out['models']['primary_z_difference']['se'])<1e-10
# Community resampling uses cluster sufficient statistics and recomputes scaling each draw.
X=matrix(base,primary).to_numpy();Y=base[['fair','pef']].to_numpy();groups=pd.factorize(base.communityID)[0];G=groups.max()+1;K=X.shape[1]
XX=np.zeros((G,K,K));XY=np.zeros((G,K,2));sy=np.zeros((G,2));sy2=sy.copy();ng=np.bincount(groups)
for g in range(G):
 A=X[groups==g];B=Y[groups==g];XX[g]=A.T@A;XY[g]=A.T@B;sy[g]=B.sum(0);sy2[g]=(B**2).sum(0)
rng=np.random.default_rng(20261118);boots=[];j=matrix(base,primary).columns.get_loc('ce_good')
for b in range(1999):
 w=rng.multinomial(G,np.full(G,1/G));xx=np.einsum('g,gij->ij',w,XX);xy=np.einsum('g,gij->ij',w,XY)
 # Rare omitted province categories are retained using the Moore-Penrose solve;
 # D5 remains identified. Record rank failures separately.
 bet=np.linalg.lstsq(xx,xy,rcond=1e-12)[0][j];n=w@ng;s=w@sy;s2=w@sy2;sd=np.sqrt((s2-s*s/n)/(n-1));std=bet/sd;boots.append([*std,std[0]-std[1]])
# Independently verify the aggregate solve against direct resampling for one draw.
idx=np.concatenate([np.flatnonzero(groups==g) for g in np.repeat(np.arange(G),w)])
direct=np.linalg.lstsq(X[idx],Y[idx],rcond=None)[0][j]/Y[idx].std(axis=0,ddof=1)
assert np.max(np.abs(direct-np.array(boots[-1][:2])))<1e-8
out['audit']['bootstrap_aggregate_verified']=True
boots=np.array(boots)
out['bootstrap']={'draws':1999,'seed':20261118,'restandardized_each_draw':True,'percentile':{k:np.quantile(boots[:,i],[.025,.975]).tolist() for i,k in enumerate(['fair','pef','difference'])},'sd_difference':float(boots[:,2].std(ddof=1))}
pd.DataFrame(boots,columns=['fair_sd','pef_sd','difference_sd']).to_csv(root/'cluster_bootstrap.csv',index=False)
print('FORMAL',out['models']['primary_z_difference'],out['bootstrap'],flush=True)
# Measurement and body-size checks, each restricted baseline uses identical people.
for name,sub in [('full_effort',base.loc[base.pef_effort.eq(1)]),('standing',base.loc[base.pef_position.eq(1)]),('seated',base.loc[base.pef_position.eq(2)]),('strict_quality',base.loc[base.pef_effort.eq(1)&base.pef_position.eq(1)&base.pef_trials.eq(3)])]:
 fit('pef_'+name,sub,'pef');fit('gap_'+name,sub,'z_difference')
for name,controls in [('posture',primary+['pef_position']),('height',primary+['height'])]:
 sub=base.dropna(subset=controls);fit('pef_'+name+'_base',sub,'pef');fit('pef_'+name+'_adjusted',sub,'pef',controls)
sub=base.dropna(subset=['height']).copy();sub['height_c']=sub.height-160;sub['height_c2']=sub.height_c**2
for c in ['age_c','age_c2','height_c','height_c2']:sub['female_'+c]=sub.female*sub[c]
fit('pef_flexible_body_size',sub,'pef',primary+['height_c','height_c2']+['female_'+c for c in ['age_c','age_c2','height_c','height_c2']])
# Ji et al. 2021 exact M equations and age lookup, no extrapolation beyond table.
reference=pd.ExcelFile(INPUTS/'PEF_reference_Table_1.xlsx')
sub['predicted_pef']=np.nan
for female,sheet in [(0,'PEF males'),(1,'PEF females')]:
 tab=pd.read_excel(reference,sheet_name=sheet,header=1).iloc[:,:2].dropna();tab.columns=['age','mspline'];tab=tab.apply(pd.to_numeric)
 ok=sub.female.eq(female)&sub.age.between(tab.age.min(),tab.age.max())
 m=np.interp(sub.loc[ok,'age'],tab.age,tab.mspline)
 if female==0:pred=100.4273-4.94*sub.loc[ok,'age']+3.4654*sub.loc[ok,'height']+m
 else:pred=66.9815-2.7342*sub.loc[ok,'age']+2.3084*sub.loc[ok,'height']+m
 sub.loc[ok,'predicted_pef']=pred
 out['audit']['reference_age_range_'+str(female)]=[float(tab.age.min()),float(tab.age.max())]
sub['pef_percent']=100*sub.pef/sub.predicted_pef.where(sub.predicted_pef.gt(0))
fit('pef_percent_predicted',sub,'pef_percent');fit('pef_percent_same_base',sub.dropna(subset=['pef_percent']),'pef')
for group,value in [('never',0),('ever',1)]:fit('pef_smoke_'+group,base.loc[base.ever_smoke.eq(value)],'pef',primary+['height'])
for group,value in [('former',1),('current',2)]:fit('pef_smoke_'+group,base.loc[base.smoking.eq(value)],'pef',primary+['height'])
sub=base.dropna(subset=['ever_smoke','height']).copy();sub['D5_smoking']=sub.ce_good*sub.ever_smoke
fit('pef_smoking_interaction_model',sub,'pef',primary+['height','ever_smoke','D5_smoking'])
a=fits['pef_smoking_interaction_model'][2];G=sub.communityID.nunique();b=float(a.params.D5_smoking);se=float(a.bse.D5_smoking);q=t.ppf(.975,G-1)
out['smoking_interaction']={'b':b,'se':se,'low':b-q*se,'high':b+q*se,'p':float(2*t.sf(abs(b/se),G-1))}
# Mechanism-related comparisons: same people, LPM on probability scale, no mediation claim.
healthblock=['pef','sbp','dbp','height','chronic','adl']
common=base.dropna(subset=['cesd']+healthblock).copy()
for name,controls in [('base',primary),('cesd',primary+['cesd']),('measured',primary+['pef','sbp','dbp','height']),('health',primary+healthblock),('both',primary+healthblock+['cesd'])]:fit('common_'+name,common,'fair',controls)
for name in ['cesd','measured','health','both']:contrast('attenuation_'+name,'common_base','common_'+name)
cs=base.dropna(subset=['cesd']);fit('cesd_pair_base',cs,'fair');fit('cesd_pair_adjusted',cs,'fair',primary+['cesd']);contrast('cesd_larger_sample','cesd_pair_base','cesd_pair_adjusted')
fit('cesd_as_outcome',cs,'cesd')
fit('gap_cesd_common_base',cs,'z_difference')
fit('gap_cesd_adjusted',cs,'z_difference',primary+['cesd'])
contrast('gap_attenuation_cesd','gap_cesd_common_base','gap_cesd_adjusted')
sub=common.dropna(subset=['chronic13']);fit('common_nonpsychiatric_count',sub,'fair',primary+['pef','sbp','dbp','height','chronic13','adl','cesd'])
sub=common.dropna(subset=['adl_observed']);fit('no_adl_fill_base',sub,'fair');fit('no_adl_fill_adjusted',sub,'fair',primary+['pef','sbp','dbp','height','chronic','adl_observed','cesd'])
# Strict diagnosis primary, broad known conditions as specified sensitivity.
for name,i in [('hypertension',1),('lung',5)]:
 fit('diagnosis_'+name,base,'dx'+str(i));fit('known_'+name,base,'known'+str(i))
 sub=base.dropna(subset=['dx'+str(i)]).copy();sub['z_dx']=-(sub['dx'+str(i)]-sub['dx'+str(i)].mean())/sub['dx'+str(i)].std()
 # Paired standardized diagnostic contrasts use own common sample SDs.
 for y in ['fair','pef']:sub['z_'+y]=(sub[y]-sub[y].mean())/sub[y].std()
 for y in ['z_dx','z_fair','z_pef']:fit(name+'_'+y,sub,y)
 contrast(name+'_fair_minus_dx',name+'_z_fair',name+'_z_dx');contrast(name+'_dx_minus_pef',name+'_z_dx',name+'_z_pef')
ps=[out['models']['diagnosis_'+n]['p'] for n in ['hypertension','lung']]
for n,p in zip(['hypertension','lung'],multipletests(ps,method='holm')[1]):out['models']['diagnosis_'+n]['p_holm']=float(p)
for i in [1,5]:out['audit']['diagnosis_'+str(i)]={'strict_missing':int(base[f'dx{i}'].isna().sum()),'broad_missing':int(base[f'known{i}'].isna().sum()),'strict_yes':int(base[f'dx{i}'].eq(1).sum()),'broad_yes':int(base[f'known{i}'].eq(1).sum())}
# Internal face-validity checks are associations, not validation against spirometry.
fit('pef_lung_condition',base.dropna(subset=['dx5']), 'pef',primary+['height','dx5','smoking'])
a=fits['pef_lung_condition'][2];out['pef_face_validity']={k:{'b':float(a.params[k]),'se':float(a.bse[k])} for k in ['age_c','female','height','dx5']}
out['sources']={'questionnaire':'https://charls.charlsdata.com/Public/ashelf/public/uploads/document/2015-charls-wave4/application/CHARLS_2015_Questionnaire.pdf','biomarker':'https://charls.pku.edu.cn/en/data/Biomarker2015.pdf','prediction_reference':'https://doi.org/10.3389/fpubh.2021.706524','lookup_download':'https://www.ebi.ac.uk/europepmc/webservices/rest/PMC8417711/supplementaryFiles'}
out['interpretation']='Follow-up observational association analysis; standardized inequality is not proof of reporting bias, equivalence, causal mediation or early-life pollution effects. Reference PEF uses a partly overlapping 2011 CHARLS cohort, so it is a normalization sensitivity, not external validation.'
(root/'discordance_results.json').write_text(json.dumps(out,indent=2,allow_nan=False))
pd.DataFrame(out['models']).T.to_csv(root/'model_summary.csv')
for k,v in out['models'].items():print(k,v['n'],round(v['b'],5),[round(v[a],5) for a in ['low','high']],round(v['p'],6))
print('CONTRASTS',out['contrasts']);print('AUDIT',out['audit']);print('SMOKE',out['smoking_interaction'])
