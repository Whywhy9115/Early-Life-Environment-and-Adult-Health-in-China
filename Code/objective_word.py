from project_paths import INPUTS, stage_dir, check_document_text
"""Extend the verified SURA Word package using its own unchanged formatting components."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from copy import deepcopy,copy
import json,hashlib
from lxml import etree

root=stage_dir('objective')
source=INPUTS/'SURA_base.docx'
check_document_text(source, 'd5c8120a47f327001c8dde0329acb8e329ff5226191a8b69bdad5a2d15f471e4')
z=ZipFile(source);doc=etree.fromstring(z.read('word/document.xml'));ns=dict(doc.nsmap)
ns['a']='http://schemas.openxmlformats.org/drawingml/2006/main';ns['wp']='http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'
body=doc.find('w:body',ns);ps=body.findall('w:p',ns);tables=body.findall('w:tbl',ns)
R=json.loads((root/'Replication/objective_results.json').read_text());M=R['models']
old_ppr=[etree.tostring(p.find('w:pPr',ns)) if p.find('w:pPr',ns) is not None else None for p in ps]
old_rpr=[etree.tostring(x) for p in ps for x in p.xpath('.//w:rPr',namespaces=ns)]
old_tables=[etree.tostring(x) for x in tables]
def text(node,value):
    ts=node.xpath('.//w:t',namespaces=ns)
    if not ts:
        p=node if etree.QName(node).localname=='p' else node.find('.//w:p',ns)
        r=etree.SubElement(p,'{'+ns['w']+'}r');ts=[etree.SubElement(r,'{'+ns['w']+'}t')]
    ts[0].text=str(value);ts[0].set('{http://www.w3.org/XML/1998/namespace}space','preserve')
    for t0 in ts[1:]:t0.text=''
def plain(p):return ''.join(p.xpath('.//w:t/text()',namespaces=ns))
def clone(node):
    q=deepcopy(node)
    for b in q.xpath('.//w:bookmarkStart|.//w:bookmarkEnd',namespaces=ns):b.getparent().remove(b)
    return q
changes={
4:'Early-life environmental conditions may shape health long after exposure, yet retrospective neighborhood assessments and historical pollution records capture different dimensions of this relationship. This study examines their associations with health in China using the China Health and Retirement Longitudinal Study, its 2014 life-history survey, and historical total suspended particulate (TSP) concentrations from 1981–1995. The reported-outcome analyses use 15,797 adult main respondents with complete emotional items and 18,058 with harmonized general-health responses. Adult offspring are examined separately in 25,406 family records. Linear, binary and ordered response models assess neighborhood associations, while Probit and instrumental-variable Probit models examine 6,539 pollution-linked records. A favorable recalled neighborhood is associated with a 0.320-point higher emotional-response count and a 4.66 percentage point higher adjusted probability of fair or better self-rated health. The health difference remains 3.75 points after adjustment for childhood family finances. A measured-health extension prioritizes peak expiratory flow among 13,935 main respondents aged 45 or older in 2015. Its adjusted neighborhood difference is −1.29 L/min (95% CI −5.20 to 2.62); supplementary blood-pressure and height estimates also have intervals containing zero. Birth-year and weighted TSP estimates remain imprecise under city-clustered inference. The objective outcomes do not corroborate a corresponding measured-health advantage, while not identifying reporting bias or ruling out pollution effects. Retrospective reporting, selection and geographical assignment limit causal interpretation. Distinguishing reporting sources and exposure timing remains essential to evaluating health across the life course.',
239:'Measured outcomes qualify the reporting results. In 2015, the adjusted neighborhood difference in peak flow is −1.29 L/min (95% CI −5.20 to 2.62; N = 13,935). Blood pressure and height also have intervals containing zero. Appendix E reports measurement rules, all outcomes and sensitivity checks.',
241:'The matched-sample comparison retains a positive self-rated-health association without a corresponding peak-flow difference. This contrast does not establish reporting bias. Geography and residential histories remain unresolved for causal pollution analysis; Appendix F documents why a Huai River regression-discontinuity design cannot yet be estimated from the available geographic inputs.',
244:'The measured-health extension finds no clear neighborhood association with peak flow, blood pressure or height. These results qualify a general physiological interpretation of the reporting associations. They do not establish that pollution is harmless or isolate reporting bias. A causal redesign requires verified residential locations, policy-boundary support and exposure timing.',
318:'The measured-health extension in Appendix E uses raw peak-flow, blood-pressure and height readings. Its estimates do not corroborate a measured-health advantage associated with favorable neighborhood recall. Further work can examine graded CES-D-10 scores, test participation and recall mechanisms; these questions remain distinct from identifying a causal pollution effect.',
330:'Appendix F audits the proposed Huai River design. Individual migration information improves exposure assessment, but the archive lacks verified coordinates and policy-boundary distances. Local support, pollution discontinuities and alternative heating pathways must be evaluated before replacing the meteorological instruments or interpreting a policy contrast as an early-life pollution effect.'
}
for i,v in changes.items():
    print('paragraph',i,'words',len(plain(ps[i]).split()),'->',len(v.split()));text(ps[i],v)

# Add TOC entries without changing any existing paragraph geometry.
for title,page,anchor in [('Appendix E Measured health outcomes','41','ObjectiveE'),('Appendix F Feasibility of a Huai River design','44','ObjectiveF')]:
    q=clone(ps[42]);ts=q.xpath('.//w:t',namespaces=ns)
    ts[0].text=title
    for x in ts[1:]:x.text=''
    ts[-1].text=page
    for h in q.xpath('.//w:hyperlink',namespaces=ns):h.set('{'+ns['w']+'}anchor',anchor)
    body.insert(body.index(ps[43]),q)

section=body.find('w:sectPr',ns)
def add(node):body.insert(body.index(section),node);return node
def para(value,role=316,pagebreak=False):
    q=clone(ps[role]);text(q,value)
    for h in q.xpath('.//w:hyperlink',namespaces=ns):
        if not plain(h):h.getparent().remove(h)
    if pagebreak and q.find('w:pPr/w:pageBreakBefore',ns) is None:etree.SubElement(q.find('w:pPr',ns),'{'+ns['w']+'}pageBreakBefore')
    return add(q)
def heading(value,newpage=False):return para(value,315,newpage)
def caption(value):return para(value,311)
def note(value):return para(value,312)
def table(headers,rows):
    q=clone(tables[5]);source_rows=q.findall('w:tr',ns);ht=deepcopy(source_rows[2]);bt=deepcopy(source_rows[4])
    for row in source_rows:q.remove(row)
    for vals,template in [(headers,ht)]+[(r,bt) for r in rows]:
        row=deepcopy(template);cells=row.findall('w:tc',ns);assert len(cells)==len(vals)==4
        for c,v in zip(cells,vals):text(c,v)
        q.append(row)
    return add(q)
def val(k):
    v=M[k];return [f"{v['n']:,}",f"{v['b']:.2f}",f"({v['low']:.2f}, {v['high']:.2f})"]
def ci(k):
    v=M[k];return f"{v['b']:.2f} ({v['low']:.2f}, {v['high']:.2f})"

# Physical page 43; body page 41. New components use the source paragraph and table roles.
he=para('Appendix E Measured health outcomes',314)
heading('E1 Sample construction and measurement')
para('The extension links main respondents to their own 2014 neighborhood report. The primary wave is 2015; 2011 and 2013 provide earlier-wave checks. Raw biomarker files are linked by individual ID, without latest-wave or household-based birthplace restrictions. Age is survey year minus life-history birth year; eligibility requires age 45 or older.')
caption('Table E1  Construction of the measured-health samples')
table(['Selection stage','2011','2013','2015'],[
['Biomarker records']+[f"{R['flow'][str(y)]['biomarker_records']:,}" for y in [2011,2013,2015]],
['Valid neighborhood report']+[f"{R['flow'][str(y)]['valid_neighborhood']:,}" for y in [2011,2013,2015]],
['Age 45 or older']+[f"{R['flow'][str(y)]['age45_neighborhood']:,}" for y in [2011,2013,2015]],
['Valid peak flow']+[f"{R['flow'][str(y)]['pef_available']:,}" for y in [2011,2013,2015]],
['Peak-flow estimation sample']+[f"{M[f'{y}_pef_primary']['n']:,}" for y in [2011,2013,2015]]])
note('Notes: Counts are individuals within each wave; participants overlap across waves. The final row also requires sex, province, community and childhood-finance information. The original reported-health sample and these reconstructed biomarker samples have different selection rules.')
para('Peak expiratory flow is the maximum of at least two valid QB002–QB004 readings, cleaned before aggregation. Codes 993 and 999 indicate unsuccessful or declined measurements and are excluded. Instrument endpoints 30 and 890 L/min are retained, then excluded in a sensitivity check. Peak flow is neither a diagnosis nor a forced expiratory volume measurement (CHARLS, 2015).')
para('Blood-pressure outcomes average at least two valid paired measurements. Data-quality bounds are 50–300 mmHg for systolic and 30–200 mmHg for diastolic pressure, with systolic exceeding diastolic. Height is retained between 100 and 210 cm. These rules exclude invalid readings without defining clinical hypertension. Treatment can affect measured blood pressure, and older-age height may reflect shrinkage as well as early growth.')
heading('E2 Model specification')
para('Primary OLS models include age centered at 60 and its square, sex, current-province indicators and childhood-finance categories. Community-clustered intervals use t reference values with G − 1 degrees of freedom. The 2015 peak-flow sample spans 448 communities and 122 cities. Adult height, education, urban residence and smoking enter separate checks because they may be pathways from childhood conditions to later health.')

# Physical page 44.
heading('E3 Main estimates and earlier-wave checks',True)
para('Table E2 reports every designated outcome in its original units. The peak-flow coefficient is −1.29 L/min (p = 0.518). Blood-pressure and height estimates are also close to zero, with raw p-values of 0.602, 0.803 and 0.868, respectively. Holm adjustment across the three supplementary outcomes gives adjusted p-values of 1.000. These are unweighted conditional associations among measured survivors, not estimates of national prevalence or causal effects.')
caption('Table E2  Neighborhood associations with measured health in 2015')
table(['Outcome','Observations','Difference','95% confidence interval'],[
['Peak flow (L/min)']+val('2015_pef_primary'),['Systolic pressure (mmHg)']+val('2015_sbp_primary'),['Diastolic pressure (mmHg)']+val('2015_dbp_primary'),['Height (cm)']+val('2015_height_primary')])
note('Notes: Differences compare favorable D5 categories 1–2 with unfavorable categories 3–4. All models include age, age squared, sex, province indicators and childhood-finance categories. Community-clustered 95% intervals are pointwise. Peak flow is primary; systolic pressure, diastolic pressure and height are supplementary.')
para('On the same 13,935-person peak-flow sample, the age-and-sex coefficient is −2.52 L/min (95% CI −6.67 to 1.63). Adding province indicators gives 0.41 (−3.49 to 4.30); adding childhood finances gives the primary estimate. Thus, the near-zero pattern does not depend on one selected adjustment set.')
caption('Table E3  Measured-health associations across survey waves')
table(['Outcome','2011','2013','2015'],[[label]+[ci(f'{y}_{key}_primary') for y in [2011,2013,2015]] for label,key in [('Peak flow (L/min)','pef'),('Systolic pressure (mmHg)','sbp'),('Diastolic pressure (mmHg)','dbp'),('Height (cm)','height')]])
note('Notes: Cells give the coefficient and community-clustered 95% interval under the primary specification. In 2011, N = 10,817 for peak flow, 11,145 for either pressure outcome and 11,124 for height; corresponding 2013 counts are 10,972, 11,271 and 11,433. The 2015 counts appear in Table E2. Earlier-wave outcomes precede the retrospective 2014 report and are not independent replications.')
para('All earlier-wave intervals include zero. Across available peak-flow records, 8,894 participants appear in both 2013 and 2015, illustrating the dependence between these checks. The results do not support promoting neighborhood recall to an established predictor of these measured outcomes. They also do not test a well-defined historical pollution dose or exclude effects on other dimensions of health.')

# Physical page 45.
heading('E4 Peak-flow sensitivity and interpretation',True)
# Locate the source Figure 4 drawing by its preceding figure paragraph, not a guessed relationship.
fig4cap=next(i for i,p in enumerate(ps) if plain(p).startswith('Figure 4  '))
figpara=clone(ps[fig4cap-1]);assert figpara.xpath('.//w:drawing',namespaces=ns)
rels=etree.fromstring(z.read('word/_rels/document.xml.rels'));rel_ns=rels.nsmap[None]
rid='rIdObjective12';etree.SubElement(rels,'{'+rel_ns+'}Relationship',Id=rid,Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image',Target='media/objective_figure12.png')
for bl in figpara.xpath('.//a:blip',namespaces=ns):bl.set('{'+ns['r']+'}embed',rid)
# New plot ratio; preserve the source forest plot width. Existing figures are never resized.
extent=figpara.find('.//wp:extent',ns);cx=int(extent.get('cx'));cy=round(cx*5.65/8);extent.set('cy',str(cy))
for ex in figpara.xpath('.//a:xfrm/a:ext',namespaces=ns):ex.set('cy',str(cy))
for dp in figpara.xpath('.//wp:docPr',namespaces=ns):dp.set('id','120');dp.set('name','Figure 12');dp.set('descr','Peak-flow estimates and pointwise confidence intervals under prespecified specifications.')
for cp in figpara.xpath('.//*[local-name()="cNvPr"]'):cp.set('id','120');cp.set('name','Figure 12')
add(figpara);caption('Figure 12  Peak-flow estimates across waves and sensitivity specifications')
note('Notes: Points and intervals are computed directly from the model results. Intervals use t-based clustered inference. The adult-characteristic model adds height, education, urban residence and smoking to the primary covariates. The last row additionally conditions on 2013 peak flow. These selected subsets and overlapping waves are not independent estimates.')
para('Every plotted sensitivity interval includes zero. The age-45–64 height estimate is 0.008 cm (95% CI −0.248 to 0.263). Seated, fully compliant blood-pressure readings without recent smoking, exercise, food or alcohol give 0.23 mmHg (−0.54 to 1.00) for systolic and 0.14 (−0.31 to 0.59) for diastolic pressure.')
heading('E5 A matched-sample reporting comparison')
para('An exploratory check added after the objective-outcome estimates uses 13,720 respondents with both outcomes. With the primary covariates, the Probit average contrast for fair-or-better health is 5.10 percentage points (95% CI 3.44–6.76); the peak-flow difference is −1.28 L/min (−5.21 to 2.66). Matching reduces sample-composition differences. Different constructs, precision and residual confounding remain; this is neither a formal test of equal associations nor proof of reporting bias.')

# Physical page 46.
hf=para('Appendix F Feasibility of a Huai River design',314)
heading('F1 Geographic support in the current archive')
para('A Huai River heating-policy design requires verified locations, a defensible Qinling–Huai River policy boundary and sufficient locations near both sides. The 2015 peak-flow sample covers 122 prefecture-level cities in 28 provinces and 448 communities. These national counts do not establish local support; no boundary-based model is estimated here.')
para('An inventory of 309 Stata datasets under the raw and working-data directories found no fields identifiable as respondent coordinates, signed policy-boundary distances or north-of-boundary indicators; the archive also contains no standard geospatial boundary files. PSU metadata give province and city names. The life-history residence module contains location references and movement histories, but not verified coordinates needed for a running variable. These findings concern the supplied archive, not all data potentially obtainable from CHARLS.')
para('City-centroid assignment offers only a coarse screen when cities span the boundary or respondents live far from their centers. The stored TSP series is interpolated. Original monitors, interpolation assumptions and exposure uncertainty require checking before interpreting a discontinuity. Copying city values across respondents does not add independent exposure locations.')
heading('F2 Birthplace and migration')
caption('Table F1  Residence-history checks in the primary peak-flow sample')
table(['Check','Count','Denominator','Interpretation'],[
['Local-birth proxy 1 or 2','11,735','13,935','Not a nonmover definition'],
['First residence reported moved','2,629','11,735','Movement despite local-birth proxy'],
['First residence not moved','9,101','11,735','Requires timing and location verification'],
['Movement status unavailable','5','11,735','Not classified'],
['Born before 1950','4,248','13,935','Birth can precede policy expansion']])
note('Notes: The local-birth proxy prioritizes 2015 BB001 and fills missing entries from earlier waves; it is provisional when residence changes. The movement flag is the 2014 life-history item T001B for the first residence. A move need not cross the heating-policy boundary. Counts do not define a validated lifetime exposure sample.')
para('Local birth cannot be renamed nonmigration. The original household-level selection may assign one member’s birthplace status to another; this extension links individuals directly. Exposure reconstruction needs dated histories and explicit treatment of return migration, missing histories and moves after the life-history interview.')

# Physical page 47.
heading('F3 Exposure timing and the decision to proceed',True)
para('The primary peak-flow participants were aged 11–63 in 1981. Their 1981–1995 pollution histories therefore cover different life stages and do not isolate prenatal or early-childhood exposure. A valid heating-policy contrast could identify a long-term policy-related exposure difference under suitable assumptions; it would not, by itself, identify when in the life course the effect arose. The earlier TSP analysis and this proposed design have different target populations and exposure definitions.')
para('The original Huai River research uses geographic discontinuities in sustained exposure: Chen et al. (2013) study TSP, while Ebenstein et al. (2017) examine PM10. Their pollution jumps are not first-stage estimates for the CHARLS sample. A CHARLS application must estimate its own local first stage and assess the relevance of urban heating provision to rural respondents. Heating can also affect health through indoor warmth and other pathways, so translating a policy effect into a pollution effect requires an exclusion argument.')
para('The current decision is to retain the measured-outcome results as evidence about the scope of the neighborhood association, without promoting a Huai River instrument. Boundary-side counts, bandwidth-specific support, covariate continuity and a local pollution first stage are not estimable from the verified geographic inputs. They are unresolved prerequisites, not failed statistical tests and not evidence that the policy design is impossible.')
para('The next empirical gate is a validated geographic crosswalk and policy boundary linked to dated residence histories. With that input, report city or finer-location counts on each side within prespecified bandwidths, local linear estimates, clustering at the assignment level and sensitivity to boundary and interpolation uncertainty. Proceed on design credibility and precision, rather than selecting a bandwidth or outcome that yields significance. Separating early-life exposure would additionally require a defensible timing contrast.')
heading('References for Appendices E and F')
ref=next(i for i,p in enumerate(ps) if plain(p).startswith('Barker, D. J.'))
para('China Health and Retirement Longitudinal Study (CHARLS). (2015). Biomarker questionnaire 2015. Peking University. https://charls.pku.edu.cn/sj/tijianwenjuan2015.pdf',ref)
para('Chen, Y., Ebenstein, A., Greenstone, M., & Li, H. (2013). Evidence on the impact of sustained exposure to air pollution on life expectancy from China’s Huai River policy. Proceedings of the National Academy of Sciences, 110(32), 12936–12941. https://doi.org/10.1073/pnas.1300018110',ref)
para('Ebenstein, A., Fan, M., Greenstone, M., He, G., & Zhou, M. (2017). New evidence on the impact of sustained exposure to air pollution on life expectancy from China’s Huai River Policy. Proceedings of the National Academy of Sciences, 114(39), 10384–10389. https://doi.org/10.1073/pnas.1616784114',ref)
max_book=max([int(x) for x in doc.xpath('.//w:bookmarkStart/@w:id',namespaces=ns)]+[0])
for j,(h,name) in enumerate([(he,'ObjectiveE'),(hf,'ObjectiveF')],1):
    start=etree.Element('{'+ns['w']+'}bookmarkStart');start.set('{'+ns['w']+'}id',str(max_book+j));start.set('{'+ns['w']+'}name',name)
    end=etree.Element('{'+ns['w']+'}bookmarkEnd');end.set('{'+ns['w']+'}id',str(max_book+j));h.insert(1,start);h.append(end)

# Preserve all original formatting and opaque package components.
assert old_ppr==[etree.tostring(p.find('w:pPr',ns)) if p.find('w:pPr',ns) is not None else None for p in ps]
assert old_rpr==[etree.tostring(x) for p in ps for x in p.xpath('.//w:rPr',namespaces=ns)]
assert old_tables==[etree.tostring(x) for x in tables]
dest=root/'SURA_Objective_Health_Revision.docx'
changes_xml={'word/document.xml':etree.tostring(doc,xml_declaration=True,encoding='UTF-8',standalone=True),'word/_rels/document.xml.rels':etree.tostring(rels,xml_declaration=True,encoding='UTF-8',standalone=True)}
with ZipFile(dest,'w',ZIP_DEFLATED) as out:
    for e in z.infolist():out.writestr(copy(e),changes_xml.get(e.filename,z.read(e.filename)))
    out.writestr('word/media/objective_figure12.png',(root/'Figures/Figure_12.png').read_bytes())
with ZipFile(dest) as out:
    preserved=[n for n in z.namelist() if n not in changes_xml];assert all(z.read(n)==out.read(n) for n in preserved)
    assert not doc.xpath('.//w:tc/w:r',namespaces=ns)
audit={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'revision_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'preserved_parts':len(preserved),'original_paragraph_formatting_unchanged':True,'original_tables_unchanged':True,'original_images_unchanged':True,'added_appendices':['E','F'],'original_paragraph_edits':list(changes)}
(root/'Replication/document_verification.json').write_text(json.dumps(audit,indent=2));print(dest)
