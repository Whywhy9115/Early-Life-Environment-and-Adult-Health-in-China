from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Read archive metadata and record available coordinate or policy-distance fields."""
from pathlib import Path
from zipfile import ZipFile
import argparse,re,json,warnings
import pandas as pd
ap=argparse.ArgumentParser();ap.add_argument('archive');a=ap.parse_args();z=ZipFile(a.archive)
hits={};errors=[];nfiles=0
for n in z.namelist():
    if n.startswith('__MACOSX') or not n.endswith('.dta') or not any(s in n for s in ['Raw_data/','Working_data/']):continue
    nfiles+=1
    try:
        with z.open(n) as f:
            with pd.io.stata.StataReader(f) as r:
                labs=r.variable_labels();match={k:v for k,v in labs.items() if re.search(r'latitude|longitude|经度|纬度|huai|qinling|dist_h|(^|_)(lat|lon|lng|north)(_|$)',k+' '+v,re.I)}
                if match:hits[n]=match
    except Exception as e:errors.append([n,str(e)])
out={'files_scanned':nfiles,'coordinate_or_boundary_fields':hits,'errors':errors,'geospatial_files':[n for n in z.namelist() if not n.startswith('__MACOSX') and n.lower().endswith(('.shp','.geojson','.gpkg','.kml'))]}
(results_dir('objective')/'geography_inventory.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
print(json.dumps(out,ensure_ascii=False))
