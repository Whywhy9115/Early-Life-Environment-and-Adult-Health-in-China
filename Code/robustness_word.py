from project_paths import INPUTS, stage_dir, check_document_text
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from copy import deepcopy,copy
from lxml import etree
import hashlib,json
root=stage_dir('robustness')
source=stage_dir('discordance')/'SURA_Health_Discordance_Revision.docx'
check_document_text(source, '37ef6bdb53456b90f4ff9af84dc503f5941731b8d40bf1f43bdab60f549a7eeb')
z=ZipFile(source);doc=etree.fromstring(z.read('word/document.xml'));ns=doc.nsmap;b=doc.find('w:body',ns);ps=b.findall('w:p',ns);tables=b.findall('w:tbl',ns)
R=json.loads((root/'Replication/robustness_results.json').read_text());M=R['models'];B=R['ipw']['bootstrap']['percentile']
def text(x):return ''.join(x.xpath('.//w:t/text()',namespaces=ns))
def settext(x,s):
 ts=x.xpath('.//w:t',namespaces=ns);ts[0].text=s;ts[0].set('{http://www.w3.org/XML/1998/namespace}space','preserve')
 for t in ts[1:]:t.text=''
 if '\n' in s:
  parts=s.split('\n');ts[0].text=parts[0];run=ts[0].getparent()
  for part in parts[1:]:
   etree.SubElement(run,'{'+ns['w']+'}br');a=etree.SubElement(run,'{'+ns['w']+'}t');a.text=part
def clone(x):
 q=deepcopy(x)
 for a in q.xpath('.//w:bookmarkStart|.//w:bookmarkEnd',namespaces=ns):a.getparent().remove(a)
 return q
ppr=[etree.tostring(p.find('w:pPr',ns)) for p in ps]
rpr=[etree.tostring(q) for p in ps for q in p.xpath('.//w:rPr',namespaces=ns)]
tabs=[etree.tostring(t) for t in tables];before=[text(p) for p in ps];edited=[]
for i,p in enumerate(ps):
 t=text(p)
 if t.startswith('Early-life environmental conditions may shape'):
  t=t.replace('Measurement-quality and body-size checks retain near-zero peak-flow estimates.','Measurement checks retain near-zero peak-flow estimates. The paired difference persists under selection and survey weighting and in 2011 and 2013.')
 elif t.startswith('The paired analysis formally distinguishes'):
  t='Among 13,720 respondents, standardized self-rated-health and peak-flow coefficients differ by 0.126 SD (95% CI 0.079 to 0.172). The difference persists under selection and survey weighting and in earlier waves. Appendices G and H detail the paired tests and their limits.'
 elif t.startswith('The formal paired comparison establishes a difference'):
  t='The paired comparison establishes different standardized self-rated-health and peak-flow associations, robust to selection and survey weighting and present in earlier waves. Depressive symptoms and reported health account for part of the former association; measured indicators alone change it little. Recall, selection and causal mechanisms remain unresolved.'
 else:continue
 settext(p,t);edited.append(i)
# Existing TOC entries stay fixed; append H using the retained G entry.
toc=next(p for p in ps if text(p).startswith('Appendix G Differences') and p.xpath('.//w:hyperlink',namespaces=ns))
q=clone(toc);ts=q.xpath('.//w:t',namespaces=ns);ts[0].text='Appendix H Selection weights and earlier outcomes'
for t in ts[1:]:t.text=''
ts[-1].text='51'
for h in q.xpath('.//w:hyperlink',namespaces=ns):h.set('{'+ns['w']+'}anchor','RobustnessH')
b.insert(b.index(toc)+1,q)
roles={}
for key,prefix in [('title','Appendix G Differences'),('heading','G1 A formal'),('body','The central comparison uses'),('caption','Table G1'),('note','Notes: All three rows'),('reference','Ji, C., Xia')]:
 roles[key]=next(p for p in ps if text(p).startswith(prefix) and not p.xpath('.//w:hyperlink',namespaces=ns))
section=b.find('w:sectPr',ns)
def para(t,role='body',page=False):
 q=clone(roles[role]);settext(q,t)
 if page and q.find('w:pPr/w:pageBreakBefore',ns)is None:etree.SubElement(q.find('w:pPr',ns),'{'+ns['w']+'}pageBreakBefore')
 b.insert(b.index(section),q);return q
def heading(t,page=False):return para(t,'heading',page)
def note(t):return para(t,'note')
def table(caption,headers,rows):
 para(caption,'caption');q=clone(tables[10]);trs=q.findall('w:tr',ns);head=deepcopy(trs[0]);body=deepcopy(trs[1])
 for tr in trs:q.remove(tr)
 for vals,t in [(headers,head)]+[(r,body) for r in rows]:
  a=deepcopy(t)
  for c,v in zip(a.findall('w:tc',ns),vals):settext(c,str(v))
  q.append(a)
 b.insert(b.index(section),q)
def ci(key,scale=1,boot=None):
 v=M[key];lo,hi=(v['low'],v['high']) if boot is None else B[boot]
 return f"{v['b']*scale:.3f}\n({lo*scale:.3f}, {hi*scale:.3f})"
def pc(key):
 v=M[key];return f"{100*v['b']:.2f} ({100*v['low']:.2f}, {100*v['high']:.2f})"
h=para('Appendix H Selection weights and earlier outcomes','title',True)
heading('H1 Participation in valid peak-flow measurement')
para('The selection denominator starts with 2015 health interviews, including people without a biomarker record. Requiring age 45 or older, linked 2014 neighborhood conditions and primary covariates leaves 17,295 people; 13,916 have at least two peak-flow trials in the valid range. Completion is 80.15% for favorable neighborhoods and 81.02% otherwise. These rates concern test availability among linked interviewees, not survival or total survey participation.')
table('Table H1  Neighborhood associations with measurement completion',['Selection outcome','N','Difference (pp)','95% confidence interval'],[[label,f"{M[k]['n']:,}",f"{100*M[k]['b']:.2f}",f"({100*M[k]['low']:.2f}, {100*M[k]['high']:.2f})"] for label,k in [('Valid PEF, all eligible','selection_eligible_all'),('Any biomarker record','selection_biorecord'),('Valid PEF, record present','selection_biomarker_records')]])
note('Notes: Linear probability models use the primary covariates and community clustering. A biomarker record does not imply a valid peak-flow test. Intervals are 95%; pp denotes percentage points.')
para('Among 16,699 eligible people with self-rated health, 13,720 have valid peak flow. The adjusted completion difference is −0.05 percentage points (95% CI −1.44 to 1.33). This gives no clear evidence of selection on D5, but does not establish absence of selection bias.')
table('Table H2  Paired associations after inverse probability weighting',['Specification','N','PEF association (SD)','Paired difference (SD)'],[
 ['Unweighted','13,720',ci('2015_pef'),ci('2015_gap')],
 ['Inverse probability','13,720',ci('ipw_raw_pef',boot='raw_pef'),ci('ipw_raw_gap',boot='raw_gap')],
 ['IPW capped at 99th percentile','13,720',ci('ipw_cap99_pef',boot='cap99_pef'),ci('ipw_cap99_gap',boot='cap99_gap')]])
note('Notes: IPW intervals are percentile intervals from 999 community resamples, refitting selection and standardization each time; all draws converged. The unweighted row uses cluster-robust t inference. Difference is standardized self-rated health minus PEF.')
para('The selection logit includes D5, primary covariates and observed self-rated health. Both outcome equations use the same weights and controls. Predicted completion ranges from 0.268 to 0.947; the maximum inverse probability weight is 3.73 and effective sample size is 13,601. Capping at 1.59 changes little. IPW assumes conditional exchangeability of missing and observed PEF and adequate overlap; unmeasured selection and missing life-history participation remain unresolved.')
heading('H2 Official cross-sectional weights',True)
para('The 2015 release provides a biomarker weight that combines individual weights with adjustment for biomarker nonresponse. It is the primary survey-weight sensitivity; the household- and individual-response-adjusted individual weight is reported separately. Both are available for 13,515 of the 13,720 paired records. The table therefore includes the unweighted comparison on exactly those 13,515 people.')
table('Table H3  Standardized associations on common weight support',['Specification','Self-rated health','Peak flow','Paired difference'],[
 ['Unweighted, same support',ci('survey_biomarker_unweighted_fair'),ci('survey_biomarker_unweighted_pef'),ci('survey_biomarker_unweighted_gap')],
 ['Official biomarker weight',ci('survey_biomarker_fair'),ci('survey_biomarker_pef'),ci('survey_biomarker_gap')],
 ['Official individual weight',ci('survey_individual_fair'),ci('survey_individual_pef'),ci('survey_individual_gap')]])
note('Notes: N = 13,515 in every row. Each outcome uses weighted within-sample standardization and the same primary covariates. Estimates and 95% community-clustered intervals are in SD units. The difference is tested within person, retaining cross-outcome covariance.')
para('With biomarker weights, the paired difference is 0.137 SD (95% CI 0.072 to 0.201), compared with 0.120 (0.073 to 0.167) without weights on the same support. Individual weights give 0.134 (0.078 to 0.190). Retaining the original unweighted 2015 outcome scales gives differences of 0.133 and 0.131 SD under the two weights, respectively; the conclusion does not depend on weighted rescaling.')
para('Unequal official weights reduce effective sample size to 5,075 for biomarker weights and 7,389 for individual weights. The biomarker-weighted PEF interval widens to −0.063 to 0.045 SD. Thus the association difference remains clear, while precision about the size of the PEF association is weaker than in the unweighted model.')
para('These are weighted regressions with community-robust inference, not a reconstruction of the full stratified national survey design. The released weights do not automatically correct the requirement to participate in the 2014 life-history survey or provide D5. They therefore do not make this linked subset nationally representative. Official biomarker weights are not multiplied by the estimated completion weights in H1, because both already address overlapping response processes.')
para('Weighted standard deviations use weighted second central moments with an n/(n−1) correction, reproducing ordinary sample standard deviations under constant weights. Official weights are held fixed; estimated IPW uncertainty is incorporated by bootstrap refitting.')
heading('H3 Earlier outcomes and equivalence sensitivity',True)
para('The paired comparison is repeated within 2011 and 2013, using contemporaneous self-rated health and peak flow, age at measurement and the same control definitions. Both equations in each wave use identical respondents and wave-specific outcome standard deviations. Fair-or-better health is harmonized across the two question forms; baseline identifiers are linked using the documented adjustment.')
table('Table H4  Paired comparisons before the recall survey',['Wave and N','Self-rated health','Peak flow','Paired difference'],[[f"{yr} (N = {M[str(yr)+'_gap']['n']:,})",ci(str(yr)+'_fair'),ci(str(yr)+'_pef'),ci(str(yr)+'_gap')] for yr in [2011,2013,2015]])
note('Notes: Estimates and 95% community-clustered intervals are in SD units. Earlier-wave difference tests have p = 0.0154 and 0.0058; both remain below 0.05 after Holm correction across those two tests. Respondents overlap across waves; these are not independent replications.')
para('The difference predates the 2014 recall interview, which argues against an explanation confined to 2015 health shocks. It cannot exclude earlier or persistent health influencing the later recollection, stable reporting tendencies, selection or confounding. D5 itself is still measured retrospectively in 2014.')
table('Table H5  Exploratory equivalence tests for 2015 PEF',['Margin (SD)','Unweighted TOST p','Biomarker-weighted p','Both below 0.05'],[[f"±{delta:.3f}",f"{R['tost'][str(delta)]['p_tost']:.4f}" if R['tost'][str(delta)]['p_tost']>=.0001 else '<0.0001',f"{R['tost_survey_biomarker'][str(delta)]['p_tost']:.4f}" if R['tost_survey_biomarker'][str(delta)]['p_tost']>=.0001 else '<0.0001','Yes' if R['tost'][str(delta)]['equivalent_at_05'] and R['tost_survey_biomarker'][str(delta)]['equivalent_at_05'] else 'No'] for delta in [.025,.05,.1]])
note('Notes: TOST uses two one-sided community-clustered t tests; the reported p is their maximum. All margins were considered after seeing the original estimates. None is presented as a prespecified clinically meaningful threshold.')
para('The unweighted 90% interval is −0.037 to 0.016 SD and lies within ±0.05, but the biomarker-weighted interval does not. Equivalence at that margin is therefore not a robust conclusion. These exploratory checks describe precision; they do not establish no causal effect or validate an arbitrary threshold.')
para('China Health and Retirement Longitudinal Study (CHARLS). (2017). Followup 2015 release note, version 20171011. Peking University. https://charls.pku.edu.cn/en/data/Release2015.pdf','reference')
idx=max([int(v) for v in doc.xpath('.//w:bookmarkStart/@w:id',namespaces=ns)]+[0])+1
st=etree.Element('{'+ns['w']+'}bookmarkStart');st.set('{'+ns['w']+'}id',str(idx));st.set('{'+ns['w']+'}name','RobustnessH');en=etree.Element('{'+ns['w']+'}bookmarkEnd');en.set('{'+ns['w']+'}id',str(idx));h.insert(1,st);h.append(en)
assert ppr==[etree.tostring(p.find('w:pPr',ns)) for p in ps]
assert rpr==[etree.tostring(q) for p in ps for q in p.xpath('.//w:rPr',namespaces=ns)]
assert tabs==[etree.tostring(t) for t in tables]
assert all(text(p)==before[i] for i,p in enumerate(ps) if i not in edited)
dest=root/'SURA_Selection_Robustness_Revision.docx';xml=etree.tostring(doc,xml_declaration=True,encoding='UTF-8',standalone=True)
with ZipFile(dest,'w',ZIP_DEFLATED) as zz:
 for e in z.infolist():zz.writestr(copy(e),xml if e.filename=='word/document.xml' else z.read(e.filename))
with ZipFile(dest) as zz:assert all(zz.read(n)==z.read(n) for n in z.namelist() if n!='word/document.xml')
audit={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'all_previous_paragraph_and_run_properties_unchanged':True,'all_previous_tables_images_styles_and_sections_unchanged':True,'edited_paragraph_indices':edited,'all_previous_appendix_text_unchanged':True,'new_appendix':'H','new_tables':5,'TSP_frozen':True}
(root/'Replication/document_verification.json').write_text(json.dumps(audit,indent=2));print(dest)
