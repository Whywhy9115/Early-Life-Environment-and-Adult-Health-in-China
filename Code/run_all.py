#!/usr/bin/env python3
"""Reproduce the final paper in a new output directory, preserving all source files."""
from pathlib import Path
import argparse,datetime,hashlib,importlib,importlib.metadata,json,os,shutil,subprocess,sys,time,tempfile
sys.dont_write_bytecode=True
P=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(P/'Code'))
from project_paths import stage_dir,results_dir

def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda:f.read(4*1024*1024),b''):h.update(block)
    return h.hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive',type=Path,help='Original Qiu.zip; read only.')
    parser.add_argument('--output',type=Path,help='New, nonexistent output directory.')
    parser.add_argument('--check-only',action='store_true',help='Validate package, dependencies and data without analysis.')
    parser.add_argument('--recompute-main',action='store_true',default=True,help='Recompute all main models; this is the default.')
    parser.add_argument('--no-word',action='store_true',help='Run analysis and figures only.')
    a=parser.parse_args();config=json.loads((P/'config.json').read_text())
    archive=(a.archive or Path(config['default_archive'])).expanduser().resolve()
    if not archive.is_file():parser.error('Qiu.zip not found. Supply --archive /path/to/Qiu.zip.')
    cache=tempfile.TemporaryDirectory(prefix='early-life-font-')
    os.environ.setdefault('MPLCONFIGDIR',cache.name)
    versions={}
    for name in ['numpy','pandas','scipy','statsmodels','matplotlib','openpyxl','lxml','PIL']:
        importlib.import_module(name)
        distribution='pillow' if name=='PIL' else name
        versions[distribution]=importlib.metadata.version(distribution)
    from matplotlib import font_manager
    font_manager.findfont('Times New Roman',fallback_to_default=False)
    entries=json.loads((P/'manifest.json').read_text())
    for e in entries:
        path=P/e['file']
        if not path.is_file() or digest(path)!=e['sha256']:raise RuntimeError('Package file has changed: '+e['file'])
    if digest(archive)!=config['archive_sha256']:raise RuntimeError('Archive differs from the final-paper input. This package reproduces the fixed version; it must not silently insert new data into fixed manuscript prose.')
    print('Package, dependencies, Times New Roman and original data verified.',flush=True)
    if a.check_only:return
    out=(a.output or P/'runs'/datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')).expanduser().resolve()
    if out.exists():parser.error('--output must be new: existing outputs are never overwritten.')
    out.mkdir(parents=True);(out/'logs').mkdir();os.environ['EARLY_LIFE_OUTPUT_DIR']=str(out)
    env=os.environ.copy();env.update({'PYTHONDONTWRITEBYTECODE':'1','OPENBLAS_NUM_THREADS':'1','OMP_NUM_THREADS':'1','MKL_NUM_THREADS':'1','MPLCONFIGDIR':str(out/'matplotlib_cache'),'PYTHONPATH':os.pathsep.join([str(P/'Code'),str(P/'Code')])})
    records=[];started=time.time()
    def run(label,rel,use_archive=False):
        cmd=[sys.executable,str(P/'Code'/Path(rel).name)]+([str(archive)] if use_archive else [])
        print('Running '+label+' ...',flush=True);begin=time.time()
        log=out/'logs'/f'{len(records)+1:02d}_{label}.log'
        with log.open('w') as f:status=subprocess.run(cmd,cwd=out,env=env,stdout=f,stderr=subprocess.STDOUT).returncode
        records.append({'stage':label,'seconds':round(time.time()-begin,2),'returncode':status,'log':str(log.relative_to(out))})
        if status:raise RuntimeError(f'{label} failed. See {log}')
    def compare(stage,filename):
        import numpy as np
        expected=json.loads((P/'Inputs/reference_results'/stage/filename).read_text())
        actual=json.loads((results_dir(stage)/filename).read_text())
        checked=0
        def visit(x,y,path=''):
            nonlocal checked
            if isinstance(x,bool):
                if x!=y:raise AssertionError(path)
            elif isinstance(x,(float,int)):
                if not np.isclose(x,y,rtol=1e-6,atol=1e-7,equal_nan=True):raise AssertionError(f'{path}: {x} != {y}')
                checked+=1
            elif isinstance(x,dict):
                for k,v in x.items():
                    if k=='sources':continue
                    if k not in y:raise AssertionError('Missing '+path+'/'+k)
                    visit(v,y[k],path+'/'+k)
            elif isinstance(x,list):
                if len(x)!=len(y):raise AssertionError(path+' length')
                for i,(v,w) in enumerate(zip(x,y)):visit(v,w,path+f'/{i}')
            # Environment/source strings may differ; numerical results are the gate.
        visit(expected,actual)
        return {'stage':stage,'file':filename,'numeric_values_checked':checked,'matched':True}
    comparisons=[]
    try:
        if a.recompute_main:
            run('main_recomputed','main/full_analysis.py',True)
        else:
            for name in ['estimates.json','full_results.json']:shutil.copy2(P/'Inputs/reference_results/main'/name,results_dir('main')/name)
            print('Main/TSP: retained frozen results; no model refitting.',flush=True)
        for name in ['estimates.json','full_results.json']:comparisons.append(compare('main',name))
        run('main_figures','main/figures.py')
        for n in [2,11]:shutil.copy2(P/f'Inputs/Figure_{n}_original.png',stage_dir('main')/'Figures'/f'Figure_{n}_original.png')
        run('objective_analysis','objective/objective_analysis.py',True)
        comparisons.append(compare('objective','objective_results.json'))
        run('geography_audit','objective/geography_audit.py',True)
        comparisons.append(compare('objective','geography_inventory.json'))
        run('objective_figure','objective/plot_objective.py')
        run('discordance_analysis','discordance/discordance_analysis.py',True)
        comparisons.append(compare('discordance','discordance_results.json'))
        run('discordance_figures','discordance/plot_discordance.py')
        run('robustness_analysis','robustness/robustness_analysis.py',True)
        comparisons.append(compare('robustness','robustness_results.json'))
        run('independent_validation','robustness/validate_analysis.py',True)
        run('fixed_sample_analysis','fixed/fixed_sample_analysis.py',True)
        run('descriptive_tables','descriptive_tables.py',True)
        comparisons.append(compare('fixed','fixed_sample_results.json'))
        if not a.no_word:
            for stage in ['objective','discordance','robustness','fixed']:run(stage+'_word','word/'+stage+'_word.py')
            run('revised_manuscript','revise_manuscript.py')
            run('verify_manuscript','verify_manuscript.py')
            run('final_figure_numbering','export_final_figures.py')
        status='complete'
    except Exception:
        status='failed'
        raise
    finally:
        report={'status':status,'archive':str(archive),'archive_sha256':config['archive_sha256'],'main_mode':'recomputed original specifications' if a.recompute_main else 'frozen confirmed results','python':sys.version,'versions':versions,'elapsed_seconds':round(time.time()-started,2),'stages':records,'comparisons':comparisons,'output':str(out),'Word_numeric_prose_guard':'All retained numerical result structures must match before fixed-version document builders run.'}
        (out/'run_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
    print('Completed. Results: '+str(out),flush=True)
if __name__=='__main__':main()
