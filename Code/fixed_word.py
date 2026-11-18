from project_paths import INPUTS, stage_dir, check_document_text
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from lxml import etree
from copy import copy
import hashlib,json
root=stage_dir('fixed')
source=stage_dir('robustness')/'SURA_Selection_Robustness_Revision.docx'
check_document_text(source, 'ee5f69086ee27e9af0429a84b9205908ce2bf6f362b2f475ae6fe40f504ec0bd')
z=ZipFile(source);doc=etree.fromstring(z.read('word/document.xml'));ns=doc.nsmap
ps=doc.findall('w:body/w:p',ns)
def text(p):return ''.join(p.xpath('.//w:t/text()',namespaces=ns))
p=next(p for p in ps if text(p).startswith('The difference predates the 2014 recall interview'))
new='The pre-recall difference weakens an explanation confined to 2015 shocks, but cannot exclude persistent health influencing the 2014 recollection, reporting tendencies or confounding. An exploratory comparison fixes the sample at 8,719 respondents with complete data in both waves: self-rated-health coefficients are 3.44 and 5.96 percentage points in 2013 and 2015, respectively, an increase of 2.52 points (95% CI 0.28 to 4.76; p = 0.028). Joint estimation allows wave-specific control coefficients and clusters by community. The increase is therefore not solely due to changing respondent composition; its mechanism remains unresolved.'
oldtext=text(p);ts=p.xpath('.//w:t',namespaces=ns);ts[0].text=new
for t in ts[1:]:t.text=''
# Only the intended paragraph text changes, retaining its existing run/paragraph formatting.
dest=root/'SURA_Fixed_Sample_Revision.docx'
with ZipFile(dest,'w',ZIP_DEFLATED) as zz:
 for e in z.infolist():zz.writestr(copy(e),etree.tostring(doc,xml_declaration=True,encoding='UTF-8',standalone=True) if e.filename=='word/document.xml' else z.read(e.filename))
with ZipFile(dest) as zz:assert all(zz.read(n)==z.read(n) for n in z.namelist() if n!='word/document.xml')
# Restore text in an audit copy and check complete XML tree equality.
ts[0].text=oldtext
assert etree.tostring(doc)==etree.tostring(etree.fromstring(z.read('word/document.xml')))
audit={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'change':'one interpretation paragraph in Appendix H3','all_other_text_formatting_tables_figures_and_package_parts_unchanged':True}
(root/'Replication/document_verification.json').write_text(json.dumps(audit,indent=2))
print(dest)
