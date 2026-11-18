from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Generate Figure 12 from the actual estimates, preserving the paper's forest-plot style."""
from pathlib import Path
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

root=stage_dir('objective')
R=json.loads((root/'Replication/objective_results.json').read_text())['models']
rows=[('2015 primary','2015_pef_primary'),('2011 cross-wave check','2011_pef_primary'),('2013 cross-wave check','2013_pef_primary'),('Three trials and full effort','pef_three_full_effort'),('Exclude floor and ceiling','pef_no_endpoints'),('Adjust for adult characteristics','pef_adult_adjusted'),('Cluster by city','pef_city_cluster'),('Adjust for 2013 peak flow','pef_adjusted_2013')]
plt.rcParams.update({'font.family':'Times New Roman','font.size':12,'axes.linewidth':.6,'axes.unicode_minus':True})
fig=plt.figure(figsize=(8,5.65));ax=fig.add_axes([.36,.17,.29,.66])
y=np.arange(len(rows))[::-1];b=np.array([R[k]['b'] for _,k in rows]);lo=np.array([R[k]['low'] for _,k in rows]);hi=np.array([R[k]['high'] for _,k in rows])
ax.errorbar(b,y,xerr=np.vstack([b-lo,hi-b]),fmt='o',color='black',capsize=2.5,markersize=4,lw=.85)
ax.axvline(0,color='.55',ls=(0,(3,3)),lw=.65);ax.set_xlim(-7,7);ax.set_xticks([-6,-3,0,3,6]);ax.set_ylim(-.6,len(rows)-.3);ax.set_yticks([])
ax.set_xlabel('Difference in peak flow (L/min)',labelpad=13)
for name in ['left','right','top']:ax.spines[name].set_visible(False)
fig.text(.02,.93,'Specification',fontstyle='italic');fig.text(.76,.93,'N',fontstyle='italic',ha='right');fig.text(.99,.93,'Estimate (95% CI)',fontstyle='italic',ha='right')
fig.add_artist(plt.Line2D([.02,.99],[.89,.89],transform=fig.transFigure,color='black',lw=.5))
for (label,k),yy in zip(rows,y):
    v=R[k];yp=fig.transFigure.inverted().transform(ax.transData.transform((0,yy)))[1]
    fig.text(.02,yp,label,va='center',fontsize=11.5)
    fig.text(.76,yp,f"{v['n']:,}",va='center',ha='right',fontsize=11)
    fig.text(.99,yp,f"{v['b']:.2f} ({v['low']:.2f}, {v['high']:.2f})",va='center',ha='right',fontsize=11)
out=root/'Figures';out.mkdir(exist_ok=True)
fig.savefig(out/'Figure_12.png',dpi=300,facecolor='white');fig.savefig(out/'Figure_12.pdf',facecolor='white')
