from project_paths import CODE, INPUTS, results_dir, stage_dir
from pathlib import Path
import json,numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
root=stage_dir('discordance')
R=json.loads((root/'Replication/discordance_results.json').read_text())['models']
plt.rcParams.update({'font.family':'Times New Roman','font.size':12,'axes.linewidth':.6,'axes.unicode_minus':True})
def plot(rows,file,scale,xlim,ticks,xlabel,height):
 fig=plt.figure(figsize=(8,height));ax=fig.add_axes([.37,.22,.29,.55]);y=np.arange(len(rows))[::-1]
 b=np.array([R[k]['b'] for _,k in rows])*scale;lo=np.array([R[k]['low'] for _,k in rows])*scale;hi=np.array([R[k]['high'] for _,k in rows])*scale
 ax.errorbar(b,y,xerr=np.vstack([b-lo,hi-b]),fmt='o',color='black',capsize=3,markersize=4,lw=.85)
 ax.axvline(0,color='.55',ls=(0,(3,3)),lw=.65);ax.set_xlim(*xlim);ax.set_xticks(ticks);ax.set_ylim(-.5,len(rows)-.5);ax.set_yticks([]);ax.set_xlabel(xlabel,labelpad=12)
 for s in ['left','right','top']:ax.spines[s].set_visible(False)
 fig.text(.02,.91,'Outcome or specification',fontstyle='italic');fig.text(.99,.91,'Estimate (95% CI)',fontstyle='italic',ha='right');fig.add_artist(plt.Line2D([.02,.99],[.86,.86],transform=fig.transFigure,color='black',lw=.5))
 for (label,k),yy in zip(rows,y):
  v=R[k];yp=fig.transFigure.inverted().transform(ax.transData.transform((0,yy)))[1];fig.text(.02,yp,label,va='center',fontsize=11.5);fig.text(.99,yp,f"{v['b']*scale:.3f} ({v['low']*scale:.3f}, {v['high']*scale:.3f})",va='center',ha='right',fontsize=10.8)
 for ext in ['png','pdf']:fig.savefig(root/'Figures'/f'{file}.{ext}',dpi=300,facecolor='white')
plot([('Self-rated health','primary_z_fair'),('Peak expiratory flow','primary_z_pef'),('Paired difference','primary_z_difference')],'Figure_13',1,(-.06,.19),[-.05,0,.05,.10,.15],'Standardized association (SD)',3.5)
plot([('Baseline','common_base'),('Add CES-D-10','common_cesd'),('Add measured health','common_measured'),('Add full health block','common_health'),('Add health and CES-D-10','common_both')],'Figure_14',100,(-.2,7.1),[0,2,4,6],'Self-rated health difference (pp)',4.3)
