from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Exploratory same-person comparison, using the retained harmonized construction."""
from pathlib import Path
import sys,json
p=results_dir('fixed')
s=(CODE/'robustness_analysis.py').read_text().split('# Explicit risk set starts before biomarker-module selection.')[0]
exec(compile(s,str(CODE/'robustness_analysis.py'),'exec'))
eligible={yr:allwaves[yr].dropna(subset=['pef','ce_good','communityID']+primary) for yr in [2013,2015]}
base_ids=set(allwaves[2013].loc[allwaves[2013].pef.notna(),'ID']) & set(allwaves[2015].loc[allwaves[2015].pef.notna(),'ID'])
pef_ids=set(eligible[2013].ID)&set(eligible[2015].ID)
print('COMMON_PEF_BEFORE_CONTROLS',len(base_ids),flush=True)
ids=sorted(set(matched[2013].ID)&set(matched[2015].ID))
print('COMMON_PEF_N',len(pef_ids),'SRH_missing_either',len(pef_ids-set(ids)),flush=True)
a=matched[2013].set_index('ID').loc[ids].reset_index();b=matched[2015].set_index('ID').loc[ids].reset_index()
assert a.ID.equals(b.ID)
G=a.communityID.nunique();group=pd.concat([a.communityID,b.ID.map(a.set_index('ID').communityID)],ignore_index=True)
Xa=mat(a);Xb=mat(b).reindex(columns=Xa.columns,fill_value=0)
A=Xa.to_numpy();B=Xb.to_numpy();n=len(a);k=A.shape[1];j=Xa.columns.get_loc('ce_good')
XX=np.block([[A,np.zeros_like(B)],[np.zeros_like(A),B]])
results={'n':n,'common_PEF_before_controls':len(base_ids),'excluded_missing_controls':len(base_ids-pef_ids),'common_PEF_n':len(pef_ids),'excluded_missing_SRH_either_wave':len(pef_ids-set(ids)),'clusters_2013':int(G),'community_changed':int((a.communityID!=b.communityID).sum()),'province_changed':int((a.province_eng!=b.province_eng).sum()),'definition':'Intersection of complete-case within-wave SRH/PEF paired samples; same persons in 2013 and 2015. All covariate coefficients vary by wave. Cluster by 2013 community, preserving repeated-person dependence. Exploratory unweighted LPM.','models':{}}
print('OBSERVED_COMMON_N',n,flush=True)
assert np.array_equal(a.ce_good,b.ce_good)
for label,sa,sb in [('raw_probability',1,1),('common_2013_SD',a.fair.std(),a.fair.std()),('within_wave_SD',a.fair.std(),b.fair.std())]:
 Y=np.r_[a.fair/sa,b.fair/sb]
 fit=sm.OLS(Y,XX).fit(cov_type='cluster',cov_kwds={'groups':group},use_t=True)
 vals={}
 for name,indices in [('2013',[(j,1)]),('2015',[(k+j,1)]),('2015_minus_2013',[(k+j,1),(j,-1)])]:
  c=np.zeros(2*k)
  for ix,v in indices:c[ix]=v
  coef=float(c@fit.params);se=float(np.sqrt(c@fit.cov_params()@c));crit=t.ppf(.975,G-1)
  vals[name]={'b':coef,'se':se,'low':coef-crit*se,'high':coef+crit*se,'p':float(2*t.sf(abs(coef/se),G-1))}
 results['models'][label]={'sd2013':float(sa),'sd2015':float(sb),**vals}
 # Verify each stacked coefficient matches separate OLS point estimates.
 assert abs(fit.params[j]-sm.OLS(a.fair/sa,A).fit().params.iloc[j])<1e-10
 assert abs(fit.params[k+j]-sm.OLS(b.fair/sb,B).fit().params.iloc[j])<1e-10
# Independent difference regression when design spans are the same.
assert results['community_changed']==0 and results['province_changed']==0
# Age grows by two; intercept + age + age squared spans are invariant to that shift.
assert np.max(np.abs(A@np.linalg.lstsq(A,B,rcond=None)[0]-B))<1e-8
D=sm.OLS(b.fair.to_numpy()-a.fair.to_numpy(),A).fit(cov_type='cluster',cov_kwds={'groups':a.communityID},use_t=True)
assert abs(D.params[j]-results['models']['raw_probability']['2015_minus_2013']['b'])<1e-10
# Normalize the finite-sample CR1 factors before checking covariances independently.
fstack=(2*n-1)/(2*n-2*k);fdiff=(n-1)/(n-k)
assert abs(D.bse[j]**2/fdiff-results['models']['raw_probability']['2015_minus_2013']['se']**2/fstack)<1e-10
results['validation']='Separate OLS point estimates and independent change-score cluster covariance agree (after CR1 finite-sample factor normalization).'
(p/'fixed_sample_results.json').write_text(json.dumps(results,indent=2,allow_nan=False))
print(json.dumps(results,indent=2))
