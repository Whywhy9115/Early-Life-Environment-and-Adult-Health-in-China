"""Optional: cache TOC page numbers from a Microsoft Word PDF export.
Run with the document/PDF Python environment providing pypdf. This is a layout
step, not an analysis step; the default runner uses the verified supplied cache.
"""
from pathlib import Path
from pypdf import PdfReader
import json,re,sys
P=Path(__file__).resolve().parent.parent
pages=PdfReader(sys.argv[1]).pages
mapping={}
for page in pages[1:3]:
 for line in page.extract_text().splitlines():
  m=re.match(r'^\s*(.*?)\s*\.{3,}\s*(\d+)\s*$',line)
  if m:mapping[m[1].strip()]=int(m[2])
assert len(mapping)>70,len(mapping)
(P/'Inputs/pagination.json').write_text(json.dumps({'renderer':'Microsoft Word for Mac','physical_pages':len(pages),'body_start_physical_page':4,'headings':mapping},ensure_ascii=False,indent=2))
print(len(mapping),'TOC entries')
