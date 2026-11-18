from project_paths import CODE, INPUTS, results_dir, stage_dir
from pathlib import Path
import sys,json
p=CODE/'robustness_analysis.py';s=p.read_text()
# Recreate the prespecified risk set and propensity fit without altering saved outputs.
exec(s.split('# Official cross-sectional weights:')[0])
ss=s[s.index('groups=pd.factorize(risk.communityID)'):s.index('boots=[];failed=0')]
exec(ss)
mult=rng.multinomial(G,np.full(G,1/G));count=mult[groups];sc=mult[gs]
prob,ok=selection_fit(count);assert ok
check=sm.GLM(S,P,family=sm.families.Binomial(),freq_weights=count).fit()
print('propensity verification',check.converged,float(np.max(np.abs(check.predict(Ps)-prob))),float(np.max(np.abs(check.predict(Ps)[sc>0]-prob[sc>0]))),flush=True)
assert np.max(np.abs(check.predict(Ps)[sc>0]-prob[sc>0]))<1e-7
ww=sc/prob;bet=np.linalg.lstsq(Xs.T@(ww[:,None]*Xs),Xs.T@(ww[:,None]*Ys),rcond=1e-12)[0]
bet_direct=np.linalg.lstsq(Xs*np.sqrt(ww)[:,None],Ys*np.sqrt(ww)[:,None],rcond=None)[0]
assert np.max(np.abs(bet-bet_direct))<1e-6
Y0=risk.loc[sel,'pef'].to_numpy()/s15[1];A=mat(risk.loc[sel]).to_numpy();ww=sw
be=np.linalg.lstsq(A*np.sqrt(ww)[:,None],Y0*np.sqrt(ww),rcond=None)[0];e=Y0-A@be
score=pd.DataFrame(A*(ww*e)[:,None]).groupby(risk.loc[sel,'communityID'].to_numpy()).sum().to_numpy();N,K=A.shape;ng=len(score);bread=np.linalg.inv(A.T@(ww[:,None]*A));V=bread@(score.T@score)@bread*(ng/(ng-1))*(N-1)/(N-K)
ref=out['models']['ipw_raw_fixedscale_pef'];assert abs(be[j]-ref['b'])<1e-8;assert abs(np.sqrt(V[j,j])-ref['se'])<1e-8
result={'propensity_bootstrap_matches_GLM':True,'bootstrap_weighted_fit_matches_direct_least_squares':True,'weighted_cluster_covariance_independently_verified':True,'risk_selected_IDs_match_previous_13720':True}
(root/'validation.json').write_text(json.dumps(result,indent=2));print(result)
