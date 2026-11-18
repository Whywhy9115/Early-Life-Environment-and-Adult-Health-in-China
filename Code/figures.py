from project_paths import CODE, INPUTS, results_dir, stage_dir
"""Draw the statistical figures directly from full_results.json."""
from pathlib import Path
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties

root=stage_dir('main')
out=root/'Figures';out.mkdir(exist_ok=True)
data=json.loads((root/'Replication/full_results.json').read_text())
plt.rcParams.update({'font.family':'Times New Roman','font.size':12,'axes.linewidth':.6,'savefig.dpi':300,'axes.unicode_minus':True})
def save(fig,n):
    fig.savefig(out/f'Figure_{n}.png',dpi=300,facecolor=fig.get_facecolor())
    fig.savefig(out/f'Figure_{n}.pdf',facecolor=fig.get_facecolor())
    if n in [1,3]:
        fig.savefig(out/f'Figure_{n}.jpg',dpi=300,facecolor=fig.get_facecolor(),pil_kwargs={'quality':98})
    plt.close(fig)
def forest(n,labels,values,xlabel,width=8,height=4.615):
    fig=plt.figure(figsize=(width,height));ax=fig.add_axes([.29,.19,.40,.67])
    b=np.array([r['b'] for r in values]);se=np.array([r['se'] for r in values])
    y=np.arange(len(b))[::-1]
    ax.errorbar(b,y,xerr=1.96*se,fmt='o',color='black',capsize=2.5,markersize=4,lw=.85)
    ax.axvline(0,color='.55',ls=(0,(3,3)),lw=.65)
    ax.set_yticks([]);ax.set_ylim(-.55,len(b)-.25)
    lo=min(0,min(b-1.96*se));hi=max(0,max(b+1.96*se));pad=(hi-lo)*.16
    ax.set_xlim(lo-pad,hi+pad);ax.set_xlabel(xlabel,labelpad=15)
    for name in ['left','right','top']:ax.spines[name].set_visible(False)
    fig.text(.02,.93,'Outcome definition',fontstyle='italic',va='center')
    fig.text(.99,.93,'Estimate (95% CI)',fontstyle='italic',ha='right',va='center')
    fig.add_artist(plt.Line2D([.02,.99],[.88,.88],transform=fig.transFigure,color='black',lw=.5))
    for label,bb,ss,yy in zip(labels,b,se,y):
        yp=fig.transFigure.inverted().transform(ax.transData.transform((0,yy)))[1]
        fig.text(.02,yp,label,va='center')
        fig.text(.99,yp,f'{bb:.3f} ({bb-1.96*ss:.3f}, {bb+1.96*ss:.3f})',ha='right',va='center')
    save(fig,n)
forest(4,[f'Score ≥ {c}' for c in [2,4,6,8,9]],[data['models'][f'emotional_{c}']['terms']['ce_good'] for c in [2,4,6,8,9]],'Probit coefficient')
for n,key,labels in [(5,'emotional',['Score 0–2','Score 3–4','Score 5–6','Score 7–8','Score 9–10']),(9,'health',['Very poor','Poor','Fair','Good','Very good'])]:
    values=[{'b':r['b']*100,'se':r['se']*100} for r in data['ordered'][key]['terms']['ce_good']]
    forest(n,labels,values,'Average contrast (percentage points)')
shares=np.array(data['figures']['health_shares'])*100
fig,ax=plt.subplots(figsize=(8,3.935));fig.subplots_adjust(left=.29,right=.99,top=.77,bottom=.25)
left=np.zeros(2);colors=['.25','.65','.92']
for j,(label,color) in enumerate(zip(['Poor or very poor','Fair','Good or very good'],colors)):
    ax.barh([1,0],shares[:,j],left=left,height=.31,color=color,edgecolor='black',linewidth=.5,label=label)
    for i,y in enumerate([1,0]):ax.text(left[i]+shares[i,j]/2,y,f'{shares[i,j]:.1f}%',ha='center',va='center',color='white' if j==0 else 'black')
    left+=shares[:,j]
ax.set_yticks([1,0],['Less favorable','More favorable']);ax.tick_params(axis='y',length=0,pad=60)
ax.set_xlim(0,100);ax.set_xticks([0,25,50,75,100]);ax.set_ylim(-.45,1.45);ax.set_xlabel('Share within neighborhood category (%)',labelpad=12)
for s in ['top','right','left']:ax.spines[s].set_visible(False)
fig.legend(loc='upper center',ncol=3,frameon=False,fontsize=11,handlelength=1)
save(fig,6)

def stata_axes():
    fig,ax=plt.subplots(figsize=(8,5.824),facecolor='#e1e1e1')
    fig.subplots_adjust(left=.13,right=.97,top=.91,bottom=.23)
    ax.set_facecolor('white');ax.grid(axis='y',color='#eeeeee');ax.set_axisbelow(True)
    for sp in ['top','right']:ax.spines[sp].set_visible(False)
    ax.tick_params(labelsize=11)
    return fig,ax
for n,key,groups in [(7,'age',['45–54','55–64','65+']),(8,'education',['Below middle school','Middle school and above'])]:
    fig,ax=stata_axes()
    records=data['figures'][key]
    for j,group in enumerate(groups):
        for k,ce in enumerate([1,0]):
            record=next(r for r in records if r['group']==group and r['ce_good']==ce)
            ax.bar(j*2.5+k,record['mean'],width=.70,color='#1e4662',edgecolor='none')
    ax.set_xticks([j*2.5+k for j in range(len(groups)) for k in [0,1]],['Good','Poor']*len(groups),fontsize=10)
    for j,group in enumerate(groups):ax.text(j*2.5+.5,-.11,group,ha='center',va='top',transform=ax.get_xaxis_transform(),fontsize=11)
    ax.set_ylim(0,1);ax.set_yticks(np.arange(0,1.01,.2));ax.set_ylabel('Health fair or better')
    fig.text(.5,.975,'Adult health',ha='center',va='top')
    fig.text(.5,.94,'by childhood environment quality and '+key,ha='center',va='top',fontsize=11)
    fig.text(.03,.035,'Source: CHARLS main respondents',fontsize=9)
    save(fig,n)
for n in [1,3]:
    fig,ax=stata_axes();years=np.arange(1981,1996)
    series=data['figures']['urban_rural'] if n==1 else data['figures']['historical_cities']
    colors=['#254e64','#903e47','#6b6e43','#b9a575']
    for (name,values),color in zip(series.items(),colors):
        label={'0':'Rural','1':'Urban'}.get(name,name)
        ax.plot(years,values,color=color,lw=2.3 if n==1 else 1.1,label=label)
    ax.set_xlim(1980,1995);ax.set_xticks([1980,1985,1990,1995]);ax.set_xlabel('Year')
    ax.set_ylabel('Average TSP concentration (µg/m³)' if n==1 else 'TSP concentration (µg/m³)')
    ax.legend(loc='upper right',ncol=2,frameon=True,facecolor='white',edgecolor='black',fancybox=False,fontsize=10)
    fig.text(.5,.10,'Concentration of TSP in Rural and Urban cities of China' if n==1 else 'Concentration of TSP in Typical Cities of China',ha='center',fontsize=13,color='#182e48')
    fig.text(.025,.035,'Source: Archived TSP series, 1981–1995',fontsize=9)
    save(fig,n)
fig=plt.figure(figsize=(8,5.64))
for j,(kind,title) in enumerate([('','(a) Probit'),('iv_','(b) Instrumental variable Probit')]):
    bottom=.59 if j==0 else .16
    ax=fig.add_axes([.30,bottom,.40,.23])
    rows=[data['models'][kind+x]['terms'][x] for x in ['TSP','TSP_total']]
    b=np.array([r['b'] for r in rows])*100;se=np.array([r['se'] for r in rows])*100
    ax.errorbar(b,[1,0],xerr=1.96*se,fmt='o',color='black',capsize=2,markersize=3.5,lw=.8)
    ax.axvline(0,color='.6',ls=(0,(3,3)),lw=.6);ax.set_ylim(-.5,1.5);ax.set_yticks([])
    for sp in ['top','right','left']:ax.spines[sp].set_visible(False)
    fig.text(.02,bottom+.30,title,fontweight='bold')
    fig.text(.99,bottom+.30,'Estimate (95% CI)',fontstyle='italic',ha='right')
    fig.add_artist(plt.Line2D([.02,.99],[bottom+.275,bottom+.275],transform=fig.transFigure,color='black',lw=.5))
    for label,bb,ss,y in zip(['Birth-year TSP','Weighted TSP index'],b,se,[1,0]):
        yp=fig.transFigure.inverted().transform(ax.transData.transform((0,y)))[1]
        fig.text(.02,yp,label,va='center')
        fig.text(.99,yp,f'{bb:.3f} ({bb-1.96*ss:.3f}, {bb+1.96*ss:.3f})',ha='right',va='center')
fig.text(.5,.035,'Index coefficient per 100 units of the respective exposure measure',ha='center',fontsize=11)
save(fig,10)
print('Nine data-derived figures saved in PNG and vector PDF.')
