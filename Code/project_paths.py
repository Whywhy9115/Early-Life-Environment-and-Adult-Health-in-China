"""Shared paths for the consolidated, non-destructive reproduction package."""
from pathlib import Path
import os,json,hashlib
PACKAGE=Path(__file__).resolve().parent.parent
CODE=PACKAGE/'Code'
INPUTS=PACKAGE/'Inputs'
def stage_dir(stage):
    location=os.environ.get('EARLY_LIFE_OUTPUT_DIR')
    if not location:raise RuntimeError('Use run_all.py to create a new isolated output directory.')
    p=Path(location)/stage
    (p/'Replication').mkdir(parents=True,exist_ok=True)
    (p/'Figures').mkdir(exist_ok=True)
    return p
def results_dir(stage):return stage_dir(stage)/'Replication'
def check_document_text(path,expected):
    from zipfile import ZipFile
    from lxml import etree
    with ZipFile(path) as z:
        d=etree.fromstring(z.read('word/document.xml'))
        texts=d.xpath('//w:t/text()',namespaces=d.nsmap)
    actual=hashlib.sha256(json.dumps(texts,ensure_ascii=False).encode()).hexdigest()
    if actual!=expected:raise RuntimeError(f'Unexpected predecessor text: {path}. Refusing to apply a fixed-version Word patch.')
