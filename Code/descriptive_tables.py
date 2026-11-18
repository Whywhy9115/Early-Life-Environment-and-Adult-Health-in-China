"""Descriptive additions only: retain every fitted model and existing result."""
from pathlib import Path
import json,sys
from project_paths import CODE,INPUTS,results_dir
s=(CODE/'discordance_analysis.py').read_text().split('def matrix(ds,controls):')[0]
exec(compile(s,str(CODE/'discordance_analysis.py'),'exec'))
# Derive percent-predicted values with the retained reference; no new fitted model.
base['pef_percent']=np.nan
reference=pd.ExcelFile(INPUTS/'PEF_reference_Table_1.xlsx')
for female,sheet in [(0,'PEF males'),(1,'PEF females')]:
 tab=pd.read_excel(reference,sheet_name=sheet,header=1).iloc[:,:2].dropna();tab.columns=['age','mspline'];tab=tab.apply(pd.to_numeric)
 ok=base.female.eq(female)&base.age.between(tab.age.min(),tab.age.max())&base.height.notna()
 v=base.loc[ok];m=np.interp(v.age,tab.age,tab.mspline)
 pred=(100.4273-4.94*v.age+3.4654*v.height+m) if female==0 else (66.9815-2.7342*v.age+2.3084*v.height+m)
 base.loc[ok,'pef_percent']=100*v.pef/pred.where(pred.gt(0))
for k in range(1,6):base['education_'+str(k)]=base.education_group.eq(k).astype(float).where(base.education_group.notna())
variables=[('Self-rated health, fair or better (%)','fair',100),('Peak flow (L/min)','pef',1),('Peak flow (% predicted)','pef_percent',1),('Systolic pressure (mmHg)','sbp',1),('Diastolic pressure (mmHg)','dbp',1),('Height (cm)','height',1),('CES-D-10 (0–30)','cesd',1),('Reported conditions (0–14)','chronic',1),('ADL limitations (0–6)','adl',1),('Age (years)','age',1),('Female (%)','female',100),('Urban residence (%)','urban_nbs',100),('Ever smoked (%)','ever_smoke',100)]+[(label,'education_'+str(i),100) for i,label in enumerate(['Illiterate (%)','Incomplete primary (%)','Completed primary (%)','Middle school (%)','High school or above (%)'],1)]
rows=[]
for label,col,scale in variables:
 vals={str(int(k)):{'n':int(v[col].notna().sum()),'mean':float(v[col].mean()*scale),'sd':float(v[col].std()*scale)} for k,v in base.groupby('ce_good')}
 rows.append({'label':label,'column':col,'scale':scale,'groups':vals,'difference':vals['1']['mean']-vals['0']['mean']})
result={'n':len(base),'group_n':{str(int(k)):len(v) for k,v in base.groupby('ce_good')},'descriptive_table':rows,'common_complete':int(base.dropna(subset=['cesd','pef','sbp','dbp','height','chronic','adl']).shape[0]),'primary_pef_n':int(d.dropna(subset=['pef','ce_good','communityID']+primary).shape[0]),'sample_discrepancy':'Verified counts 13,935 and 13,720 are the manuscript reference, as confirmed by the author.'}
assert result['n']==13720 and result['common_complete']==11719 and result['primary_pef_n']==13935
# Education distributions in the retained main sample; no regression re-estimation.
state={'__file__':str(CODE/'analysis.py'),'__name__':'descriptive_input'}
s2=(CODE/'analysis.py').read_text().split("results = {'survey':")[0]
exec(compile(s2,str(CODE/'analysis.py'),'exec'),state)
health=state['main'].dropna(subset=['fair','ce_good','communityID']+state['primary_controls'])
assert len(health)==18058
result['education_health_shares']=[{'education':int(k),'n':len(v),'very_good_pct':float(100*v.top.mean()),'fair_or_better_pct':float(100*v.fair.mean())} for k,v in health.groupby('education_group')]
# Audit the proposed family-within TSP share, retaining the original TSP sample filter.
from zipfile import ZipFile
z2=ZipFile(sys.argv[1]);dta=[n for n in z2.namelist() if n.lower()=='qiu/working_data/all_tsp_meteor.dta'][0]
with z2.open(dta) as f:poll=pd.read_stata(f,convert_categoricals=False)
result['family_variation_claim']='8.7% is not a stored result in the retained analysis; no sibling fixed-effects estimate is included.'
outdir=results_dir('editorial');(outdir/'descriptive_results.json').write_text(json.dumps(result,indent=2,allow_nan=False))
print('DESCRIPTIVES',len(rows),'rows',result['group_n'],result['education_health_shares'])
