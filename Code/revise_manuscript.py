"""Reorganize the verified manuscript, preserving its Word styles and original figures.
All newly tabulated descriptions are read from descriptive_results.json. Existing
model estimates and statistical figures are supplied by the preceding analysis steps.
"""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from copy import deepcopy
from lxml import etree as E
import json,re,hashlib,os
from project_paths import CODE,INPUTS,stage_dir,results_dir
source=stage_dir('fixed')/'SURA_Fixed_Sample_Revision.docx'
z=ZipFile(source);doc=E.fromstring(z.read('word/document.xml'));ns=doc.nsmap
ns.update({'m':'http://schemas.openxmlformats.org/officeDocument/2006/math','w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'})
W=ns['w'];body=doc.find('w:body',ns);old=list(body);out=[];ledger=[];eqn=0;eqmap={};heads=[]
maths={x.get('key'):x[0] for x in E.parse(str(CODE/'equations.xml')).getroot()}
desc=json.loads((results_dir('editorial')/'descriptive_results.json').read_text())
def txt(el):return ''.join(el.xpath('.//w:t/text()',namespaces=ns))
def textset(el,s):
 ts=el.xpath('.//w:t',namespaces=ns)
 if not ts:r=E.SubElement(el,'{'+W+'}r');t=E.SubElement(r,'{'+W+'}t')
 else:t=ts[0]
 t.text=s;t.set('{http://www.w3.org/XML/1998/namespace}space','preserve')
 for t in ts[1:]:t.text=''
 return el
figmap={'1':'2','2':'1','3':'3','4':'10','5':'11','6':'4','7':'5','8':'6','9':'9','10':'12','11':'H1','12':'C1','13':'7','14':'8'}
tabmap={'1':'F1','2':'12','3':'13','4':'14','5':'5','6':'10','7':'11','8':'15','9':'16','C1':'B1','E1':'B2','E2':'6','E3':'C2','F1':'G1','G1':'D1','G2':'9','H1':'D2','H2':'D3','H3':'D4','H4':'7','H5':'D5'}
# Reference substitutions are applied once to each copied source element.
def refs(s):
 s=re.sub(r'\b(Figure|Table) ([A-Z]?\d+)\b',lambda m:m[1]+' '+(figmap if m[1]=='Figure' else tabmap).get(m[2],m[2]),s)
 s=s.replace('Tables 8 and 9','Tables 15 and 16').replace('Appendices G and H','Sections 6.3–6.5 and Appendix D')
 for a,b in [('Section 6.5','Section 6.8'),('Section 5.3','Section 5.7'),('Appendix E','Appendix C'),('Appendix F','Appendix G'),('Appendix G','Appendix D')]:
  # Individual obsolete cross-references are corrected explicitly below where ambiguous.
  if a.startswith('Section'):s=s.replace(a,b)
 return s

def keep(i,new=None):
 global eqn
 if i==414:return None
 el=deepcopy(old[i])
 if new is not None:textset(el,new)
 elif not el.xpath('.//m:oMath',namespaces=ns):
  for para in ([el] if el.tag.endswith('}p') else el.findall('.//w:p',ns)):
   before=txt(para);after=refs(before)
   if after!=before:textset(para,after)
 else:
  ts=el.xpath('.//w:t',namespaces=ns)
  for t in ts:
   if re.fullmatch(r'\(\d+\)',t.text or ''):
    before=int(t.text[1:-1]);eqn+=1;eqmap[before]=eqn;t.text=f'({eqn})'
 if el.tag.endswith('}tbl'):clean_table(el)
 out.append(el);ledger.append({'kind':'retained','source_element':i,'text':txt(el)})
 return el

def ks(a,b):
 for i in range(a,b+1):keep(i)

def p(s,style='FinalBody'):
 el=E.Element('{'+W+'}p');pr=E.SubElement(el,'{'+W+'}pPr');E.SubElement(pr,'{'+W+'}pStyle').set('{'+W+'}val',style)
 r=E.SubElement(el,'{'+W+'}r');t=E.SubElement(r,'{'+W+'}t');t.text=s;t.set('{http://www.w3.org/XML/1998/namespace}space','preserve');out.append(el)
 ledger.append({'kind':'new','text':s});return el

def paras(s):
 for part in s.strip().split('\n\n'):p(part.replace('\n',' '))
def h(s,level=2):
 el=p(s,'FinalHeading'+str(level));heads.append((level,s,el));return el

def eq(key):
 global eqn
 eqn+=1;el=p('','FinalEquation');pr=el.find('w:pPr',ns);el.remove(pr);pr=deepcopy(old[70].find('w:pPr',ns));el.insert(0,pr)
 for child in list(el):
  if child is not pr:el.remove(child)
 r=E.SubElement(el,'{'+W+'}r');E.SubElement(r,'{'+W+'}tab');el.append(deepcopy(maths[key]));r=E.SubElement(el,'{'+W+'}r');E.SubElement(r,'{'+W+'}tab');r=E.SubElement(el,'{'+W+'}r');E.SubElement(r,'{'+W+'}t').text=f'({eqn})'
 ledger[-1].update(kind='equation',key=key,number=eqn);return el

def clean_table(t):
 for ts in t.xpath('.//w:t',namespaces=ns):
  s=ts.text or ''
  for a,b in [('Good childhood environment','Favorable recalled neighborhood'),('Cumulative TSP exposure','Weighted TSP index'),('Temperature total','Weighted temperature'),('Not finish primary','Incomplete primary'),('Finished primary','Completed primary'),('VARIABLES','')]:s=s.replace(a,b)
  ts.text=s
 for tr in t.findall('w:tr',ns):
  pr=tr.find('w:trPr',ns)
  if pr is None:pr=E.SubElement(tr,'{'+W+'}trPr')
  for x in pr.findall('w:trHeight',ns):pr.remove(x)
  if pr.find('w:cantSplit',ns) is None:E.SubElement(pr,'{'+W+'}cantSplit')
 for pr in t.xpath('.//w:pPr',namespaces=ns):
  for x in pr.findall('w:keepNext',ns):pr.remove(x)
 # Preserve coefficients, moving Female with its following standard-error row.
 trs=t.findall('w:tr',ns);female=next((tr for tr in trs if txt(tr).startswith('Female')),None);edu=next((tr for tr in trs if txt(tr).startswith('Incomplete primary')),None)
 if female is not None and edu is not None and trs.index(female)>trs.index(edu):
  nxt=trs[trs.index(female)+1];t.remove(female);t.remove(nxt);idx=t.index(edu);t.insert(idx,female);t.insert(idx+1,nxt)

def table(caption,headers,rows,note,widths=None):
 p(caption,'FinalCaption');t=deepcopy(old[402])
 for tr in t.findall('w:tr',ns):t.remove(tr)
 width=8419;widths=widths or [1]*len(headers);total=sum(widths);widths=[int(x*width/total) for x in widths];widths[-1]+=width-sum(widths)
 grid=t.find('w:tblGrid',ns)
 for child in list(grid):grid.remove(child)
 for w in widths:E.SubElement(grid,'{'+W+'}gridCol').set('{'+W+'}w',str(w))
 cell_template=old[402].find('w:tr/w:tc',ns)
 for ri,row in enumerate([headers]+rows):
  tr=E.SubElement(t,'{'+W+'}tr');pr=E.SubElement(tr,'{'+W+'}trPr');E.SubElement(pr,'{'+W+'}cantSplit')
  if ri==0:E.SubElement(pr,'{'+W+'}tblHeader')
  for ci,val in enumerate(row):
   tc=deepcopy(cell_template);tr.append(tc);tp=tc.find('w:tcPr',ns);cw=tp.find('w:tcW',ns);cw.set('{'+W+'}w',str(widths[ci]))
   for child in list(tc):
    if child is not tp:tc.remove(child)
   pp=E.SubElement(tc,'{'+W+'}p');pr=E.SubElement(pp,'{'+W+'}pPr')
   spacing=E.SubElement(pr,'{'+W+'}spacing');spacing.set('{'+W+'}after','40');spacing.set('{'+W+'}before','40');spacing.set('{'+W+'}line','240');spacing.set('{'+W+'}lineRule','auto')
   E.SubElement(pr,'{'+W+'}jc').set('{'+W+'}val','left' if ci==0 else 'center')
   for j,line in enumerate(str(val).split('\n')):
    r=E.SubElement(pp,'{'+W+'}r');rp=E.SubElement(r,'{'+W+'}rPr');f=E.SubElement(rp,'{'+W+'}rFonts')
    for name in ['ascii','hAnsi','eastAsia','cs']:f.set('{'+W+'}'+name,'Times New Roman')
    E.SubElement(rp,'{'+W+'}sz').set('{'+W+'}val','20');E.SubElement(rp,'{'+W+'}szCs').set('{'+W+'}val','20')
    if ri==0:E.SubElement(rp,'{'+W+'}b')
    if j:E.SubElement(r,'{'+W+'}br')
    E.SubElement(r,'{'+W+'}t').text=line
 out.append(t);ledger.append({'kind':'new_table','caption':caption,'rows':rows});p(note,'FinalNote')

# Front matter retains the source section settings and title typography.
keep(0,'Early-Life Environment and Adult Health in China:')
keep(1,'Recalled Childhood Neighborhood Conditions, Historical Air Pollution, and Self-Rated versus Measured Health');keep(2);keep(3)
p('''Early-life environmental conditions, including air pollution, may affect health decades later, but survey evidence often relies on respondents’ reports of both exposure and health. This study compares associations of recalled childhood neighborhood conditions with self-rated health and measured physical function using the China Health and Retirement Longitudinal Study (CHARLS), its 2014 life-history survey and 2015 physical examinations. Among 13,720 main respondents, self-rated health and peak expiratory flow are standardized within the same sample and regressed on identical covariates. Their difference is tested with community-clustered inference and cluster resampling. A favorable recalled neighborhood is associated with 0.115 SD better self-rated health but no detectable peak-flow difference (−0.010 SD; 95% CI −0.042 to 0.021). The coefficient difference is 0.126 SD (95% CI 0.079 to 0.172). It persists under measurement-quality restrictions, selection and survey weighting, and in 2011 and 2013 health outcomes measured before the recall interview. On a fixed sample, adding depressive symptoms and measured and reported health reduces the self-rated-health association from 4.89 to 2.50 percentage points; measured indicators alone change it little. Reported physician-diagnosed lung disease shows an intermediate pattern. Historical total suspended particulate (TSP) exposure estimates linked to 6,539 younger records likewise show no detectable association with reported health, predominantly parent-reported offspring health, in Probit or instrumental-variable Probit models; imprecision and weak birth-year instruments limit interpretation, and this sample is not directly comparable with the main respondents. Recalled childhood environments therefore relate differently to different dimensions of adult health; whether the difference reflects psychological health, broader physical health or reporting remains unidentified.''','FinalAbstractText')
p('Keywords: Early-life environment; air pollution; childhood neighborhood; self-rated health; peak expiratory flow; retrospective reports; CHARLS')
keep(6);keep(7)
# Insert a real Word TOC field; cached entries and page references are refreshed after pagination.
toc=p('','FinalTOCLine');r=E.SubElement(toc,'{'+W+'}r');E.SubElement(r,'{'+W+'}fldChar').set('{'+W+'}fldCharType','begin')
r=E.SubElement(toc,'{'+W+'}r');E.SubElement(r,'{'+W+'}instrText').text=' TOC \\t "FinalHeading1,1,FinalHeading2,2" \\h \\z '
r=E.SubElement(toc,'{'+W+'}r');E.SubElement(r,'{'+W+'}fldChar').set('{'+W+'}fldCharType','separate')
r=E.SubElement(toc,'{'+W+'}r');E.SubElement(r,'{'+W+'}t').text='Contents'
r=E.SubElement(toc,'{'+W+'}r');E.SubElement(r,'{'+W+'}fldChar').set('{'+W+'}fldCharType','end')
keep(47)
h('1 Introduction',1)
paras('''Childhood neighborhood conditions may influence health through housing, sanitation, social relationships and environmental exposure. Their consequences can continue after the original conditions have changed, through persistent illness, education, behavior and later living circumstances. The fetal-origins hypothesis gives particular attention to developmental conditions (Barker, 1990), while subsequent work considers postnatal health and longer exposure histories (Currie et al., 2010, 2014). These perspectives motivate research on early environments. They also raise a measurement question: when a remembered environment is associated with health reported many years later, which aspects of health does that association describe?

This question matters when both variables come from the same respondent. A retrospective neighborhood rating can contain useful information about childhood housing and local conditions, but it is also a present assessment of the past. Self-rated health summarizes symptoms, functioning and personal expectations that a single physical test cannot fully measure. Current psychological circumstances or a stable reporting tendency may influence both assessments. Conversely, a real association with mental or social health could appear in self-rated health without appearing in respiratory performance. A difference between the outcomes is therefore informative, but neither the presence nor the absence of that difference identifies reporting bias by itself.

Previous CHARLS studies relate childhood neighborhood quality to depressive symptoms, friendship and subsequent symptom trajectories (Chen et al., 2020; Li et al., 2023; Ding et al., 2025). These studies establish the relevance of remembered childhood circumstances to questionnaire-based psychological outcomes. The present study asks a related question about measurement: whether recalled neighborhood conditions have comparable standardized associations with a general health rating and a measured respiratory outcome. Self-rated health is valuable in its own right. Its predictive association with mortality in earlier research cautions against dismissing it as merely subjective noise (Idler and Benyamini, 1997). The comparison instead asks what can be learned by observing both forms of health measurement in the same people.

The analysis links the 2014 life-history neighborhood item to health interviews and physical measurements in CHARLS. The central comparison uses 13,720 main respondents in 2015, standardizes self-rated health and peak expiratory flow within that common sample, and applies identical controls to both outcomes. The coefficient difference is estimated directly with community clustering, retaining the covariance between a person's two outcomes. A community bootstrap also re-estimates the outcome scales. This design avoids interpreting a significant coefficient in one model and an insignificant coefficient in another as evidence that the two coefficients differ. It also avoids confounding their comparison with the different age, sex and location composition of separate estimation samples.

Three findings organize the paper. First, favorable recalled neighborhoods are associated with better self-rated health, but the corresponding peak-flow association is close to zero. The standardized coefficients are 0.115 and −0.010, and their difference is 0.126 (95% CI 0.079 to 0.172). Second, the difference persists after checks of effort, posture, body size, smoking, measurement completion and survey weights. It is also present in 2011 and 2013, before neighborhood conditions were recalled. Third, depressive symptoms and measured and reported health reduce the self-rated-health coefficient from 4.89 to 2.50 percentage points on a fixed complete-case sample. Measured physical indicators alone do not materially reduce it. These results narrow the empirical question from whether the associations differ to what may account for their difference.

Several extensions help describe that pattern. Reported physician-diagnosed lung disease has an association intermediate between self-rated health and peak flow on a common sample. The emotional-response analysis retains the original exploratory scoring rule, while a separate offspring analysis makes clear that the parent's childhood assessment and the parent's report of offspring health concern different generations. Historical total suspended particulate concentrations supply a distinct exposure measure, but the younger pollution-linked sample and uncertain geographical assignment prevent direct comparison with the older main respondents. Those results are retained as supplementary evidence rather than used to validate the recalled neighborhood item. A feasibility audit also explains why the available geographical identifiers are insufficient for a credible Huai River boundary design.

The contribution is threefold. The study first turns a qualitative contrast between reported and measured outcomes into a formal within-sample test. It then examines whether observable measurement quality and participation account for that contrast, using both estimated completion weights and the released survey weights. Finally, it compares adjustment for measured health with adjustment for depressive symptoms, diagnosed conditions and functional limitations, while holding the sample constant. These exercises distinguish empirical patterns that would otherwise be combined in a single health coefficient. They do not estimate a causal neighborhood effect, a mediated proportion or an individual reporting trait. Their value lies in showing which associations survive common-sample comparisons and which explanations remain compatible with the observed data.

Section 2 develops the life-course framework and the three research questions. Section 3 discusses biological pathways and the interpretation of health measures. Sections 4 and 5 describe the data, sample construction and empirical methods. Section 6 presents the self-rated-health results, measured outcomes and formal paired comparison before the measurement, selection and explanatory checks. Emotional health, offspring and historical pollution appear as extensions. Section 7 considers competing interpretations and the limits of the design, and Section 8 concludes. The appendices retain the statistical derivations, full sensitivity tables, measurement inventory, geographical audit and reproduction details. Table 1 provides a guide to the principal estimates; samples and scales are shown separately so that the entries are not read as interchangeable effect sizes.''')
table('Table 1  Guide to the principal analyses',['Analysis','N','Estimate and 95% interval','Section'],[
['Main self-rated health','18,058','4.66 pp (3.33, 5.98)','6.1'],['2015 peak flow','13,935','−1.29 L/min (−5.20, 2.62)','6.2'],['Paired difference, 2015','13,720','0.126 SD (0.079, 0.172)','6.3'],['Paired difference, 2011','10,808','0.061 SD (0.012, 0.109)','6.3'],['Paired difference, 2013','10,935','0.069 SD (0.020, 0.118)','6.3'],['IPW paired difference','13,720','0.129 SD (0.080, 0.172)','6.4'],['Biomarker-weighted difference','13,515','0.137 SD (0.072, 0.201)','6.4'],['Common-sample SRH baseline','11,719','4.89 pp (3.16, 6.62)','6.5'],['SRH with CES-D and health','11,719','2.50 pp (1.04, 3.97)','6.5'],['Diagnosed lung disease','13,295','−1.25 pp (−2.25, −0.24)','6.5'],['2015 minus 2013 SRH','8,719','2.52 pp (0.28, 4.76)','6.5'],['Emotional-response count','15,797','0.320 points (0.223, 0.416)','6.7'],['Offspring fair-or-better health','25,406','1.16 pp (0.28, 2.05)','6.8'],['TSP birth-year Probit','6,539','−0.000025 (−0.000334, 0.000285)','6.9'],['TSP birth-year IV-Probit','6,539','−0.000247 (−0.00350, 0.00300)','6.9']],
'Notes: pp denotes percentage points. Paired differences subtract the peak-flow coefficient from the self-rated-health coefficient. Rows use their stated samples and models; they do not constitute a joint test across all outcomes. TSP entries are latent-index coefficients per exposure unit; weighted-index results also appear in Section 6.9.',[3100,1050,4210,1000])
# Original theoretical derivations remain editable and intact.
h('2 The fetal origins hypothesis and a life course framework',1);ks(62,66);ks(68,84)
h('2.3 Research questions and their empirical reach')
paras('''The framework motivates three research questions. Q1 asks whether favorable recalled childhood neighborhoods are associated with better self-rated health. Q2 asks whether they are also associated with measured physical health, and whether the standardized self-rated-health and peak-flow coefficients differ on the same sample. Q3 asks whether measurement quality, selection, depressive symptoms and observed health account for the difference. The first question describes an association, the second compares associations formally, and the third evaluates observable explanations without identifying a causal mechanism.

The outcome S in the model need not assign the same weights to health and capability as a respiratory test. Different values of α and β can produce different relationships with an early shock even without reporting error. Under δ = 1 and nonnegative transmission parameters, the weights in equations (4)–(6) are nondecreasing as time passes. A larger self-rated-health association in 2015 than in 2013 on the same people is consistent with this amplification possibility. It is not a test of those parameter restrictions: aging, period conditions and changes in appraisal can produce the same pattern. The empirical comparison cannot separate these processes.

Persistence requires an early exposure and a later outcome; amplification additionally requires comparable observations over time; timing requires distinct exposure windows and a joint comparison. The remembered neighborhood item describes childhood broadly and was recorded in 2014. Outcomes from 2011 and 2013 precede that recollection, while 2015 outcomes follow it. The regressions therefore do not estimate developmental trajectories or distinguish prenatal from postnatal effects. They examine the reach of a retrospective association across health dimensions and survey occasions.''')
h('3 Biological pathways and health measurement',1);ks(89,94);p('Peak expiratory flow is used below to examine the respiratory dimension of this pathway.');ks(95,100)
h('3.4 Self-rated health and measured physical function')
paras('''A general health rating brings together information about symptoms, limitations, mental health and the respondent's expectations. The review by Idler and Benyamini (1997) finds that self-rated health predicts mortality in many community studies. This predictive value does not require the rating to coincide with a particular biomarker. People may incorporate functional changes or illnesses that a short physical examination does not capture. A favorable rating can also reflect comparison with peers or adaptation to existing illness.

Peak expiratory flow records the maximum speed of expiration during a brief maneuver. It provides a measured respiratory outcome that does not ask respondents to evaluate their own overall health. It is nevertheless affected by effort, posture, technique and body size. A measured outcome is therefore not automatically free of error, and peak flow cannot stand for every physiological consequence of childhood conditions. Blood pressure and height supply complementary information, but neither turns this survey into a comprehensive clinical assessment.

These distinctions motivate the paired analysis. A common-sample standardized comparison describes the relative associations in the observed distributions; it does not make the outcomes biologically equivalent. If self-rated health is associated with recalled neighborhood quality while peak flow is not, possible explanations include psychological or social health, other unmeasured physical conditions, differential measurement error and shared reporting influences. The quality checks and adjustment exercises are organized around these alternatives. Their purpose is to assess how much of the contrast can be described by observed variables, rather than to designate one outcome as the correct measure of health.''')
h('4 Data and variable construction',1);ks(102,106);ks(107,110)
h('4.3 Self-rated health and harmonized response categories');ks(131,132)
p('For the paired comparisons, fair-or-better health is a binary outcome estimated by a linear probability model before standardization. The original main-sample Probit and ordered models are retained as separate descriptions. Their coefficients and average probability contrasts should not be compared directly with standardized linear coefficients. Response wording, rather than the raw numerical category alone, determines the harmonized health threshold in every wave.')
h('4.4 Measured health outcomes');ks(347,347);ks(351,352)
p('Peak flow is the primary measured outcome. The construction requires at least two valid trials, keeps the maximum valid reading and excludes values outside the retained range of 30–890 L/min. The primary measured-health analysis uses age, age squared, sex, childhood finances and province indicators. Age at the examination is used. Height is added in a same-sample sensitivity analysis because it predicts lung volume and may itself reflect earlier conditions. Other sensitivity models allow more flexible age, sex and height relationships.')
p('Percent-predicted peak flow uses the sex-specific reference equations of Ji et al. (2021). Let A be age in years, H height in centimeters and M the published sex- and age-specific spline value. The equations are:');eq('male');eq('female');eq('predicted')
p('The published lookup covers ages 40–85. No extrapolation is made outside that range, and predictions must be positive. This reference was estimated using 2011 CHARLS participants; it is a normalization check rather than an independent validation sample. Effort and posture are taken from QB005 and QB006, respectively, and smoking is grouped from the contemporaneous health interview. Blood pressure is summarized from valid repeated readings and height from the biomarker module. Appendix B lists the construction rules and Appendix C gives the full outcome results.')
h('4.5 Depressive symptoms diagnosed conditions and daily activities');keep(420)
p('CES-D-10 follows the standard symptom-frequency scoring rather than the extreme-response count used in the emotional extension. With eight negatively worded items in set N and hopefulness and happiness in set P, its score is:');eq('cesd')
p('All ten items must be observed, yielding a score from 0 to 30 with higher values indicating more symptoms. Chen and Mui (2014) discuss the scale in older Chinese adults. The 2015 score measures mood after the 2014 recall interview; it is not a direct measure of mood during recall. The health-control block adds the count of 14 reported conditions and six ADL limitations to peak flow, systolic and diastolic pressure and height. These additional questionnaire measures are kept distinct from examination measurements. Strict physician-diagnosis outcomes exclude ambiguous diagnostic sources; broader known-condition definitions are reported as sensitivity checks.')
h('4.6 Emotional response count');ks(126,128);keep(129,refs(txt(old[129])).replace('Appendix C','Appendix B'))
h('4.7 Historical pollution meteorology and exposure windows');ks(112,113);ks(57,59);ks(114,119);ks(121,123);keep(67)
keep(136);keep(137);ks(138,140)
p('The labels cubic and quartic identify two archived exposure files with different contents. The available code does not establish the interpolation exponent, neighborhood search or coordinate system that produced either file. In particular, the labels cannot be treated as documentation of inverse-distance powers. No QGIS project, interpolation script or operation record is available. The analysis uses the archived cubic regression input and the quartic descriptive series as specified in the original project, without claiming to reconstruct the spatial interpolation.')
h('4.8 Covariates and reporting units');keep(133);keep(134,txt(old[134]).replace('Appendix B','Appendix A'))
p('The main reported-health models and the paired measured-health models retain their respective covariate sets. In the former, education indicators and survey-wave indicators describe the combined sample. In the latter, province indicators and childhood financial circumstances help account for broad geographical and early socioeconomic differences. Education is displayed as categorical proportions in the paired-sample description, not as a meaningful numerical average. The two control sets answer different descriptive questions; changing controls is not used to create an apparent agreement across models.')
h('4.9 Sample construction and descriptive comparisons')
table('Table 2  Characteristics of the 2015 paired sample',['Characteristic','Less favorable\nMean (SD); N','Favorable\nMean (SD); N','Difference'],[[x['label'],*[f"{x['groups'][k]['mean']:.2f} ({x['groups'][k]['sd']:.2f}); {x['groups'][k]['n']:,}" for k in ['0','1']],f"{x['difference']:.2f}"] for x in desc['descriptive_table']],
'Notes: The paired sample contains 13,720 respondents: 5,027 in the less favorable group and 8,693 in the favorable group. Differences are favorable minus less favorable and are unadjusted. N is variable-specific; missing supplementary measures do not remove respondents from the main paired sample. Percentage rows report the mean and SD of the indicator multiplied by 100. Education proportions use respondents with observed education.',[3000,2480,2480,1400])
p('The raw peak-flow difference is negative, whereas the self-rated-health difference is positive. The favorable group is also older and more often female, both relevant to respiratory performance. These descriptive contrasts are not the adjusted paired estimates. They show why comparing the two unadjusted means is insufficient and why both outcome regressions use the same controls. Supplementary variables have different available sample sizes; requiring all of them would change the primary comparison.')
table('Table 3  Construction of the 2015 analysis samples',['Step','Remaining N'],[['Biomarker records','16,406'],['Linked valid childhood neighborhood rating','14,898'],['Age at least 45','14,269'],['At least two valid peak-flow trials','13,978'],['Complete primary covariates','13,935'],['Harmonized self-rated health also observed','13,720'],['Complete CES-D and full health-control block','11,719']],
'Notes: Each row applies the next restriction to the preceding row. The selection analysis uses a separate denominator beginning with health interviews, including people without a biomarker record. Its denominator should not be confused with this biomarker-based construction.',[7000,2360])
table('Table 4  Relationship between the estimation samples',['Analysis','N','Unit and scope'],[['Original general-health model','18,058','Main respondent; selected later or earlier wave'],['Original emotional-response model','15,797','Main respondent; ten complete emotional items'],['Offspring neighborhood model','25,406','Adult family record; health reported by parent'],['Historical TSP model','6,539','6,531 offspring and 8 main-respondent records'],['2015 paired health models','13,720','Same respondent and covariates for both outcomes'],['2015 common adjustment sample','11,719','Complete CES-D and measured/reported health'],['2013–2015 fixed sample','8,719','Complete outcome and covariates in both waves']],
'Notes: Samples overlap but are not interchangeable. The 4.66-point original Probit average contrast, 5.10-point matched-sample Probit contrast and 4.89-point common-sample linear coefficient refer to different samples or models. None replaces the primary standardized paired contrast.',[3600,1000,4760])
p('The 2015 peak-flow and paired sample sizes are 13,935 and 13,720 under the reproduced eligibility rules. The fixed-wave comparison begins with 8,894 people observed in both peak-flow samples, excludes 25 with missing model covariates and another 150 with incomplete self-rated health, and retains 8,719. These exclusions are applied before estimating either year. Archived descriptive summaries for the original reported-outcome and TSP samples remain in Appendix F.')
# Empirical methods
h('5 Empirical methods and identification',1);ks(145,151);keep(152,txt(old[152]).replace('Appendix B','Appendix A'));keep(153);ks(154,159)
h('5.3 Paired standardized associations')
p('Let S denote fair-or-better self-rated health and P denote peak flow. Both outcomes use the same 13,720 respondents, D denotes the favorable recalled-neighborhood indicator, and X contains the primary covariates. Standardization uses the sample mean and sample standard deviation of each outcome:');eq('standard');eq('paired')
p('The self-rated-health equation is linear in the binary outcome before standardization. The parameters are adjusted mean differences, not Probit index coefficients. The central null hypothesis compares the two neighborhood coefficients:');eq('difference');eq('covariance')
p('Regressing the within-person difference ZS − ZP on the same design matrix gives exactly the coefficient difference. Community-clustered inference preserves dependence across the two outcomes and across people in the same community. A separate cross-equation score calculation verifies its standard error. The primary interval uses a t reference with 447 degrees of freedom for 448 communities. This is a test of equal standardized associations, not a comparison of two significance labels.')
p('A community pairs bootstrap resamples whole communities with replacement. Each draw re-estimates both standard deviations and both equations, so uncertainty from standardization is included in the resampled estimate. With 1,999 draws, the percentile interval is:');eq('bootstrap')
p('Earlier-wave comparisons use their own common samples, contemporaneous controls and outcome standard deviations. They test the same within-wave contrast. They are not independent replications because respondents overlap, and a comparison of their point estimates alone is not a formal test of change over time.')
h('5.4 Measurement completion and survey weights')
p('Measurement completion is first treated as an outcome. The denominator begins with 2015 health interviews, retains valid D5, age and primary covariates, and includes people without any biomarker record. Linear probability models estimate the adjusted association between D5 and a valid peak-flow test. Among interviewees with observed self-rated health, a selection logit then predicts completion using D5, the primary controls and that health rating. For observed tests, inverse-probability weights and their capped version are:');eq('ipw');eq('ess')
p('The cap is the 99th percentile of uncapped weights among observed tests. Effective sample size summarizes the concentration of weights; it is not the number of independent clusters. The IPW comparison uses 999 community resamples, refitting selection probabilities, weights, outcome scales and regressions in each draw. Identification of a full-eligible-sample association still requires that missing peak flow be conditionally exchangeable with observed peak flow and that completion probabilities remain positive.')
p('Official biomarker and individual weights are examined separately on their common support. Biomarker weights already incorporate response adjustments, so they are not multiplied by the estimated completion weights. For weighted standardization, the outcome mean and variance are:');eq('weightedmean');eq('weightedsd')
p('This variance convention reduces to the ordinary sample variance under equal weights. Both equations use the same weights, controls and observations. Comparisons retaining the original unweighted outcome scales distinguish weighting from rescaling. Official weights are held fixed and inference remains clustered by community; the exercise does not reconstruct the entire stratified survey design.')
h('5.5 Covariate adjustment and the fixed-wave comparison')
p('The adjustment analysis fixes the sample at 11,719 complete cases before adding any control block. Baseline, CES-D-only, measured-health-only, full-health and combined models therefore differ in covariates rather than respondents. The absolute and proportional coefficient reductions are:');eq('attenuation')
p('The reduction is estimated jointly on the common sample, retaining the covariance of baseline and adjusted coefficients. It is descriptive. Current health and depressive symptoms may be consequences of earlier conditions or share unobserved causes with the exposure report. The proportional reduction cannot be interpreted as the fraction causally mediated by those controls.')
p('The exploratory comparison of 2013 and 2015 fixes a second sample at 8,719 people with complete information in both waves. The stacked model allows the intercept, neighborhood coefficient and every control coefficient to vary by wave:');eq('fixed');eq('yearcontrast')
p('Community clustering accounts for repeated records and within-community dependence. The raw binary-outcome contrast is reported in percentage points. Standardizing both years with the 2013 outcome SD gives a common-scale comparison; separate within-year standardization is a sensitivity check. Fixing respondents excludes composition change as the sole explanation, but does not separate aging from calendar-period conditions or changes in reporting.')
h('5.6 Exploratory equivalence tests')
p('A confidence interval containing zero does not establish equivalence. Two one-sided tests describe whether the peak-flow association is contained within a chosen symmetric margin m on the standardized scale:');eq('tostnull');eq('toststats');eq('tostp')
p('G is the number of communities. Equivalence requires rejection of both one-sided nulls. Margins of 0.025, 0.05 and 0.10 SD are sensitivity values considered after observing the initial results; none was prespecified or established as a clinical threshold. Both unweighted and biomarker-weighted estimates are reported, so precision is not judged only from the narrower unweighted interval.')
h('5.7 Historical TSP and instrumental variables');ks(161,166)
h('5.8 Inference and exploratory scope');ks(168,170)
p('The paired comparison is the central descriptive test. Secondary outcomes and overlapping quality subsets provide sensitivity evidence rather than independent confirmations. Holm adjustment is reported for the two strict diagnosis outcomes and for the two earlier-wave paired tests. Other intervals are pointwise unless stated otherwise. The analysis developed after the original reported-health results; the quality, selection, adjustment, equivalence and fixed-wave exercises were not preregistered. Appendix I records that sequence without presenting exploratory choices as prospective hypotheses.')
# Main results
h('6 Results',1);h('6.1 Recalled neighborhoods and self-rated health');ks(200,216)
h('6.2 Measured health outcomes');keep(354);keep(356);ks(357,359);keep(360);keep(364)
p('The staged 2015 peak-flow coefficient changes from −2.52 L/min with age and sex adjustment to 0.41 after province indicators, and to −1.29 in the primary model. These changes show the relevance of geographical composition, but all intervals include zero. Systolic and diastolic pressure and height provide complementary measured outcomes. Their estimates do not supply a clear favorable-neighborhood pattern. The full staged specification and wave-specific results are retained in Appendix C, with the statistical figure generated from those same estimates.')
h('6.3 Formal comparison of self-rated health and peak flow');keep(393);ks(394,399);keep(452);ks(453,455)
p('The earlier-wave differences are 0.061 SD in 2011 and 0.069 SD in 2013. Because both health measures precede the 2014 recollection, an explanation confined to a contemporaneous 2015 shock is insufficient. Persistent health may nevertheless influence the later recollection, and stable reporting tendencies or unobserved childhood conditions can affect multiple waves. The earlier-wave checks therefore change the timing argument without resolving the direction of causation.')
h('6.4 Measurement quality selection and weights');keep(404);keep(406)
# Compact synthesis retains original units where a paired coefficient was not estimated.
table('Table 8  Summary of measurement and selection checks',['Specification','N','PEF association','Paired difference (SD)'],[
['Full effort','13,537','−1.76 L/min (−5.63, 2.11)','0.126 (0.079, 0.173)'],['Standing','12,941','−0.53 L/min (−4.54, 3.49)','0.123 (0.075, 0.171)'],['Full effort, standing, three trials','12,729','−0.76 L/min (−4.76, 3.25)','0.122 (0.074, 0.170)'],['Height adjusted','13,604','−1.45 L/min (−5.32, 2.41)','Not estimated'],['Percent-predicted PEF','13,527','−0.20 pp (−1.43, 1.02)','Not estimated'],['Never smokers','7,987','0.14 L/min (−4.07, 4.36)','Not estimated'],['Inverse probability weighted','13,720','−0.013 SD (−0.045, 0.018)','0.129 (0.080, 0.172)'],['IPW capped at 99th percentile','13,720','−0.013 SD (−0.045, 0.018)','0.129 (0.080, 0.173)'],['Official biomarker weight','13,515','−0.009 SD (−0.063, 0.045)','0.137 (0.072, 0.201)'],['Official individual weight','13,515','−0.012 SD (−0.054, 0.030)','0.134 (0.078, 0.190)']],
'Notes: Intervals are 95%. Outcome units are shown explicitly; the first six rows are not standardized peak-flow coefficients. A paired difference is reported only where the retained specification estimated it. IPW uses bootstrap intervals; other displayed intervals use community-clustered inference. Detailed quality and weighting results appear in Appendix D.',[2900,900,2860,2700])
keep(433);keep(437);keep(441);ks(443,443);ks(447,449)
p('These checks preserve the positive difference between standardized health associations. They do not prove that completion is ignorable: the completion models address observed interviewees with valid childhood reports, not survival to the survey or participation in life-history recall. The official biomarker weights substantially widen the peak-flow interval. Appendix D therefore reports equivalence tests under both weighting choices; the ±0.05 SD margin is supported by the unweighted test but not by the biomarker-weighted test.')
h('6.5 Depressive symptoms diagnosed conditions and change over time');ks(408,419)
p('The diagnosis comparison also helps assess scale. Reported diagnosed lung disease is associated with about 70 L/min lower peak flow after adjustment. Multiplying that descriptive difference by the 1.25-percentage-point lower prevalence gives approximately 0.9 L/min higher average peak flow. This rough calculation lies within the observed peak-flow interval and shows that the diagnosis association need not imply a detectable aggregate respiratory contrast. It is not a mediation estimate: the diagnoses, covariates and disease severity do not define a causal decomposition of the neighborhood coefficient.')
keep(456)
p('The larger 2015 association on the fixed sample is consistent with several possibilities. In the illustrative dynamic model, some early disadvantages can become more consequential as health and capability interact over time. Aging may also change which symptoms respondents consider when rating health, while period conditions and measurement circumstances may change between surveys. The years 2013 and 2015 lie on opposite sides of the 2014 life-history interview; calendar years alone do not establish that one outcome is closer to the recollection. The fixed-sample result excludes changing respondent composition as a complete explanation, but does not choose among these remaining mechanisms.')
h('6.6 Alternative health thresholds and ordered categories')
keep(218,'Positive neighborhood associations persist across all three harmonized health thresholds (Table 10). The Probit coefficients are 0.146 for fair or better, 0.144 for good or better, and 0.123 for very good or better.');ks(219,228)
p('Education coefficients vary across thresholds. This need not mean that education has a harmful effect at the upper end of the health scale: the models compare different cumulative probabilities, with different baseline category shares and conditional relationships. In the retained main sample, fair-or-better health rises from 62.2% among illiterate respondents to 84.9% among those with high school or above. The corresponding very-good shares are 10.8% and 12.7%; the middle-school share is higher still. Thus a simple monotonic education gradient in the top category is not supported by the descriptive distribution. The ordered model imposes a common index across thresholds and is reported as a complementary summary, not a test that the separate binary slopes are equal.')
h('6.7 Emotional responses and well-being');h('6.7.1 Baseline association',3);ks(174,180);h('6.7.2 Threshold and ordered category sensitivity',3);ks(182,197)
h('6.8 Adult offspring and intergenerational associations');ks(249,250)
p('These records do not measure the offspring’s own recalled childhood neighborhood, and their health is parent-reported. They cannot be pooled with main respondents to increase the sample for the paired objective-health question. A family comparison would additionally need defensible within-family exposure variation and stable offspring identifiers. No sibling fixed-effects estimate is claimed here.')
h('6.9 Historical TSP and reported health');ks(230,236);h('6.9.1 Instrumental variable results',3);ks(238,247)
p('The TSP analysis remains separate from the main paired comparison. Its 72-city sample is mostly adult offspring, whereas the measured-health comparison concerns older main respondents. The weak birth-year first stage and uncertain exposure assignment prevent the historical estimates from deciding whether the recalled-neighborhood association reflects pollution. Further interpretation of these coefficients would require stronger exposure and identification information, rather than additional variants of the same available specification.')
# Discussion is newly integrated instead of scattered limitations.
h('7 Discussion',1);h('7.1 What the three research questions establish')
paras('''The answer to Q1 is that favorable recalled neighborhoods are associated with more favorable self-rated health in the selected CHARLS samples. The association appears under several thresholds and remains after adjustment for childhood finances. Q2 yields a different pattern for measured respiratory performance: the standardized neighborhood coefficients differ when the same people and controls are used. The formal contrast is therefore more informative than contrasting significance levels from separate regressions. Blood pressure and height broaden the measurement comparison, although they do not exhaust the physiological outcomes that may matter for general health.

Q3 is only partly resolved. Effort, posture, height, smoking and observed completion do not account for the paired difference. Official weighting also preserves it, while making the peak-flow estimate less precise. Depressive symptoms, diagnosed conditions and daily activities attenuate the self-rated-health association more than measured physical indicators alone. A residual association remains on the main complete-case sample. These findings identify where the statistical association changes under adjustment; they do not determine which variables lie on a causal pathway or which part of the residual represents unmeasured health.''')
h('7.2 Competing interpretations')
paras('''One interpretation concerns reporting. A respondent who recalls childhood more favorably may also evaluate present health more favorably, producing a stronger association between two reports than between a report and a physical test. Stable appraisal tendencies could also help explain why the difference appears in health ratings obtained before the life-history interview. However, the study does not measure such a tendency directly. The difference cannot be assigned to reporting style simply because measured peak flow contributes little to the self-rated-health coefficient.

A second interpretation concerns psychological and social health. Recalled neighborhood quality may capture social relationships, insecurity or family circumstances with consequences for well-being that are not expressed in peak flow. The CES-D adjustment is compatible with such a relationship. It is equally compatible with depressive symptoms sharing causes with health ratings or influencing appraisal. Since CES-D is measured in 2015, it cannot demonstrate the respondent's emotional state during the 2014 recollection. Treating its coefficient reduction as evidence of recall bias would require information the study does not have.

A third possibility is physical health outside the measured domains. Self-rated health can summarize pain, fatigue, functional restrictions and illnesses that a peak-flow test misses. The intermediate association with reported lung diagnosis is consistent with different health measures containing partly overlapping information. Diagnosis also depends on recognition, access to care and recall, so it is not an independent clinical gold standard. The approximate prevalence-based calculation illustrates that a small disease difference and a near-zero average peak-flow difference can coexist without contradiction.

A fourth possibility concerns change over time. The larger 2015 self-rated-health coefficient on a fixed sample is consistent with amplification in the life-course model under its stated persistence conditions. It is also consistent with aging-related changes in health appraisal, period shocks or changing consequences of existing disease. The model does not identify these alternatives, and the two-wave comparison is exploratory. It establishes that sample composition alone is insufficient, while leaving the source of change open. These four interpretations can coexist rather than requiring a single explanation for every result.''')
h('7.3 Relationship to previous research')
paras('''The results complement CHARLS studies of childhood neighborhoods and depressive symptoms (Chen et al., 2020; Li et al., 2023; Ding et al., 2025). Those associations concern psychological outcomes and do not imply that every measured physiological outcome must show the same relationship. The present contribution is the common-sample comparison, together with checks of measurement and participation. Its findings preserve the relevance of remembered circumstances while restricting the claim that they uniformly predict measured physical health.

The evidence also fits a broader distinction between useful retrospective information and perfect historical measurement. Havari and Mazzonna (2015) find support for the consistency of several childhood recollections in SHARELIFE; that finding does not validate D5 or eliminate health-related recall in CHARLS. Similarly, the predictive value of self-rated health documented by Idler and Benyamini (1997) does not require it to coincide with lung function. These literatures support using both reports and measurements, with attention to what each captures, rather than judging validity from agreement alone.''')
h('7.4 Limitations')
paras('''Exposure measurement is the first limitation. D5 is a broad retrospective judgment, without a dated residential history or pollutant concentration. Its association can reflect household conditions, social surroundings and remembered experience. The historical TSP files add a separate exposure measure, but migration, incomplete interpolation provenance and overlapping calendar-year windows limit their interpretation. No verified coordinates and policy-boundary distance are available for a credible Huai River discontinuity analysis.

Outcome measurement is the second limitation. Peak flow is effort-dependent and measures one aspect of respiratory performance. Quality restrictions and expected variation by diagnosed lung disease support its usefulness, but cannot rule out measurement error or selection among survivors. Blood pressure and height also have measurement and interpretation limits. Self-rated health, diagnoses and ADL remain reports, with different recall and routing structures. An unequal standardized association should not be read as a universal difference between all subjective and objective health measures.

Selection is the third limitation. Survival, interview participation, life-history linkage, observed D5 and covariate completeness precede the measurement-completion question. Estimated completion weights address only the last part of that process under conditional assumptions. Official survey weights do not automatically correct the additional linked-sample requirements, and weighted community-robust regressions do not recover the full sampling design. Complete-case adjustment and fixed-wave comparisons describe more restricted populations than the original models.

Finally, confounding and model choice remain. Current health controls can be downstream consequences of childhood conditions, so attenuation may involve overadjustment or collider bias. Unobserved family and local circumstances can influence both exposure recollection and outcomes. The later analyses were motivated by observed patterns, and many overlapping outcomes and specifications are examined. Reported corrections cover specified small families of tests, not every exploratory comparison. In particular, equivalence margins were selected after seeing the data and cannot establish a prespecified clinically negligible effect.''')
h('7.5 Implications')
p('The practical implication is to report what a health measure supports. Retrospective neighborhood associations with general health remain informative, but measured outcomes and formal common-sample contrasts clarify their scope. Future work would benefit from prospectively recorded environments, verified childhood residence, repeated physical measurements and direct information about appraisal and psychological conditions at recall. A credible policy-boundary design would require those geographical and historical links before estimation. The present evidence supports a narrower and reproducible claim about differing associations, while identifying the information needed to distinguish their causes.')
h('8 Conclusions',1)
paras('''Favorable recalled childhood neighborhoods are associated with better self-rated health, but not with a comparable improvement in measured peak flow. On the same 13,720 respondents with standardized outcomes and identical covariates, the coefficient difference is 0.126 SD (95% CI 0.079 to 0.172). It persists under measurement-quality checks, selection and survey weighting, and appears in 2011 and 2013 outcomes recorded before the neighborhood recollection. This is a formal difference between associations, rather than a causal estimate of childhood environmental effects.

Adding depressive symptoms and measured and reported health reduces the self-rated-health coefficient from 4.89 to 2.50 percentage points on a fixed complete-case sample; measured physical indicators alone change it little. This approximately one-half reduction describes adjustment, not mediation or reporting bias. Lung diagnoses show an intermediate pattern, and the fixed 2013–2015 comparison indicates that changing respondent composition cannot fully explain the temporal difference. Psychological health, unmeasured physical conditions, appraisal and confounding remain possible explanations.

Emotional and offspring outcomes extend the descriptive evidence while retaining their distinct measures and reporting sources. Historical TSP estimates remain imprecise and provide no causal confirmation. Better exposure histories and verified geography are needed before a policy-boundary analysis can address the underlying environmental question. Retaining the distinction between recalled conditions, reported health and measured function clarifies both the evidence supported by these data and the additional information needed to explain it.''')
keep(258);keep(259);keep(260);keep(261)
# One complete, alphabetized reference list.
h('References',1)
refslist=[]
rels=E.fromstring(z.read('word/_rels/document.xml.rels'));rmap={r.get('Id'):r.get('Target') for r in rels}
for i in list(range(263,284))+[388,389,390,428,430,461]:
 s=txt(old[i])
 for link in old[i].xpath('.//w:hyperlink',namespaces=ns):
  val=rmap.get(link.get('{'+ns['r']+'}id'))
  if val and not val.startswith('#') and val not in s:s=s.replace(txt(link),val)
 s=s.replace('https://nilu.com/publication/28370/','https://doi.org/10.1016/j.atmosenv.2015.08.057').replace('https://pubmed.ncbi.nlm.nih.gov/29524919/','https://doi.org/10.1016/j.envint.2018.02.034')
 if 'Biomarker questionnaire' in s:s='China Health and Retirement Longitudinal Study (CHARLS). (2015). Biomarker questionnaire 2015. Peking University. https://charls.pku.edu.cn/en/data/Biomarker2015.pdf'
 refslist.append(s.replace('[CHARLS]','(CHARLS)'))
refslist.append('Idler, E. L., & Benyamini, Y. (1997). Self-rated health and mortality: A review of twenty-seven community studies. Journal of Health and Social Behavior, 38(1), 21–37. https://doi.org/10.2307/2955359')
for s in sorted(set(refslist),key=str.casefold):
 el=p(s,'FinalReference');pr=el.find('w:pPr',ns);sp=E.SubElement(pr,'{'+W+'}spacing');sp.set('{'+W+'}after','70')
# Appendices retain the original derivations and detailed evidence.
h('Appendix A Statistical models and clustered inference',1);ks(285,305)
h('A5 Community resampling and estimated weights')
paras('''The paired bootstrap samples communities with replacement and carries every selected respondent's complete outcome pair into each draw. Repeatedly selected communities receive separate bootstrap cluster labels. The 2015 paired comparison uses 1,999 draws and seed 20261118. Outcome means and sample standard deviations are recomputed in every draw before fitting the two equations and their difference. This permits standardization to vary with the resampled data.

The IPW bootstrap uses 999 draws and seed 2026111802. It resamples the eligible interview denominator, refits the completion logit, calculates inverse probabilities for observed tests, and recomputes weighted scales and coefficients. The capped version uses the draw-specific 99th-percentile threshold. All retained draws converged. The reported percentile intervals incorporate estimated-weight uncertainty; simply treating fitted completion weights as fixed would omit that source of uncertainty. Official released weights, by contrast, are held fixed in the survey-weight sensitivity.

The score-based covariance check and the regression of the within-person standardized difference provide independent algebraic checks of the primary standard error. The fixed-wave comparison is also checked against a difference-score formulation. These numerical agreements establish implementation consistency for the stated models, not the validity of conditional exchangeability or the absence of unobserved selection.''')
h('A6 Binary and ordered response models');ks(308,312);h('A7 Ordered response probabilities');ks(314,317);h('A8 Interpreting nonlinear model coefficients');ks(319,320)
h('Appendix B Measurement inventory and coding',1);h('B1 Emotional-response items');ks(323,327);h('B2 Examination measures');ks(348,352)
h('B3 Diagnosis history and functional limitations');keep(420)
p('The strict disease indicators distinguish confirmed prior doctor diagnoses and explicit new doctor diagnoses from self-awareness or corrected histories with an unresolved source. DA007 alone is insufficient because earlier diagnosis and confirmation routes affect who is asked the follow-up items. Missing or ambiguous status is retained as missing. Broader known-condition sensitivity outcomes admit additional reporting routes and therefore answer a different measurement question. The distinction is consequential for denominators and is preserved in the code.')
p('ADL coding uses the questionnaire’s routing information. A documented mobility skip can indicate no difficulty for questions not asked, while an unexplained blank cannot. The primary count reconstructs documented skips; the direct-answer sensitivity requires all six responses and selects a much smaller subset. Neither coding convention is silently substituted for the other in the primary models.')
h('Appendix C Full measured-health results',1);h('C1 Outcome construction and model sequence');keep(354);keep(356)
# Duplicate table is intentionally the full outcome record alongside staged specifications.
keep(357,'Table C1  Recalled neighborhood associations with measured health');keep(358);keep(359);keep(360)
keep(361,'Table C2  Measured-health associations across survey waves');keep(362);keep(363);keep(364);ks(366,369)
h('C2 Complete primary-model coefficients')
obj=json.loads((results_dir('objective')/'objective_results.json').read_text())['models']
terms=list(obj['2015_pef_primary']['terms']);rows=[]
for key in terms:
 label={'const':'Constant','ce_good':'Favorable recalled neighborhood','age_c':'Age minus 60','age_c2':'Age minus 60, squared','female':'Female'}.get(key,key.replace('province_eng_','Province: ').replace('finance_','Childhood finance: '))
 cells=[]
 for outcome in ['pef','sbp','dbp','height']:
  term=obj['2015_'+outcome+'_primary']['terms'].get(key)
  cells.append(f"{term['b']:.3f}\n({term['se']:.3f})" if term else 'Reference')
 rows.append([label]+cells)
rows += [['Observations']+[f"{obj['2015_'+k+'_primary']['n']:,}" for k in ['pef','sbp','dbp','height']],['R-squared']+[f"{obj['2015_'+k+'_primary']['r2']:.3f}" for k in ['pef','sbp','dbp','height']]]
table('Table C3  Complete coefficients for the 2015 primary measured-health models',['Variable','PEF','Systolic','Diastolic','Height'],rows,'Notes: OLS coefficients in L/min, mmHg, mmHg and cm, respectively; community-clustered standard errors in parentheses. Age is centered at 60. Province and childhood-finance categories use the first observed category as reference (Anhui and finance category 1). No significance selection is applied.',[3300,1515,1515,1515,1515])
h('C3 Blood pressure height and respiratory interpretation')
p('The blood-pressure outcomes use the retained validity rules and repeated-reading summaries rather than a respondent’s diagnostic label. A measured high-pressure indicator and a reported physician diagnosis are not identical outcomes: medication can lower a reading, and an undiagnosed respondent can have elevated pressure. Height reflects body size and developmental history but can change with aging. These differences motivate separate reporting rather than combining the measures into an unsupported health index. The measured-health coefficients and their intervals are retained without selecting outcomes by statistical significance.')
keep(371,txt(old[371]).replace('Appendix G extends','Section 6.3 extends'))
h('Appendix D Measurement selection and weighting sensitivity',1);h('D1 Effort posture body size and smoking');ks(401,406)
h('D2 Completion and inverse probability weighting');ks(433,441)
h('D3 Official survey weights');ks(443,450)
h('D4 Exploratory equivalence sensitivity');ks(457,460)
h('Appendix E Adjustment and diagnosis sensitivity',1);h('E1 Common-sample adjustment');p('Section 6.5 presents the common-sample estimates. The checks below assess sensitivity to disease-count and ADL coding.');keep(408);ks(412,413);keep(421)
h('E2 Reported diagnosed conditions');keep(415,'Table E1  Strict and broader reported condition definitions');keep(416);keep(417);ks(418,419)
p('The interpretation of these adjustments is developed in Section 7.2; these selected-subset checks do not identify mediation or reporting bias.')
h('Appendix F Supplementary descriptive statistics',1);keep(141);keep(142);keep(143)
p('These archived descriptive summaries concern the original combined reported-outcome and historical-pollution samples. They are retained to make those analyses traceable and should not be substituted for the 2015 paired-sample description in Table 2. In particular, the numerical mean of the original education category is an archive summary, not a cardinal measure of educational attainment; the main descriptive table instead reports category proportions.')
h('Appendix G Feasibility of a Huai River design',1);h('G1 Exposure timing and the main-respondent cohort');ks(374,376);h('G2 Geography and linkage audit');ks(378,381);h('G3 What would be required for estimation');ks(383,386)
h('Appendix H Directions for further research',1);h('H1 Longitudinal health and environmental histories');keep(330);h('H2 Independent exposure and outcome measurement');keep(332,'Measured outcomes, graded CES-D-10 scores and test participation are examined in the present analysis. Further work needs repeated physical tests and information about mood at recall to distinguish measurement mechanisms from persistent health differences. These questions remain distinct from identifying a causal pollution effect.');keep(333);h('H3 Identification and timing');ks(335,337);h('H4 Research sequence');ks(339,343);keep(344,txt(old[344]).replace('Appendix F','Appendix G'))
h('Appendix I Analytical development and decision record',1)
p('The empirical sequence matters because later checks were motivated by earlier findings. The original project examined reported outcomes and historical TSP. Subsequent stages corrected coding and separated reporting units before expanding measured-health comparisons. The sequence below records the scope of each stage. It does not present the later specifications as preregistered or treat the number of checks as independent confirmations.')
table('Table I1  Sequence of analytical decisions',['Stage','Question and retained decision'],[['Original project','Reported emotional and general health; separate historical TSP models. Original scripts and results retained.'],['Measurement and sample audit','Harmonize health labels across waves; main respondents and parent-reported offspring analyzed separately; TSP clustered by city.'],['Measured-health extension','Peak flow as primary examination outcome; blood pressure and height as complements; geography audited before proposing a boundary design.'],['Paired comparison and explanatory checks','Common-sample standardized comparison; effort, posture, height and smoking sensitivity; CES-D and health adjustment.'],['Selection and temporal sensitivity','Completion models, estimated and official weights, earlier-wave pairs and exploratory equivalence margins.'],['Fixed-wave and presentation revision','Fix 2013–2015 respondents; retain reproduced 13,935/13,720 sample counts; reorganize around the formal outcome contrast without changing fitted results.']],
'Notes: The later analyses are exploratory. No sibling fixed-effects estimate or QGIS interpolation reconstruction is included. The present revision preserves the fitted numerical results and adds descriptive summaries and explicit statistical notation.',[2000,7360])
h('Appendix J Reproduction and numerical checks',1)
paras('''The accompanying project keeps all available analysis code in one Code directory. Exact duplicate files are included once; distinct versions remain because they contain different cleaning or analysis operations. The collection includes the available Stata cleaning, merging, regression and graph files from Qiu.zip and the local project, together with the Python analysis, statistical-figure and Word-construction files. The total count and source hashes are recorded in code_sources.json and manifest.json. Data are kept outside Code. Run_all.command invokes Code/run_all.py, which creates a new output directory and does not overwrite source files.

The default entry point recomputes the main reported-health and historical TSP models, the measured-health models, the paired and quality comparisons, the selection and survey-weight sensitivities, and the fixed-wave comparison. It then regenerates the statistical figures and Word document. Numerical structures are compared with the retained full-precision results before fixed-version manuscript text is assembled. New descriptive tables are calculated from the same paired sample. Statistical figures are generated from the fitted results; the original biological illustration and research diagram are retained as source illustrations rather than described as new statistical plots.

The computational boundary is explicit. The statistical reanalysis reads the archived survey modules and inherited prepared files in Qiu.zip. The original cleaning scripts are supplied, but the main launcher does not independently execute every historical Stata version or rebuild inherited family links and spatial interpolation from their earliest inputs. No QGIS project, IDW script or spatial-operation record was found or supplied. Consequently, the package reproduces the reported statistical reanalysis conditional on those archived inputs, not an independently reconstructed monitor-to-person exposure pipeline. Replacing missing spatial code with a new guessed interpolation would create a different exposure and is not part of this reproduction.

The verified numerical environment uses Python 3.13.9, NumPy 2.3.5, pandas 2.3.3, SciPy 1.16.3, statsmodels 0.14.5 and Matplotlib 3.10.6. Additional document and workbook dependencies are pinned in requirements.txt. Original Stata files preserve their historical commands; the original execution version cannot be established from the available log. Pandoc is used only by the optional equation-source builder; the supplied editable equation XML permits Word reconstruction without rerunning that conversion. Random seeds and bootstrap draw counts are specified in Appendix A and in the analysis code.

The verified construction produces 13,935 respondents in the primary 2015 peak-flow model and 13,720 in the paired model. These are the sample counts used throughout the present report. Checks also retain 11,719 common adjustment cases and 8,719 complete fixed-wave cases. Cross-equation and difference-score calculations independently verify the central standard errors. These checks concern the implemented models and data rules; they do not replace substantive assumptions about recall, measurement or causal identification.''')
table('Table J1  Analysis and output map',['Outputs','Principal code'],[['Original reported-health and TSP tables; Figures 2–6 and 9–12','analysis.py; full_analysis.py; full_iv.py; ivprobit.py; figures.py'],['Measured-health tables; Figure C1','objective_analysis.py; plot_objective.py'],['Paired and adjustment results; Figures 7 and 8','discordance_analysis.py; plot_discordance.py'],['Selection, survey weights, earlier waves and equivalence','robustness_analysis.py; validate_analysis.py'],['Fixed 2013–2015 comparison','fixed_sample_analysis.py'],['Paired-sample descriptive statistics','descriptive_tables.py'],['Geographical feasibility inventory','geography_audit.py'],['Word assembly, equations and checks','objective_word.py; discordance_word.py; robustness_word.py; fixed_word.py; revise_manuscript.py; verify_manuscript.py; build_equations.py'],['Original upstream operations','All distinct supplied .do files in Code; source paths and hashes in code_sources.json']],
'Notes: run_all.py is the total entry point for the verified reanalysis. Historical Stata scripts are supplied in full and remain distinct from the executed reanalysis path. Figure 1 and Figure H1 are retained original illustrations; their underlying editable drawing sources were not supplied.',[3600,5760])
# Remove repeated explanations after their first occurrence. Tables and numerical
# sensitivity records stay in their designated appendices.
seen=set();compact=[];compact_ledger=[]
for el,record in zip(out,ledger):
 st=el.find('w:pPr/w:pStyle',ns);style=st.get('{'+W+'}val') if st is not None else ''
 key=record.get('source_element')
 if key is not None and style=='FinalBody':
  if key in seen:continue
  seen.add(key)
 compact.append(el);compact_ledger.append(record)
out=compact;ledger=compact_ledger
# Shorten explanations that duplicate the integrated Discussion or explicit formulas.
shorten={
 'For the paired comparisons, fair-or-better health': 'The paired analysis estimates fair-or-better health by a linear probability model before standardization. The retained Probit and ordered models answer separate questions; their index coefficients are not standardized linear coefficients.',
 'Peak flow is the primary measured outcome. The construction': 'Peak flow is the primary measured outcome. Its models use age, age squared, sex, childhood finances and province indicators. Height and more flexible age–sex–height relationships enter sensitivity checks because body size predicts respiratory performance and may reflect earlier conditions.',
 'The published lookup covers ages': 'The lookup covers ages 40–85, with no extrapolation and positive predicted values required. Because the reference uses 2011 CHARLS, it is a normalization check rather than independent validation. Effort, posture and smoking come from the contemporaneous modules; Appendix B details measurement construction.',
 'All ten items must be observed, yielding': 'All ten CES-D items are required, giving a score of 0–30, with higher values indicating more symptoms (Chen and Mui, 2014). The 2015 score follows the recall interview. The full health block adds 14 reported conditions and six ADL limitations to peak flow, blood pressure and height; reports remain distinct from measurements.',
 'The main reported-health models and the paired': 'The reported-health models retain education and survey-wave indicators; the paired models use province and childhood finances. These are different covariate sets for different descriptive questions. Education appears as categorical proportions in Table 2 rather than as a cardinal average.',
 'The raw peak-flow difference is negative': 'The unadjusted peak-flow difference is negative, while the self-rated-health difference is positive. The favorable group is older and more often female. These composition differences motivate identical adjustment in the paired equations. Supplementary missing values do not redefine the primary sample.',
 'The self-rated-health equation is linear': 'The self-rated-health equation is linear before standardization. Its coefficient is an adjusted mean difference. The central null compares the standardized neighborhood coefficients:',
 'Regressing the within-person difference': 'Regressing ZS − ZP on the same design matrix estimates the coefficient difference. Community clustering retains dependence across outcomes and respondents. A cross-equation score calculation verifies its standard error. The primary interval uses t(447), for 448 communities.',
 'A community pairs bootstrap resamples': 'A community pairs bootstrap with 1,999 draws recomputes both outcome scales and coefficients. Its percentile interval is:',
 'Earlier-wave comparisons use their own': 'Earlier waves use common within-wave samples and contemporaneous controls. Their point estimates are not a formal test of change over time; respondents overlap.',
 'Measurement completion is first treated': 'Completion models begin with 2015 health interviews, including people without biomarker records, and retain valid D5, age and primary controls. Linear probability models test whether D5 predicts completion. Among interviewees with self-rated health, a logit estimates completion probabilities for IPW:',
 'The cap is the 99th percentile': 'The cap is the 99th percentile of uncapped observed-test weights. The IPW bootstrap refits selection, scales and outcome models in 999 community draws. Generalization requires conditional exchangeability of missing and observed peak flow and positive completion probabilities.',
 'Official biomarker and individual weights': 'Official biomarker and individual weights are examined separately on common support, without multiplication by estimated completion weights. Weighted standardization uses:',
 'This variance convention reduces': 'This convention reproduces the ordinary sample variance under equal weights. Both equations use the same weights, controls and observations. Original-scale checks separate weighting from rescaling; inference remains community-clustered.',
 'The adjustment analysis fixes': 'All adjustment models use 11,719 complete cases. Baseline, CES-D, measured-health, full-health and combined specifications therefore hold respondents fixed. Absolute and proportional reductions are:',
 'The reduction is estimated jointly': 'Joint estimation retains coefficient covariance. The reduction is descriptive: health controls may be consequences of childhood conditions or share unobserved causes, precluding a causal mediated proportion.',
 'The exploratory comparison of 2013': 'The exploratory comparison fixes 8,719 complete respondents across 2013 and 2015. The stacked model permits every coefficient to vary by wave:',
 'Community clustering accounts for repeated': 'Community clustering accounts for repeated records. Raw differences are reported in percentage points; standardizing both years by the 2013 SD supplies a common-scale check. Fixing people does not separate aging, period effects and appraisal.',
 'The paired comparison is the central': 'The paired contrast is central. Holm correction covers the two strict diagnosis outcomes and the two earlier-wave tests; other intervals are pointwise. Later quality, selection, adjustment, equivalence and fixed-wave analyses were not preregistered (Appendix I).',
 'The diagnosis comparison also helps': 'A descriptive scale calculation is useful: about 70 L/min lower peak flow among those reporting lung disease, multiplied by its 1.25-percentage-point lower prevalence, implies approximately 0.9 L/min higher average flow. That lies within the observed interval. It is not a causal decomposition, but shows why the diagnosis and peak-flow results can coexist.',
 'The larger 2015 association on': 'The fixed-sample increase is consistent with amplification in the illustrative model, but aging, period conditions and appraisal can also explain it. Both survey years flank the 2014 recall interview; neither is demonstrably closer by calendar year alone. Fixing composition does not identify the remaining mechanism.',
 'The TSP analysis remains separate': 'The mostly offspring TSP sample cannot validate the older respondents’ paired comparison. Weak birth-year instruments and uncertain exposure assignment require better identification information before a causal interpretation.',
 'These records do not measure': 'Offspring records contain the parent’s childhood assessment and parent-reported offspring health. They are not pooled into the main paired comparison. No sibling fixed-effects estimate is claimed.',
 'The community pairs bootstrap samples': 'Community resampling carries complete outcome pairs into each draw, with distinct labels for repeatedly selected communities. The paired bootstrap uses 1,999 draws and seed 20261118 and re-estimates both scales and coefficients.',
 'The paired bootstrap samples': 'Community resampling carries complete outcome pairs into each draw, with distinct labels for repeatedly selected communities. The paired bootstrap uses 1,999 draws and seed 20261118 and re-estimates both scales and coefficients.',
 'The IPW bootstrap uses': 'The IPW bootstrap uses 999 draws and seed 2026111802, refitting completion, weights, scales and outcome models. The cap is draw-specific. All retained draws converged. Official weights remain fixed in the survey-weight sensitivity.',
 'The score-based covariance check': 'Cross-equation scores verify the paired standard error; a difference-score model verifies the fixed-wave result. Numerical agreement establishes implementation consistency, not substantive identification.',
 'The strict disease indicators distinguish': 'Strict disease indicators retain explicit or confirmed doctor diagnoses. Self-awareness and ambiguous corrected histories enter only broader definitions. DA007 alone misses the confirmation and prior-history routes. Unresolved status remains missing.',
 'ADL coding uses the questionnaire': 'Documented routing skips are reconstructed for ADL, while unexplained blanks remain missing. The direct-answer sensitivity requires all six answers and therefore selects a different subset.',
 'The blood-pressure outcomes use': 'Measured pressure and a reported diagnosis are different outcomes: medication can lower readings and undiagnosed disease can remain. Height also reflects aging. These measures are reported separately, without selecting by significance or combining them into an unsupported index.',
 'These archived descriptive summaries concern': 'The archived summaries concern the original reported-health and TSP samples, not the paired sample. Education-category averages are retained for traceability; Table 2 instead reports category proportions.',
 'The empirical sequence matters': 'Later analyses were motivated by earlier results. Table I1 records their development without presenting exploratory choices as preregistered hypotheses.',
 'The accompanying project keeps': 'All available distinct code is in Code, including Stata files from Qiu.zip and local project folders and the Python analysis, plotting and Word scripts. Exact duplicates are included once. Data remain separate. Run_all.command invokes Code/run_all.py and creates a new output directory; code_sources.json and manifest.json record provenance and hashes.',
 'The default entry point recomputes': 'The entry point refits the main, TSP and extension models, checks full-precision results, then regenerates statistical figures and Word. Descriptive tables use the paired sample. The biological illustration and research diagram are retained original illustrations, not new statistical plots.',
 'The computational boundary is explicit': 'The reanalysis uses archived survey modules and inherited prepared files. Original Stata cleaning scripts are supplied, but the launcher does not execute every historical version or independently rebuild family links. No QGIS project, IDW script or operation record is available. Reproduction is conditional on archived exposure inputs, not an independently reconstructed monitor-to-person pipeline.',
 'The verified numerical environment uses': 'The verified environment is Python 3.13.9, NumPy 2.3.5, pandas 2.3.3, SciPy 1.16.3, statsmodels 0.14.5 and Matplotlib 3.10.6; other dependencies are pinned. The original Stata execution version is unverified. Optional equation-source rebuilding requires Pandoc; supplied equation XML supports Word reconstruction without it.',
 'The verified construction produces': 'The verified counts are 13,935 for primary peak flow, 13,720 for the pair, 11,719 for common adjustment and 8,719 for fixed waves. Cross-equation and difference-score checks verify the central standard errors.'
}
for el in out:
 st=el.find('w:pPr/w:pStyle',ns)
 if st is not None and st.get('{'+W+'}val')=='FinalBody':
  for prefix,replacement in shorten.items():
   if txt(el).startswith(prefix):textset(el,replacement);break
# Further remove repeated caveats now developed in Discussion, retaining numerical evidence.
remove_ids={149,153,157,158,159,164,165,170,178,179,189,197,234,238,245,247,399,423,424,425,343}
remove_els={id(el) for el,record in zip(out,ledger) if record.get('source_element') in remove_ids}
out=[el for el in out if id(el) not in remove_els]

# Editorial consistency for the common-sample analysis and reporting units.
for el in list(out):
 if not el.tag.endswith('}p'):continue
 before=txt(el);after=before
 if before.startswith('Appendix G audits the proposed Huai River design.'):
  out.remove(el);continue
 after=after.replace('matched-sample','common-sample').replace('matched sample','common sample')
 for value in ['4.63','4.69','2.39','3.19','−0.64','2.52','4.78','3.15','0.035','2.49','1.81']:
  after=after.replace(value+' points',value+' percentage points')
 for value in ['4.66','5.10','4.89']:
  after=after.replace(value+'-point',value+'-percentage-point')
 if before.startswith(('Figure 4  ','Figure 5  ','Figure 6  ','Table 10  ')):
  after=after.replace('Reported health','Self-rated health')
 if before.startswith('CHARLS data and questionnaires are available'):
  after='CHARLS data and questionnaires are available through the project under its access conditions. Appendix J describes the reproduction files and their scope. Code/run_all.py is the total entry point for rebuilding the statistical analyses, figures and Word document from the archived inputs. TSP interpolation and upstream family links are inherited from those inputs and are not independently reconstructed.'
 if before.startswith('The central comparison uses the same 13,720'):
  after='Among the same 13,720 respondents, the standardized association with self-rated health exceeds that with peak flow by 0.126 SD (95% CI 0.079 to 0.172). The sample spans 448 communities. Fair-or-better self-rated health and peak expiratory flow are separately centered and divided by their sample standard deviations, 0.4383 and 125.20 L/min. Higher values indicate better health in both outcomes. Linear models use identical age, age-squared, sex, province and childhood-finance covariates; the binary outcome is estimated as a linear probability model.'
 if before.startswith('This formulation draws on the dynamic perspective'):
  after+=' Section 7.2 returns to this model when considering change over time as a possible interpretation of the fixed-sample comparison.'
 if after!=before:textset(el,after)
# TSP outcomes are predominantly parent reports, with eight main respondents retained.
for i,el in enumerate(out):
 if txt(el).startswith(('Table 15  ','Table 16  ')):
  table_el=out[i+1]
  for pp in table_el.findall('.//w:p',ns):
   if txt(pp).strip()=='Reported health':textset(pp,'Reported health (predominantly offspring)')
  note=out[i+2]
  textset(note,txt(note)+' Health is parent-reported for 6,531 offspring records and self-rated for eight main-respondent records; these reporting units are retained together in the historical specification.')

# Describe the study and its reproducibility in the author's voice.
paragraph_updates = {
 'CHARLS data and questionnaires are available': 'CHARLS data and questionnaires are available through the CHARLS project under its access conditions. Appendix J describes the analysis code and reproducibility checks. Code/run_all.py estimates the models and produces the statistical figures. The analyses use prepared household links and TSP exposure files; household linkage and spatial interpolation are not re-estimated.',
 'All available distinct code is in Code': 'Code contains the Stata cleaning and estimation scripts and Python analysis and plotting scripts. Data are stored separately. Code/run_all.py is the main entry point, also accessible through Run_all.command; code_sources.json and manifest.json record file origins and checksums.',
 'The entry point refits the main, TSP and extension models': 'The main entry point estimates the reported-health, TSP and measured-health models, checks full-precision results and generates statistical figures. Paired-sample descriptive statistics use the same respondents as the outcome comparison.',
 'The reanalysis uses archived survey modules': 'The analyses use CHARLS survey modules and prepared household-linkage and TSP exposure files. Household linkage is not repeated. The QGIS project, interpolation script and operation record are unavailable, preventing independent reconstruction of the spatial interpolation.',
 'The verified environment is Python': 'The analyses were run with Python 3.13.9, NumPy 2.3.5, pandas 2.3.3, SciPy 1.16.3, statsmodels 0.14.5 and Matplotlib 3.10.6; other dependency versions are specified in requirements.txt. The Stata version used for the earlier data preparation is unverified.',
 'Notes: run_all.py is the total entry point': 'Notes: Code/run_all.py runs the analyses listed above from the prepared inputs. The Stata scripts document earlier data preparation and estimation; the main entry point does not execute every historical specification.',
 'Notes: The later analyses are exploratory.': 'Notes: The later analyses are exploratory. No sibling fixed-effects estimate or independent reconstruction of the TSP interpolation is included.',
 'The next empirical gate is a validated geographic crosswalk': 'A Huai River analysis would require a validated geographic crosswalk and policy boundary linked to dated residence histories. It would also require sufficient locations on each side within prespecified bandwidths, local linear estimation, clustering at the assignment level and sensitivity checks for boundary and interpolation uncertainty. Design credibility and precision would determine feasibility. Separating early-life exposure would additionally require a defensible timing contrast.',
}
phrase_updates = {
 'The analysis uses the archived cubic regression input and the quartic descriptive series as specified in the original project, without claiming to reconstruct the spatial interpolation.': 'The analysis uses the cubic file for regressions and the quartic file for descriptive series. Spatial interpolation is not re-estimated.',
 'These findings concern the supplied archive, not all data potentially obtainable from CHARLS.': 'These findings concern the data used in this study; additional geographical information may be obtainable from CHARLS.',
 'The revised main health sample contains': 'The main health sample contains',
 'Those results are retained as supplementary evidence rather than used to validate the recalled neighborhood item.': 'Those results provide supplementary evidence but do not validate the recalled neighborhood item.',
 'CHARLS general-health reports provide a broad outcome rather than measurements of these individual mechanisms.': 'CHARLS general-health reports capture a broad outcome and do not measure these individual mechanisms.',
 'Their purpose is to assess how much of the contrast can be described by observed variables, rather than to designate one outcome as the correct measure of health.': 'The checks assess how much of the contrast can be described by observed variables.',
 'This produces a selected combination of survey records rather than repeated within-person health trajectories.': 'The resulting sample combines selected survey records and does not track within-person health trajectories.',
 'The item measures a recalled residential assessment rather than pollutant concentration or a dated exposure history.': 'The item records a retrospective residential assessment; it provides neither pollutant concentrations nor a dated exposure history.',
 'Because the reference uses 2011 CHARLS, it is a normalization check rather than independent validation.': 'Because the reference uses 2011 CHARLS, this check assesses normalization and provides no independent validation.',
 'Disease history combines baseline flags, confirmation, new diagnoses and self-awareness paths rather than reading DA007 alone.': 'Disease history combines baseline flags, confirmation, new diagnoses and self-awareness paths, extending beyond DA007 alone.',
 'CES-D-10 follows the standard symptom-frequency scoring rather than the extreme-response count used in the emotional extension.': 'CES-D-10 uses standard symptom-frequency scoring; the emotional extension uses a separate extreme-response count.',
 'Education appears as categorical proportions in Table 2 rather than as a cardinal average.': 'Table 2 reports education as categorical proportions.',
 'These four interpretations can coexist rather than requiring a single explanation for every result.': 'These four interpretations can coexist.',
}
for el in out:
 if not el.tag.endswith('}p'): continue
 before=txt(el);after=before
 for prefix,replacement in paragraph_updates.items():
  if before.startswith(prefix): after=replacement;break
 for old_text,new_text in phrase_updates.items(): after=after.replace(old_text,new_text)
 if after!=before: textset(el,after)
# Record analytical choices as decisions made, not instructions to an editor.
for i,el in enumerate(out):
 if txt(el).startswith('Table I1  '):
  table_el=out[i+1]
  rows=table_el.findall('w:tr',ns)
  updates=[
   ('Initial analyses','Reported emotional and general health were examined alongside separate historical TSP models.'),
   ('Measurement and sample audit','Health labels were harmonized across waves. Main respondents and parent-reported offspring were analyzed separately; TSP standard errors were clustered by city.'),
   ('Measured-health extension','Peak flow was the primary examination outcome, with blood pressure and height as complements. Geographical information was assessed for a boundary design.'),
   ('Paired comparison and explanatory checks','Standardized outcomes were compared on a common sample. Checks examined effort, posture, height, smoking, CES-D and other health measures.'),
   ('Selection and temporal sensitivity','Completion models, estimated and official weights, earlier-wave pairs and exploratory equivalence margins were examined.'),
   ('Fixed-wave comparison','The 2013–2015 comparison used the same respondents in both waves. The primary peak-flow and paired samples contained 13,935 and 13,720 respondents, respectively.'),
  ]
  for row,values in zip(rows[1:],updates):
   for cell,value in zip(row.findall('w:tc',ns),values):textset(cell,value)
 if txt(el).startswith('Table J1 '):
  table_el=out[i+1]
  for row in list(table_el.findall('w:tr',ns)):
   cells=row.findall('w:tc',ns)
   if cells and txt(cells[0]).startswith('Word assembly'):table_el.remove(row)
   elif cells and txt(cells[0]).startswith('Original upstream operations'):
    textset(cells[0],'Earlier data preparation and estimation')
    textset(cells[1],'Stata .do files in Code; file origins and checksums in code_sources.json')


# Integrate the historical pollution evidence into the discussion.
for el in out:
 if not el.tag.endswith('}p'):continue
 before=txt(el);after=before
 after=after.replace('Historical total suspended particulate (TSP) exposure estimates linked to 6,539 younger records likewise show no detectable association with reported health, predominantly parent-reported offspring health, in Probit or instrumental-variable Probit models; imprecision and weak birth-year instruments limit interpretation, and this sample is not directly comparable with the main respondents.', 'Historical total suspended particulate (TSP) exposure estimates linked to 6,539 younger records likewise show no detectable association with reported health, mostly parent-reported offspring health, in Probit or instrumental-variable Probit models. These estimates are imprecise, the birth-year instruments are weak, and the sample is not directly comparable with the main respondents.')
 after=after.replace('The archived summaries concern the original reported-health and TSP samples, not the paired sample. Education-category averages are retained for traceability; Table 2 instead reports category proportions.', 'These summaries describe the self-rated-health and TSP samples, not the paired sample. Education appears here as category averages; Table 2 reports category shares.')
 after=after.replace('these reporting units are retained together in the historical specification', 'the TSP models pool these two reporting groups')
 after=after.replace('the main entry point does not execute every historical specification', 'run_all.py does not re-run every earlier Stata specification')
 if after!=before:textset(el,after)
insertions=[
 ('7.2 Competing interpretations', 'The historical pollution analysis examines the exposure side of the question. TSP exposure estimates, based on historical concentrations rather than recalled neighborhood ratings, show no detectable association with reported health among 6,539 younger records, mostly parent-reported offspring health. Thus, neither the peak-flow comparison nor the separate TSP analysis provides a corresponding positive association. The TSP results, however, do not constitute a common-sample test of replacing recalled exposure with measured pollution.'),
 ('Outcome measurement is the second limitation.', 'The exposure–outcome comparison is incomplete. Respondents in the 2015 peak-flow sample were born before 1981, the first year of the historical TSP series. Birth-year TSP is therefore unavailable for this sample, so the combination of historical birth-year exposure and measured lung function cannot be estimated with these data. The TSP sample also differs in age, reporter and geographical assignment; its null estimate cannot be attributed to measurement alone.'),
 ('8 Conclusions', 'For historical pollution research, a central constraint is exposure assignment: interpolated city-level concentrations linked through survey residence cannot isolate early-life exposure without dated residential histories.'),
]
for prefix,content in insertions:
 index=next(i for i,e in enumerate(out) if txt(e).startswith(prefix))
 paragraph=p(content);out.pop();out.insert(index,paragraph)


# Final content adjustments, numbering, metadata and pagination conventions.
for el in out:
 for t in el.xpath('.//w:t',namespaces=ns):
  s=t.text or ''
  s=s.replace('Cumulative TSP exposure','Weighted TSP index').replace('Temperature total','Weighted temperature')
  s=s.replace('historical TSP estimates remain a separate, frozen analysis','historical TSP estimates remain a separate analysis')
  t.text=s
 # Do not allow a caption to be stranded above its table or figure note.
 if el.tag.endswith('}p'):
  ps=el.find('w:pPr/w:pStyle',ns);style=ps.get('{'+W+'}val') if ps is not None else ''
  if style in ['FinalCaption','FinalFigure']:
   pr=el.find('w:pPr',ns)
   if pr.find('w:keepNext',ns) is None:E.SubElement(pr,'{'+W+'}keepNext')
for el in out:
 if el.tag.endswith('}tbl'):
  tr=el.find('w:tr',ns);pr=tr.find('w:trPr',ns)
  if pr is None:pr=E.SubElement(tr,'{'+W+'}trPr')
  if pr.find('w:tblHeader',ns) is None:E.SubElement(pr,'{'+W+'}tblHeader')
# Correct the original emotional Probit column label.
for el in out:
 if el.tag.endswith('}tbl') and '0.137' in txt(el) and '7.45' in txt(el):
  rows=el.findall('w:tr',ns)
  for row in rows[:4]:
   cells=row.findall('w:tc',ns)
   if any('Emotional response' in txt(c) for c in cells):
    c=cells[-1];pr=c.find('w:tcPr',ns);span=pr.find('w:gridSpan',ns)
    if span is not None:pr.remove(span)
    widths=[x.get('{'+W+'}w') for x in el.find('w:tblGrid',ns)]
    pr.find('w:tcW',ns).set('{'+W+'}w',widths[-2]);textset(c,'Emotional count')
    c2=deepcopy(c);c2.find('w:tcPr/w:tcW',ns).set('{'+W+'}w',widths[-1]);textset(c2,'Count ≥ 6');row.append(c2)
# Keep regression header blocks and coefficient/SE pairs together across pages.
for el in out:
 if not el.tag.endswith('}tbl'):continue
 rows=el.findall('w:tr',ns)
 regression=bool(rows and re.search(r'\(1\)',txt(rows[0])))
 if regression:
  for j,row in enumerate(rows):
   keep_next=j<4
   if j+1<len(rows):
    cells=rows[j+1].findall('w:tc',ns)
    keep_next=keep_next or (cells and not txt(cells[0]).strip() and any(re.match(r'^\([-−]?\d',txt(c)) for c in cells[1:]))
   if j<3:
    rp=row.find('w:trPr',ns)
    if rp is None:rp=E.SubElement(row,'{'+W+'}trPr')
    if rp.find('w:tblHeader',ns) is None:E.SubElement(rp,'{'+W+'}tblHeader')
   if keep_next:
    for pp in row.findall('.//w:p',ns):
     pr=pp.find('w:pPr',ns)
     if pr is None:pr=E.SubElement(pp,'{'+W+'}pPr')
     if pr.find('w:keepNext',ns) is None:E.SubElement(pr,'{'+W+'}keepNext')
# Keep notes with the final row, rather than leaving a note alone on a new page.
for j,el in enumerate(out[:-1]):
 if el.tag.endswith('}tbl'):
  st=out[j+1].find('w:pPr/w:pStyle',ns)
  if st is not None and st.get('{'+W+'}val')=='FinalNote':
   for pp in el.findall('w:tr',ns)[-1].findall('.//w:p',ns):
    pr=pp.find('w:pPr',ns)
    if pr is None:pr=E.SubElement(pp,'{'+W+'}pPr')
    if pr.find('w:keepNext',ns) is None:E.SubElement(pr,'{'+W+'}keepNext')
# Preserve the manually adjusted Figure 2 and Figure 3 layout.
for i,el in list(enumerate(out)):
 if txt(el).startswith(('Figure 2  ', 'Figure 3  ')):
  number=2 if txt(el).startswith('Figure 2  ') else 3
  figure=out[i-1]
  width,height={2:(4931764,3589520),3:(4928832,3587385)}[number]
  for extent in figure.xpath('.//wp:extent | .//a:xfrm/a:ext',namespaces={**ns,'a':'http://schemas.openxmlformats.org/drawingml/2006/main'}):
   extent.set('cx',str(width));extent.set('cy',str(height))
  for paragraph in (figure,el):
   prop=paragraph.find('w:pPr/w:keepNext',ns)
   if prop is not None:prop.getparent().remove(prop)
  if number==3:
   gap=E.Element('{'+W+'}p');pr=E.SubElement(gap,'{'+W+'}pPr')
   E.SubElement(pr,'{'+W+'}pStyle').set('{'+W+'}val','FinalNote')
   E.SubElement(pr,'{'+W+'}keepLines')
   out.insert(i-1,gap)

# Replace residual obsolete appendix references in context, without chaining maps.
for el in out:
 if el.tag.endswith('}p') and not el.xpath('.//m:oMath',namespaces=ns):
  for t in el.xpath('.//w:t',namespaces=ns):
   s=t.text or ''
   s=s.replace('in H1,','in Section 5.4,').replace('Appendix E1','Appendix B2')
   t.text=s
# Native equations retain every original OMML payload, only numbering changes.
for el in out:
 if el.xpath('.//wp:docPr',namespaces=ns):
  pos=out.index(el);caption=txt(out[pos+1]) if pos+1<len(out) else ''
  for dp in el.xpath('.//wp:docPr',namespaces=ns):dp.set('name',caption.split('  ')[0]);dp.set('title',caption);dp.set('descr',caption)
# Rebuild the heading inventory from all retained and new headings.
heads=[]
for el in out:
 st=el.find('w:pPr/w:pStyle',ns)
 if st is not None and st.get('{'+W+'}val') in ['FinalHeading1','FinalHeading2']:
  heads.append((int(st.get('{'+W+'}val')[-1]),txt(el),el))
# Force a new page before the reference list and each appendix as in the source.
for level,title,el in heads:
 if title=='References' or title.startswith('Appendix '):
  pr=el.find('w:pPr',ns);E.SubElement(pr,'{'+W+'}pageBreakBefore')
# Add bookmarks for TOC page references.
for i,(level,title,el) in enumerate(heads,1000):
 start=E.Element('{'+W+'}bookmarkStart');start.set('{'+W+'}id',str(i));start.set('{'+W+'}name',f'SURA_{i}');el.insert(1,start)
 end=E.SubElement(el,'{'+W+'}bookmarkEnd');end.set('{'+W+'}id',str(i))
for child in list(body):body.remove(child)
for el in out:body.append(el)
body.append(deepcopy(old[-1]))
# Cached static TOC with page fields; Word/LibreOffice can paginate/update these.
idx=body.index(toc);body.remove(toc)
pagination=json.loads((INPUTS/'pagination.json').read_text())['headings']
assert set(pagination)=={title for _,title,_ in heads},'Heading outline differs from verified pagination; regenerate the layout cache.'
for j,(level,title,el) in enumerate(heads):
 if level>2:continue
 line=E.Element('{'+W+'}p');pr=E.SubElement(line,'{'+W+'}pPr');E.SubElement(pr,'{'+W+'}pStyle').set('{'+W+'}val','FinalTOCLine')
 if level==2:E.SubElement(pr,'{'+W+'}ind').set('{'+W+'}left','240')
 tabs=E.SubElement(pr,'{'+W+'}tabs');tab=E.SubElement(tabs,'{'+W+'}tab');tab.set('{'+W+'}val','right');tab.set('{'+W+'}leader','dot');tab.set('{'+W+'}pos','8419')
 r=E.SubElement(line,'{'+W+'}r');E.SubElement(r,'{'+W+'}t').text=title
 r=E.SubElement(line,'{'+W+'}r');E.SubElement(r,'{'+W+'}tab')
 f=E.SubElement(line,'{'+W+'}fldSimple');f.set('{'+W+'}instr',f' PAGEREF SURA_{1000+j} \\h ');r=E.SubElement(f,'{'+W+'}r');E.SubElement(r,'{'+W+'}t').text=str(pagination[title])
 body.insert(idx,line);idx+=1
# Ensure every final heading was included, including retained subheadings.
# (The TOC intentionally includes the new main outline, not every appendix sub-subtopic.)
settings=E.fromstring(z.read('word/settings.xml'));up=settings.find('w:updateFields',ns)
if up is None:up=E.SubElement(settings,'{'+W+'}updateFields')
up.set('{'+W+'}val','false')
core=E.fromstring(z.read('docProps/core.xml'))
core.find('{http://purl.org/dc/elements/1.1/}title').text='Early-Life Environment and Adult Health in China: Recalled Childhood Neighborhood Conditions, Historical Air Pollution, and Self-Rated versus Measured Health'
core.find('{http://purl.org/dc/elements/1.1/}subject').text=core.find('{http://purl.org/dc/elements/1.1/}title').text
custom=E.fromstring(z.read('docProps/custom.xml'))
for prop in list(custom):custom.remove(prop)
root=Path(os.environ['EARLY_LIFE_OUTPUT_DIR']);dest=root/'SURA_Revised_2026-11-18.docx'
with ZipFile(dest,'w',ZIP_DEFLATED) as zz:
 for item in z.infolist():
  data=E.tostring(doc,xml_declaration=True,encoding='UTF-8',standalone=True) if item.filename=='word/document.xml' else E.tostring(settings,xml_declaration=True,encoding='UTF-8',standalone=True) if item.filename=='word/settings.xml' else E.tostring(core,xml_declaration=True,encoding='UTF-8',standalone=True) if item.filename=='docProps/core.xml' else E.tostring(custom,xml_declaration=True,encoding='UTF-8',standalone=True) if item.filename=='docProps/custom.xml' else z.read(item.filename)
  zz.writestr(item,data)
report={'source':str(source),'output':str(dest),'equation_old_to_new':eqmap,'equations':eqn,'word_count':len(re.findall(r"\b[\w’'-]+\b",' '.join(txt(x) for x in out))),'sections':[title for _,title,_ in heads],'source_elements_retained':[x['source_element'] for x in ledger if x['kind']=='retained'],'ledger':ledger}
(results_dir('editorial')/'manuscript_build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(dest);print('WORDS',report['word_count'],'EQUATIONS',eqn)
