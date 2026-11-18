from project_paths import INPUTS, stage_dir, check_document_text
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from copy import deepcopy,copy
from lxml import etree
import hashlib,json
root=stage_dir('discordance')
source=stage_dir('objective')/'SURA_Objective_Health_Revision.docx'
check_document_text(source, 'a7675539d551ff9b12e537bee4947ba72de727662e43870b822b60c72322215c')
z=ZipFile(source);doc=etree.fromstring(z.read('word/document.xml'));ns=dict(doc.nsmap);ns['a']='http://schemas.openxmlformats.org/drawingml/2006/main';ns['wp']='http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'
b=doc.find('w:body',ns);ps=b.findall('w:p',ns);tables=b.findall('w:tbl',ns)
R=json.loads((root/'Replication/discordance_results.json').read_text());M=R['models'];C=R['contrasts']
def plain(x):return ''.join(x.xpath('.//w:t/text()',namespaces=ns))
def settext(x,t):
 ts=x.xpath('.//w:t',namespaces=ns);assert ts
 ts[0].text=str(t);ts[0].set('{http://www.w3.org/XML/1998/namespace}space','preserve')
 for a in ts[1:]:a.text=''
def clone(x):
 q=deepcopy(x)
 for a in q.xpath('.//w:bookmarkStart|.//w:bookmarkEnd',namespaces=ns):a.getparent().remove(a)
 return q
ppr=[etree.tostring(x.find('w:pPr',ns)) if x.find('w:pPr',ns)is not None else None for x in ps]
rpr=[etree.tostring(x) for p in ps for x in p.xpath('.//w:rPr',namespaces=ns)]
tbl=[etree.tostring(t) for t in tables]
frozen=[etree.tostring(x) for x in ps[357:]]
changes={
4:'Early-life environmental conditions may shape health long after exposure, yet retrospective neighborhood assessments and historical pollution records capture different dimensions of this relationship. This study examines their associations with health in China using the China Health and Retirement Longitudinal Study, its 2014 life-history survey, and historical total suspended particulate (TSP) concentrations from 1981–1995. Reported-outcome analyses use 15,797 adult main respondents with emotional items and 18,058 with harmonized general-health responses; adult offspring are examined separately in 25,406 family records. Historical pollution models use 6,539 linked records. A favorable recalled neighborhood is associated with a 0.320-point higher emotional-response count and a 4.66 percentage point higher adjusted probability of fair or better self-rated health. A paired analysis of 13,720 main respondents in 2015 compares standardized self-rated health with peak expiratory flow using identical covariates. The associations are 0.115 and −0.010 standard deviations, respectively; their difference is 0.126 (95% CI 0.079 to 0.172). Measurement-quality and body-size checks retain near-zero peak-flow estimates. On a fixed 11,719-person sample, adding depressive symptoms and measured and reported health reduces the self-rated-health association from 4.89 to 2.50 percentage points. Reported physician-diagnosed lung disease is also associated with recalled neighborhood conditions, whereas hypertension is not clearly associated. These findings distinguish health dimensions without identifying reporting bias or causal pathways. The historical TSP estimates remain imprecise. Retrospective exposure reporting, selection and geographical assignment continue to limit causal interpretation.',
241:'The paired analysis formally distinguishes the reporting and peak-flow associations. Among 13,720 respondents, their standardized coefficients differ by 0.126 SD (95% CI 0.079 to 0.172). Quality and height checks retain near-zero peak-flow estimates. Appendix G presents the paired test and explanatory analyses.',
243:'On the same 11,719 respondents, depressive symptoms and health controls reduce the self-rated-health association from 4.89 to 2.50 percentage points. Reported diagnosed lung disease also shows an association. The pattern supports differences across health dimensions, but does not establish reporting bias or causal mediation. Geography and exposure timing remain unresolved for causal pollution analysis.',
246:'The formal paired comparison establishes a difference between standardized self-rated-health and peak-flow associations. Current depressive symptoms and reported health account for part of the former association; measured indicators alone change it little. This pattern warrants a multidimensional interpretation, while leaving recall, confounding and causal mechanisms unresolved.',
356:'The initial matched-sample comparison uses 13,720 respondents: the Probit contrast for fair-or-better health is 5.10 percentage points (95% CI 3.44–6.76), and the peak-flow difference is −1.28 L/min (−5.21 to 2.66). Appendix G extends this comparison with standardized linear models and a formal paired test. Their difference is 0.126 SD (0.079 to 0.172), corroborated by community resampling. This establishes a scale-specific association difference, while different health constructs and residual confounding prevent an inference of reporting bias.'
}
for i,t in changes.items():settext(ps[i],t)
# New static TOC entry, preserving all existing entries.
q=clone(ps[44]);ts=q.xpath('.//w:t',namespaces=ns);ts[0].text='Appendix G Differences across health measures'
for x in ts[1:]:x.text=''
ts[-1].text='46'
for h in q.xpath('.//w:hyperlink',namespaces=ns):h.set('{'+ns['w']+'}anchor','DiscordanceG')
b.insert(b.index(ps[45]),q)
roles={}
for key,prefix in [('title','Appendix E Measured'),('heading','E1 Sample'),('body','The extension links'),('caption','Table E1'),('note','Notes: Counts are individuals'),('reference','Barker, D. J.')]:
 roles[key]=next(p for p in ps if plain(p).startswith(prefix) and (key!='title' or p is not ps[43]))
section=b.find('w:sectPr',ns)
def add(q):b.insert(b.index(section),q);return q
def para(t,role='body',newpage=False):
 q=clone(roles[role]);settext(q,t)
 for h in q.xpath('.//w:hyperlink',namespaces=ns):
  if not plain(h):h.getparent().remove(h)
 if newpage and q.find('w:pPr/w:pageBreakBefore',ns)is None:etree.SubElement(q.find('w:pPr',ns),'{'+ns['w']+'}pageBreakBefore')
 return add(q)
def heading(t,newpage=False):return para(t,'heading',newpage)
def caption(t):return para(t,'caption')
def note(t):return para(t,'note')
template=tables[10] # E1 uses the original four-column source pattern.
assert len(template.findall('w:tr',ns)[0].findall('w:tc',ns))==4

def table(headers,rows):
 q=clone(template);tr=q.findall('w:tr',ns);head=deepcopy(tr[0]);row=deepcopy(tr[1])
 for x in tr:q.remove(x)
 for vals,t in [(headers,head)]+[(r,row) for r in rows]:
  a=deepcopy(t)
  for c,v in zip(a.findall('w:tc',ns),vals):settext(c,v)
  q.append(a)
 return add(q)
def values(key,scale=1,digits=2):
 v=M[key];return [f"{v['n']:,}",f"{scale*v['b']:.{digits}f}",f"({scale*v['low']:.{digits}f}, {scale*v['high']:.{digits}f})"]
rels=etree.fromstring(z.read('word/_rels/document.xml.rels'));rn=rels.nsmap[None]
fp=next(p for p in ps if p.xpath('.//wp:docPr[@name="Figure 12"]',namespaces=ns))
def figure(n,height):
 q=clone(fp);rid=f'rIdDiscordance{n}';etree.SubElement(rels,'{'+rn+'}Relationship',Id=rid,Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image',Target=f'media/discordance_figure{n}.png')
 for a in q.xpath('.//a:blip',namespaces=ns):a.set('{'+ns['r']+'}embed',rid)
 ex=q.find('.//wp:extent',ns);cy=round(int(ex.get('cx'))*height/8);ex.set('cy',str(cy))
 for a in q.xpath('.//a:xfrm/a:ext',namespaces=ns):a.set('cy',str(cy))
 for a in q.xpath('.//wp:docPr',namespaces=ns):a.set('id',str(n*10));a.set('name',f'Figure {n}');a.set('descr','Actual regression estimates with community-clustered 95% confidence intervals.')
 for a in q.xpath('.//*[local-name()="cNvPr"]'):a.set('id',str(n*10));a.set('name',f'Figure {n}')
 add(q)
# 48
h=para('Appendix G Differences across health measures','title',True)
heading('G1 A formal paired comparison')
para('The central comparison uses the same 13,720 respondents in 448 communities. Fair-or-better self-rated health and peak expiratory flow are separately centered and divided by their sample standard deviations, 0.4383 and 125.20 L/min. Higher values indicate better health in both outcomes. Linear models use identical age, age-squared, sex, province and childhood-finance covariates; the binary outcome is estimated as a linear probability model.')
figure(13,3.5);caption('Figure 13  Paired standardized neighborhood associations')
note('Notes: All three rows use the same people and controls. Intervals use community clustering and t(447) reference values. The difference is self-rated health minus peak flow; it is tested directly, not inferred from separate significance tests.')
para('The self-rated-health coefficient is 0.115 SD (95% CI 0.078 to 0.153), compared with −0.010 SD (−0.042 to 0.021) for peak flow. Their difference is 0.126 SD (0.079 to 0.172; p < 0.001). Regressing the within-person difference of standardized outcomes retains their covariance. A separate cross-equation cluster-score calculation reproduces its standard error.')
para('A community pairs bootstrap resamples all records within selected communities in 1,999 draws and recomputes both standard deviations and coefficients. Its percentile interval for the difference is 0.080–0.173 SD. Excluding four proxy-flagged records does not change the conclusion. These follow-up analyses were motivated by the earlier results; they were not preregistered.')
para('The test establishes unequal associations on this sample-specific scale. It does not make a dichotomized overall-health report and a respiratory measurement identical constructs, establish equivalence of peak flow, or identify a reporting-bias mechanism.')
# 49
heading('G2 Measurement quality and body size',True)
caption('Table G1  Sensitivity of the peak-flow association')
rows=[('Full effort','pef_full_effort'),('Standing','pef_standing'),('Seated','pef_seated'),('Full effort, standing, three trials','pef_strict_quality'),('Adjust posture','pef_posture_adjusted'),('Adjust height','pef_height_adjusted'),('Flexible age, sex and height','pef_flexible_body_size'),('Never smokers','pef_smoke_never'),('Ever smokers','pef_smoke_ever'),('Former smokers','pef_smoke_former'),('Current smokers','pef_smoke_current'),('Percent of predicted PEF','pef_percent_predicted')]
table(['Specification','N','Difference','95% confidence interval'],[[label]+values(key) for label,key in rows])
note('Notes: Differences are L/min except the last row, which is percentage points of predicted PEF. All models retain primary covariates; smoking strata additionally adjust height. Full effort is QB005=1 and posture uses QB006. These overlapping checks are not independent replications.')
para('All intervals include zero. Adjusting height gives −1.45 L/min, compared with −1.39 in the identical 13,604-person unadjusted-for-height sample. The strict-quality subset retains a standardized self-rated-health minus peak-flow difference of 0.122 SD (95% CI 0.074 to 0.170). The exposure-by-ever-smoking interaction is −4.93 L/min (−11.93 to 2.07; p = 0.167), providing no clear evidence of heterogeneity.')
para('Percent-predicted PEF uses Ji et al. (2021), including the published age-specific spline lookup. For men, the predicted value is 100.4273 − 4.94 × age + 3.4654 × height + Mspline; for women it is 66.9815 − 2.7342 × age + 2.3084 × height + Mspline. Height is in centimeters. Ages outside the lookup range of 40–85 are excluded, with no extrapolation. The estimate is −0.20 percentage points (−1.43 to 1.02; N = 13,527).')
para('This reference was derived from 2011 CHARLS participants, so it is a normalization check rather than independent validation. Internally, reported diagnosed lung disease is associated with about 70 L/min lower peak flow after adjustment for age, sex, height, smoking, province and childhood finances. The instrument detects expected variation, but these checks cannot rule out measurement error or survival selection.')
# 50
heading('G3 Depressive symptoms and health controls',True)
para('To separate covariate adjustment from sample changes, all five specifications in Figure 14 use the same 11,719 complete cases. The measured-health block includes peak flow, systolic and diastolic pressure, and height. The full health block also includes a 14-condition count and six-item ADL limitations. The latter two are questionnaire reports and are not purely objective measurements.')
figure(14,4.3);caption('Figure 14  Self-rated-health associations on a fixed sample')
note('Notes: Estimates are linear-probability differences in percentage points, with community-clustered 95% intervals. Each row adds the stated controls to the same baseline. The final row includes the full health block and CES-D-10. No row changes the estimation sample.')
para('The baseline association is 4.89 percentage points (95% CI 3.16–6.62). It becomes 3.20 (1.61–4.79) with CES-D-10, 4.93 (3.21–6.65) with measured health alone, 3.34 (1.84–4.85) with the full health block, and 2.50 (1.04–3.97) with both blocks. The final reduction is 2.39 points (1.53–3.26), or 48.9% of the baseline coefficient. This percentage is descriptive, not a mediated proportion.')
para('In the larger CES-D-complete sample (N = 12,674), the association declines from 5.06 to 3.19 points, a paired reduction of 1.87 (1.29–2.45). The standardized self-rated-health minus peak-flow difference also declines, from 0.123 to 0.090 SD; its adjusted interval remains above zero (0.044–0.136).')
# 51
heading('G4 Diagnosed conditions and coding checks',True)
caption('Table G2  Associations with reported diagnosed conditions')
table(['Outcome definition','N','Difference (pp)','95% confidence interval'],[
['Physician-diagnosed hypertension']+values('diagnosis_hypertension',100),
['Physician-diagnosed lung disease']+values('diagnosis_lung',100),
['Broader known hypertension']+values('known_hypertension',100),
['Broader known lung disease']+values('known_lung',100)])
note('Notes: Lower disease probability indicates better health. Strict definitions retain explicit new diagnoses or confirmed prior doctor-diagnosis records. Broader definitions also include self-awareness and corrected prior positives whose diagnostic source is ambiguous. Missing values are not coded as absence. Doctor diagnosis is reported by respondents, not verified from clinical records.')
para('The lung-disease difference is −1.25 percentage points (95% CI −2.25 to −0.24; raw p = 0.015; Holm-adjusted p = 0.030 across the two strict outcomes). The hypertension difference is −0.64 points (−2.27 to 0.99; adjusted p = 0.439). The broader definitions retain the same directional pattern. Strict status is unresolved for 425 lung-disease and 734 hypertension records in the matched sample.')
para('On the same 13,295 people with resolved lung-disease status, coding absence of disease as favorable gives standardized coefficients of 0.112 for self-rated health, 0.042 for diagnosed lung disease and −0.013 for peak flow. The self-rated-health minus diagnosis contrast is 0.069 SD (0.021–0.117); diagnosis minus peak flow is 0.055 SD (0.014–0.096). These additional contrasts are exploratory, with pointwise intervals. They suggest an intermediate pattern rather than a uniform division between reported and measured outcomes.')
para('CES-D-10 sums ten 0–3 item scores, reversing hopefulness and happiness, and requires all ten responses. ADL counts any difficulty in dressing, bathing, eating, transfers, toileting and continence. Documented mobility skips are reconstructed before coding skipped ADLs as no difficulty; unexplained blanks remain missing. Disease history combines baseline flags, confirmation, new diagnoses and self-awareness paths rather than reading DA007 alone.')
para('Excluding emotional disease from the control count gives a final association of 2.49 points (1.02–3.95). Requiring six directly observed ADL answers instead selects 7,927 people: the baseline and fully adjusted associations are 4.33 and 1.81 points, with the latter interval spanning −0.16 to 3.79. This subset excludes many respondents routed past ADL questions and cannot substitute for the full matched sample.')
# 52
heading('G5 Interpretation and remaining uncertainty',True)
para('The paired comparison establishes different standardized associations, supported by cluster resampling and measurement checks. Measured health alone leaves the self-rated-health association almost unchanged. Depressive symptoms, reported disease and functional limitations account for more of it, while a positive residual association remains in the main common sample.')
para('The data do not identify why the associations differ. Self-rated health covers more than respiratory performance. Depressive symptoms can represent genuine psychological health, influence health appraisal, or share causes with childhood recall. The 2015 CES-D measure follows the 2014 neighborhood report, so adjustment does not directly observe mood at the time of recall. Physical symptoms also overlap with some depression items. Coefficient attenuation is therefore not evidence that depression caused recall bias.')
para('Likewise, the remaining coefficient cannot be assigned to reporting style. Unmeasured health, social circumstances, measurement error, selection and confounding remain plausible. Current health controls may be consequences of childhood circumstances, making overadjustment or collider bias possible. Reported doctor diagnoses depend on access to care and recall as well as disease. Their intermediate pattern is informative but does not resolve these alternatives.')
para('These findings support an observational contribution: recalled neighborhood conditions relate differently to self-rated health, diagnosed conditions and peak flow. Psychological and reported health measures partly attenuate those differences. Historical TSP estimates remain a separate, frozen analysis; the paired comparison supplies no new causal pollution claim.')
heading('References for Appendix G')
para('China Health and Retirement Longitudinal Study (CHARLS). (2015). Followup questionnaire 2015. Peking University. Health status, functional limitations and depression modules. https://charls.charlsdata.com/Public/ashelf/public/uploads/document/2015-charls-wave4/application/CHARLS_2015_Questionnaire.pdf','reference')
para('China Health and Retirement Longitudinal Study (CHARLS). (2015). Biomarker questionnaire 2015. Peking University. https://charls.pku.edu.cn/en/data/Biomarker2015.pdf','reference')
para('Ji, C., Xia, Y., Dai, H., Zhao, Z., Liu, T., Tong, S., Zhang, X., & Zhao, Y. (2021). Reference values and related factors for peak expiratory flow in middle-aged and elderly Chinese. Frontiers in Public Health, 9, 706524. https://doi.org/10.3389/fpubh.2021.706524','reference')
# Native Word pagination correction limited to Appendix F body paragraph spacing.
# Text, font, figures, tables and statistical content remain unchanged.
layout_only=[]
for i,p in enumerate(ps):
 if i>=357 and p.find('w:pPr/w:pStyle',ns) is not None and p.find('w:pPr/w:pStyle',ns).get('{'+ns['w']+'}val')=='FinalBody':
  pr=p.find('w:pPr',ns);sp=etree.SubElement(pr,'{'+ns['w']+'}spacing');sp.set('{'+ns['w']+'}after','60');sp.set('{'+ns['w']+'}line','330');sp.set('{'+ns['w']+'}lineRule','auto');layout_only.append(i)
# Bookmark and immutable-component checks.
idx=max([int(x) for x in doc.xpath('.//w:bookmarkStart/@w:id',namespaces=ns)]+[0])+1
st=etree.Element('{'+ns['w']+'}bookmarkStart');st.set('{'+ns['w']+'}id',str(idx));st.set('{'+ns['w']+'}name','DiscordanceG');en=etree.Element('{'+ns['w']+'}bookmarkEnd');en.set('{'+ns['w']+'}id',str(idx));h.insert(1,st);h.append(en)
assert all(ppr[i]==(etree.tostring(x.find('w:pPr',ns)) if x.find('w:pPr',ns)is not None else None) for i,x in enumerate(ps) if i not in layout_only)
assert rpr==[etree.tostring(x) for p in ps for x in p.xpath('.//w:rPr',namespaces=ns)]
assert tbl==[etree.tostring(t) for t in tables]
assert all(plain(a)==plain(c) for a,c in zip(etree.fromstring(z.read('word/document.xml')).find('w:body',ns).findall('w:p',ns)[357:],ps[357:]))
changed={'word/document.xml':etree.tostring(doc,xml_declaration=True,encoding='UTF-8',standalone=True),'word/_rels/document.xml.rels':etree.tostring(rels,xml_declaration=True,encoding='UTF-8',standalone=True)}
dest=root/'SURA_Health_Discordance_Revision.docx'
with ZipFile(dest,'w',ZIP_DEFLATED) as zz:
 for e in z.infolist():zz.writestr(copy(e),changed.get(e.filename,z.read(e.filename)))
 for n in [13,14]:zz.writestr(f'word/media/discordance_figure{n}.png',(root/f'Figures/Figure_{n}.png').read_bytes())
with ZipFile(dest) as zz:assert all(zz.read(n)==z.read(n) for n in z.namelist() if n not in changed)
audit={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'all_previous_run_properties_unchanged':True,'paragraph_spacing_only_adjusted':layout_only,'all_previous_tables_unchanged':True,'all_previous_images_unchanged':True,'appendix_F_text_unchanged':True,'TSP_not_reestimated':True,'edited_paragraphs':list(changes),'added_appendix':'G','added_figures':[13,14]}
(root/'Replication/document_verification.json').write_text(json.dumps(audit,indent=2));print(dest)
