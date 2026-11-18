"""Collect original/generated figures under the revised manuscript numbering."""
from pathlib import Path
import shutil,os,json,hashlib
from project_paths import stage_dir
out=Path(os.environ['EARLY_LIFE_OUTPUT_DIR'])/'Figures';out.mkdir(exist_ok=True)
mapping={'1':('main','2_original'),'2':('main','1'),'3':('main','3'),'4':('main','6'),'5':('main','7'),'6':('main','8'),'7':('discordance','13'),'8':('discordance','14'),'9':('main','9'),'10':('main','4'),'11':('main','5'),'12':('main','10'),'C1':('objective','12'),'H1':('main','11_original')}
records=[]
for label,(stage,old) in mapping.items():
 for suffix in ['.png','.pdf','.jpg']:
  src=stage_dir(stage)/'Figures'/('Figure_'+old+suffix)
  if not src.exists():continue
  dest=out/('Figure_'+label+suffix);shutil.copy2(src,dest)
  records.append({'figure':label,'file':dest.name,'source_stage':stage,'source_figure':old,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(out/'figure_sources.json').write_text(json.dumps(records,indent=2));print(len(mapping),'figures collected')
