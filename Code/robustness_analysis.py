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
root=results_dir('robustness')
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
from scipy.special import expit
root=results_dir('robustness')
out={'models':{},'pairs':{},'audit':{},'selection':{},'ipw':{},'weights':{},'tost':{}}
def srh(yr):
 h=raw(yr,'health_status_and_functioning' if yr==2011 else 'Health_Status_and_Functioning')
 if yr==2011:h['ID']=h.householdID+'0'+h.ID.str[-2:]
 q=h[['ID','communityID','da001','da002']].copy()
 rating=(6-valid(q.da002,1,5)).fillna((7-valid(q.da001,1,5)).clip(upper=5))
 q['fair']=rating.ge(3).astype(float).where(rating.notna())
 assert q.ID.is_unique
 return q

def mat(d,extra=[]):return design(d,['ce_good']+primary+extra)
def est(key,d,y,w=None):
 X=mat(d);v=np.ones(len(d)) if w is None else np.asarray(w,dtype=float)
 a=sm.WLS(d[y],X,weights=v).fit(cov_type='cluster',cov_kwds={'groups':d.communityID},use_t=True)
 b=float(a.params.ce_good);se=float(a.bse.ce_good);g=d.communityID.nunique();crit=t.ppf(.975,g-1)
 r={'n':len(d),'clusters':int(g),'b':b,'se':se,'low':b-crit*se,'high':b+crit*se,'p':float(2*t.sf(abs(b/se),g-1))}
 out['models'][key]=r;return r

def scales(Y,w):
 n=len(Y);mu=np.average(Y,axis=0,weights=w)
 return np.sqrt(np.average((Y-mu)**2,axis=0,weights=w)*n/(n-1))
def pair(key,d,w=None,fixed=None):
 d=d.copy();v=np.ones(len(d)) if w is None else np.asarray(w,dtype=float)
 Y=d[['fair','pef']].to_numpy();sd=scales(Y,v) if fixed is None else fixed
 for i,y in enumerate(['fair','pef']):d['z_'+y]=Y[:,i]/sd[i];est(key+'_'+y,d,'z_'+y,v)
 d['gap']=d.z_fair-d.z_pef;est(key+'_gap',d,'gap',v)
 out['pairs'][key]={'n':len(d),'sd_fair':float(sd[0]),'sd_pef':float(sd[1]),'effective_n':float(v.sum()**2/(v@v))}
 assert abs(out['models'][key+'_gap']['b']-(out['models'][key+'_fair']['b']-out['models'][key+'_pef']['b']))<1e-9
 return sd
# Earlier outcomes are matched within wave. No independence assumption across waves.
matched={}
for yr in [2011,2013,2015]:
 h=srh(yr)
 d=merge(allwaves[yr],h[['ID','fair']],'ID').dropna(subset=['fair','pef','ce_good','communityID']+primary).copy()
 matched[yr]=d;pair(str(yr),d)
assert len(matched[2015])==13720
s15=np.array([out['pairs']['2015']['sd_fair'],out['pairs']['2015']['sd_pef']])
# Explicit risk set starts before biomarker-module selection.
h=srh(2015)
risk=merge(merge(merge(h,family,'ID'),life,'ID'),geo,'communityID',validate='m:1')
risk['age']=2015-risk.birthyear;risk['age_c']=risk.age-60;risk['age_c2']=risk.age_c**2
out['audit']['health_interviews']=len(risk)
risk=risk.loc[risk.age.ge(45)&risk.ce_good.notna()].dropna(subset=primary+['communityID']).copy()
b=raw(2015,'Biomarker',['ID','qb002','qb003','qb004'])
v=b[['qb002','qb003','qb004']].apply(lambda s:valid(s,30,890));b['pef']=v.max(axis=1).where(v.notna().sum(axis=1)>=2);b['biorecord']=1
risk=merge(risk,b[['ID','pef','biorecord']],'ID');risk['biorecord']=risk.biorecord.fillna(0);risk['selected']=risk.pef.notna().astype(float)
for name,d in [('eligible_all',risk),('eligible_srh',risk.dropna(subset=['fair'])),('biomarker_records',risk.loc[risk.biorecord.eq(1)])]:
 est('selection_'+name,d,'selected')
 out['selection'][name]={'n':len(d),'selected':int(d.selected.sum()),'by_D5':[{'D5':int(k),'n':len(v),'selected':int(v.selected.sum()),'rate':float(v.selected.mean())} for k,v in d.groupby('ce_good')]}
est('selection_biorecord',risk,'biorecord')
risk=risk.dropna(subset=['fair']).copy();sel=risk.selected.eq(1)
assert set(risk.loc[sel,'ID'])==set(matched[2015].ID)
pair('risk_selected',risk.loc[sel]);assert abs(out['models']['risk_selected_gap']['b']-out['models']['2015_gap']['b'])<1e-9
P=mat(risk,['fair']).to_numpy();S=risk.selected.to_numpy();X=mat(risk).to_numpy();Y=risk[['fair','pef']].to_numpy();j=mat(risk).columns.get_loc('ce_good')
glm=sm.GLM(S,P,family=sm.families.Binomial()).fit();phat=glm.predict(P)
assert glm.converged
sw=1/phat[sel];cap=np.quantile(sw,.99);cw=np.minimum(sw,cap)
for name,w in [('raw',sw),('cap99',cw)]:
 pair('ipw_'+name,risk.loc[sel],w);pair('ipw_'+name+'_fixedscale',risk.loc[sel],w,s15)
 out['ipw'][name]={'ess':float(w.sum()**2/(w@w)),'weight_quantiles':np.quantile(w,[0,.01,.5,.95,.99,1]).tolist()}
out['ipw']['probability_quantiles']=np.quantile(phat,[0,.01,.05,.5,.95,.99,1]).tolist();out['ipw']['cap99_threshold']=float(cap);out['ipw']['risk_n']=len(risk);out['ipw']['selected_n']=int(sel.sum())
# Selection logit AME with cluster robust delta method, alongside adjusted LPM.
logit=sm.GLM(S,P,family=sm.families.Binomial()).fit(cov_type='cluster',cov_kwds={'groups':risk.communityID})
p0=P.copy();p1=P.copy();pj=mat(risk,['fair']).columns.get_loc('ce_good');p0[:,pj]=0;p1[:,pj]=1
pr0=expit(p0@logit.params);pr1=expit(p1@logit.params);grad=((pr1*(1-pr1))[:,None]*p1-(pr0*(1-pr0))[:,None]*p0).mean(0)
se=float(np.sqrt(grad@logit.cov_params()@grad));b=float(np.mean(pr1-pr0));G=risk.communityID.nunique();q=t.ppf(.975,G-1)
out['selection']['logit_ame']={'n':len(risk),'b':b,'se':se,'low':b-q*se,'high':b+q*se,'p':float(2*t.sf(abs(b/se),G-1))}
# Official cross-sectional weights: same support comparison and no double weighting.
w=raw(2015,'Weights',['ID','INDV_weight_ad2','Biomarker_weight'])
wd=merge(matched[2015],w,'ID')
for col,key in [('Biomarker_weight','survey_biomarker'),('INDV_weight_ad2','survey_individual')]:
 d=wd.loc[wd[col].gt(0)].copy();a=d[col].to_numpy(dtype=float)
 pair(key+'_unweighted',d);pair(key,d,a);pair(key+'_fixedscale',d,a,s15)
 out['weights'][key]={'available':len(d),'excluded':len(wd)-len(d),'ess':float(a.sum()**2/(a@a)),'quantiles':np.quantile(a,[0,.01,.5,.95,.99,1]).tolist()}
# Exploratory TOST sensitivity grid. None is a prespecified clinical equivalence margin.
r=out['models']['2015_pef'];df=r['clusters']-1;crit=t.ppf(.95,df)
for delta in [.025,.05,.10]:
 pl=float(t.sf((r['b']+delta)/r['se'],df));pu=float(t.cdf((r['b']-delta)/r['se'],df))
 out['tost'][str(delta)]={'margin':delta,'low90':r['b']-crit*r['se'],'high90':r['b']+crit*r['se'],'p_lower':pl,'p_upper':pu,'p_tost':max(pl,pu),'equivalent_at_05':bool(max(pl,pu)<.05),'status':'exploratory post hoc margins, no clinical justification'}

# Both earlier-wave tests survive Holm adjustment across these two follow-up contrasts.
for key,pval in zip(['2011_gap','2013_gap'],multipletests([out['models']['2011_gap']['p'],out['models']['2013_gap']['p']],method='holm')[1]):out['models'][key]['p_holm_early_waves']=float(pval)
out['tost_survey_biomarker']={}
rr=out['models']['survey_biomarker_pef'];ddf=rr['clusters']-1;qq=t.ppf(.95,ddf)
for delta in [.025,.05,.10]:
 pl=float(t.sf((rr['b']+delta)/rr['se'],ddf));pu=float(t.cdf((rr['b']-delta)/rr['se'],ddf))
 out['tost_survey_biomarker'][str(delta)]={'margin':delta,'low90':rr['b']-qq*rr['se'],'high90':rr['b']+qq*rr['se'],'p_tost':max(pl,pu),'equivalent_at_05':bool(max(pl,pu)<.05),'status':'exploratory post hoc margins, no clinical justification'}

(root/'robustness_results.json').write_text(json.dumps(out,indent=2))
print('POINT ESTIMATES',json.dumps(out),flush=True)
# Community multiplier representation of pairs bootstrap: all respondents in a selected
# community repeat together. Refit selection probabilities and recompute outcome scaling.
groups=pd.factorize(risk.communityID)[0];G=groups.max()+1;rng=np.random.default_rng(2026111802)
Ps=P[sel];Xs=X[sel];Ys=Y[sel];gs=groups[sel];start=np.asarray(glm.params)
def selection_fit(count):
 beta=start.copy()
 for it in range(60):
  p=expit(np.clip(P@beta,-30,30));v=count*p*(1-p);score=P.T@(count*(S-p));H=P.T@(v[:,None]*P)
  step=np.linalg.lstsq(H,score,rcond=1e-12)[0];beta+=step
  if np.max(np.abs(step))<1e-8:return expit(np.clip(Ps@beta,-30,30)),True
 return expit(np.clip(Ps@beta,-30,30)),False
boots=[];failed=0
for i in range(999):
 mult=rng.multinomial(G,np.full(G,1/G));count=mult[groups];sc=mult[gs];p,ok=selection_fit(count)
 if not ok:failed+=1;continue
 raww=1/p;cut=np.quantile(np.repeat(raww,sc),.99);row=[]
 for capw in [raww,np.minimum(raww,cut)]:
  ww=sc*capw;bet=np.linalg.lstsq(Xs.T@(ww[:,None]*Xs),Xs.T@(ww[:,None]*Ys),rcond=1e-12)[0][j]
  mu=np.average(Ys,weights=ww,axis=0);n=sc.sum();sd=np.sqrt(np.average((Ys-mu)**2,weights=ww,axis=0)*n/(n-1));std=bet/sd;row.extend([float(std[0]),float(std[1]),float(std[0]-std[1])])
 boots.append(row)
 if (i+1)%100==0:print('BOOTSTRAP',i+1,'failures',failed,flush=True)
boots=np.array(boots);assert len(boots)>=990
out['ipw']['bootstrap']={'requested':999,'completed':len(boots),'failed':failed,'seed':2026111802,'method':'community pairs with refitted logistic selection and weighted standardization','percentile':{name:np.quantile(boots[:,i],[.025,.975]).tolist() for i,name in enumerate(['raw_fair','raw_pef','raw_gap','cap99_fair','cap99_pef','cap99_gap'])}}
pd.DataFrame(boots,columns=['raw_fair','raw_pef','raw_gap','cap99_fair','cap99_pef','cap99_gap']).to_csv(root/'ipw_bootstrap.csv',index=False)
# Official weights are held fixed in CR1 inference; generated IPW uncertainty uses bootstrap.
out['sources']={'release_note':'https://charls.pku.edu.cn/en/data/Release2015.pdf','archive':str(args.archive)}
out['interpretation']='Weighted and earlier-wave associations are robustness evidence, not identification of recall bias or causal childhood effects. IPW assumes conditionally ignorable PEF missingness and positivity; it cannot correct survival or missing 2014 recall.'
(root/'robustness_results.json').write_text(json.dumps(out,indent=2,allow_nan=False));pd.DataFrame(out['models']).T.to_csv(root/'model_summary.csv')
print('FINISHED',out['ipw']['bootstrap'],flush=True)
