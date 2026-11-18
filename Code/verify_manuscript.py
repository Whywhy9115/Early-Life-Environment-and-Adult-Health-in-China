"""Verify result preservation, editable equations, captions and output provenance.
Structural and numerical checks complement, but do not replace, visual Word QA.
"""
from pathlib import Path
from zipfile import ZipFile
from lxml import etree as E
from collections import Counter
import json,re,os,hashlib
from project_paths import stage_dir,results_dir,INPUTS
root=Path(os.environ['EARLY_LIFE_OUTPUT_DIR']);p=root/'SURA_Revised_2026-11-18.docx';source=stage_dir('fixed')/'SURA_Fixed_Sample_Revision.docx'
z=ZipFile(p);src=ZipFile(source);d=E.fromstring(z.read('word/document.xml'));s=E.fromstring(src.read('word/document.xml'));ns=d.nsmap;W=ns['w']
def text(x):return ''.join(x.xpath('.//w:t/text()',namespaces=ns))
def style(x):
 a=x.find('w:pPr/w:pStyle',ns);return a.get('{'+W+'}val') if a is not None else ''
body=list(d.find('w:body',ns));old=list(s.find('w:body',ns));alltext='\n'.join(text(x) for x in body);checks={}
# Equations retain identical mathematical structures, unaffected by number changes.
def structure(x):return (x.tag,tuple(sorted(x.attrib.items())),x.text,tuple(structure(c) for c in x))
orig_math=Counter(structure(x) for x in s.xpath('//m:oMath',namespaces=ns));new_math=Counter(structure(x) for x in d.xpath('//m:oMath',namespaces=ns))
assert not (orig_math-new_math),'Original equation changed or missing'
checks['original_math_payloads_retained']=sum(orig_math.values())
nums=[]
for el in body:
 if el.xpath('.//m:oMath',namespaces=ns):nums+=list(map(int,re.findall(r'\((\d+)\)',text(el))))
assert nums==list(range(1,39)),nums
checks['continuous_numbered_equations']=len(nums)
# Every source table's numerical cells survive, irrespective of label/row placement.
def numeric_cells(t):
 return Counter(text(c).replace('−','-') for c in t.findall('.//w:tc',ns) if re.fullmatch(r'[\d\s,.()<>+*%±eE−\-–]+',text(c)) and re.search(r'\d',text(c)))
source_tables=[x for x in old if x.tag.endswith('}tbl')];tables=[x for x in body if x.tag.endswith('}tbl')]
for i,t in enumerate(source_tables):
 counts=numeric_cells(t)
 assert any(not (counts-numeric_cells(u)) for u in tables),f'Original numerical table {i+1} not preserved'
checks['original_tables_preserved_numerically']=len(source_tables)
# Embedded figure binaries are retained exactly; statistical replacements occurred upstream.
for name in src.namelist():
 if name.startswith('word/media/'):assert src.read(name)==z.read(name),name
checks['all_source_media_identical']=True
media_hashes={hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if n.startswith('word/media/')}
actual_figures=[]
for n in [1,3,4,5,6,7,8,9,10]:actual_figures.append(stage_dir('main')/'Figures'/f"Figure_{n}{'.jpg' if n in [1,3] else '.png'}")
actual_figures += [stage_dir('objective')/'Figures/Figure_12.png',stage_dir('discordance')/'Figures/Figure_13.png',stage_dir('discordance')/'Figures/Figure_14.png']
assert all(hashlib.sha256(f.read_bytes()).hexdigest() in media_hashes for f in actual_figures)
checks['statistical_figures_identical_to_regenerated_outputs']=len(actual_figures)
pagecache=json.loads((INPUTS/'pagination.json').read_text())['headings']
for el in body:
 if style(el)=='FinalTOCLine':
  field=el.find('w:fldSimple',ns)
  if field is not None:
   title=''.join(el.xpath('./w:r/w:t/text()',namespaces=ns));assert text(field)==str(pagecache[title])
checks['cached_native_Word_TOC_pages_verified']=len(pagecache)

caps=[text(x) for x in body if style(x)=='FinalCaption'];table_ids=[];figure_ids=[]
for c in caps:
 m=re.match(r'(Figure|Table) ([A-Z]?\d+)\s',c);assert m,c
 (figure_ids if m[1]=='Figure' else table_ids).append(m[2])
assert len(table_ids)==len(set(table_ids));assert len(figure_ids)==len(set(figure_ids));assert figure_ids==[str(i) for i in range(1,13)]+['C1','H1'],figure_ids
assert [x for x in table_ids if x.isdigit()]==[str(i) for i in range(1,17)]
for label,ids in [('Figure',figure_ids),('Table',table_ids)]:
 for ref in re.findall(r'\b'+label+r' ([A-Z]?\d+)\b',alltext):assert ref in ids,(label,ref)
checks['captions_and_references']={'figures':figure_ids,'tables':table_ids}
for i,el in enumerate(body):
 for dp in el.xpath('.//wp:docPr',namespaces=ns):assert dp.get('title')==text(body[i+1])==dp.get('descr')
checks['figure_metadata_match_captions']=True
assert '13,936' not in alltext and '13,721' not in alltext
assert 'VARIABLES' not in alltext and 'Cumulative TSP exposure' not in alltext
assert all(not re.match(r'G4 ',text(x)) for x in body)
# Styles and page geometry are byte-preserved from the source template.
assert z.read('word/styles.xml')==src.read('word/styles.xml')
assert structure(body[-1])==structure(old[-1]);checks['source_styles_and_page_geometry_retained']=True
# Verify new descriptive rows directly against the generated result, including denominators.
des=json.loads((results_dir('editorial')/'descriptive_results.json').read_text());t2=tables[table_ids.index('2')]
for row,data in zip(t2.findall('w:tr',ns)[1:],des['descriptive_table']):
 cells=[text(c) for c in row.findall('w:tc',ns)]
 assert cells[0]==data['label']
 for j,k in enumerate(['0','1'],1):
  v=data['groups'][k];assert cells[j]==f"{v['mean']:.2f} ({v['sd']:.2f}); {v['n']:,}"
 assert cells[3]==f"{data['difference']:.2f}"
checks['descriptive_rows_verified']=len(des['descriptive_table'])
# All complete primary-model coefficients in C3 are formatted from stored full precision.
obj=json.loads((results_dir('objective')/'objective_results.json').read_text())['models'];tc3=tables[table_ids.index('C3')]
for row,key in zip(tc3.findall('w:tr',ns)[1:],obj['2015_pef_primary']['terms']):
 cells=[text(c) for c in row.findall('w:tc',ns)]
 for j,y in enumerate(['pef','sbp','dbp','height'],1):
  v=obj['2015_'+y+'_primary']['terms'].get(key)
  expected=f"{v['b']:.3f}({v['se']:.3f})" if v else 'Reference';assert cells[j]==expected,(key,y,cells[j],expected)
checks['full_primary_coefficients_verified']=4*len(obj['2015_pef_primary']['terms'])
# Semantic anchors for the central reported contrast, beyond mere number occurrence.
dis=json.loads((results_dir('discordance')/'discordance_results.json').read_text());models=dis['models'];v=models['primary_z_difference']
assert models['primary_z_fair']['n']==models['primary_z_pef']['n']==13720
assert f"{v['b']:.3f}"=='0.126' and f"{v['low']:.3f}"=='0.079' and f"{v['high']:.3f}"=='0.172'
for phrase in ['0.126 SD (95% CI 0.079 to 0.172)','from 4.89 to 2.50','13,935','13,720','11,719','8,719']:
 assert phrase in alltext,phrase
for key in ['gap_full_effort','gap_standing','gap_strict_quality']:
 v=models[key];expected=f"{v['b']:.3f} ({v['low']:.3f}, {v['high']:.3f})";assert expected in text(tables[table_ids.index('8')]),(key,expected)
checks['central_semantic_anchors_verified']=True
# References occur in one list, and no unresolved source-link placeholder survives.
assert sum(text(x)=='References' and style(x)=='FinalHeading1' for x in body)==1
for x in body:
 if style(x)=='FinalReference':assert 'Source link' not in text(x) and 'Official questionnaire' not in text(x)
assert 'https://doi.org/10.2307/2955359' in alltext
checks['reference_list_verified']=True
checks['output_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
checks['scope']='All original table numeric cells; all original editable math and media; new descriptive and full-coefficient tables; primary semantic anchors and structural references. Visual pagination is checked separately.'
(results_dir('editorial')/'manuscript_verification.json').write_text(json.dumps(checks,indent=2));print(json.dumps({k:v for k,v in checks.items() if k!='captions_and_references'},indent=2))
