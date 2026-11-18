"""Gaussian triangular IV-probit with a city-clustered score covariance."""
import numpy as np
import statsmodels.api as sm
from scipy.optimize import minimize
from scipy.special import log_ndtr
from statsmodels.tools.numdiff import approx_fprime

def fit_full_iv(data, exposure, controls, instruments, cluster):
    def standardize(value):
        return (value-value.mean())/value.std()
    X=sm.add_constant(standardize(controls.drop(columns='const'))).to_numpy()
    Z=np.column_stack([X,standardize(data[instruments])])
    end=standardize(data[exposure]).to_numpy()
    structural=np.column_stack([end,X])
    k=structural.shape[1]
    y=2*data.fair.to_numpy()-1
    first=np.linalg.lstsq(Z,end,rcond=None)[0]
    residual=end-Z@first
    sigma=np.sqrt(np.mean(residual**2))

    def parts(theta):
        sd=np.exp(theta[-1])
        error=(end-Z@theta[k+1:-1])/sd
        index=y*(structural@theta[:k]+theta[k]*error)
        return error,index,sd
    def scores(theta):
        error,index,sd=parts(theta)
        derivative=y*np.exp(-.5*index**2-.5*np.log(2*np.pi)-log_ndtr(index))
        return np.column_stack([structural*derivative[:,None],derivative*error,
            Z*((error-derivative*theta[k])/sd)[:,None],error**2-1-derivative*theta[k]*error])
    def objective(theta):
        error,index,sd=parts(theta)
        return np.mean(.5*error**2+np.log(sd)-log_ndtr(index)), -scores(theta).mean(axis=0)
    initial=sm.Probit(data.fair,np.column_stack([structural,residual/sigma])).fit(disp=False).params
    fit=minimize(objective,np.r_[initial,first,np.log(sigma)],jac=True,method='BFGS',options={'gtol':1e-9,'maxiter':500})
    if np.max(np.abs(fit.jac))>1e-6:
        raise RuntimeError('IV-probit score did not converge')
    theta=fit.x
    inverse=np.linalg.inv(approx_fprime(theta,lambda b:-scores(b).sum(axis=0),centered=True))
    groups=data[cluster].astype('category').cat.codes.to_numpy()
    group_scores=np.zeros((groups.max()+1,len(theta)))
    np.add.at(group_scores,groups,scores(theta))
    n_groups=len(group_scores)
    covariance=inverse@group_scores.T@group_scores@inverse.T*n_groups/(n_groups-1)

    labels=[exposure]+list(controls.columns)
    means=controls.drop(columns='const').mean().to_numpy()
    scales=controls.drop(columns='const').std().to_numpy()
    def coefficients(b):
        normalized=b[:k]/np.sqrt(1+b[k]**2)
        exposure_beta=normalized[0]/data[exposure].std()
        other_beta=normalized[2:]/scales
        intercept=normalized[1]-exposure_beta*data[exposure].mean()-other_beta@means
        return np.r_[exposure_beta,intercept,other_beta]
    gradient=approx_fprime(theta,coefficients,centered=True)
    estimates=coefficients(theta)
    ses=np.sqrt(np.diag(gradient@covariance@gradient.T))
    from scipy.stats import norm
    return {'n':len(data),'terms':{name:{'b':float(b),'se':float(se),'p':float(2*norm.sf(abs(b/se)))} for name,b,se in zip(labels,estimates,ses)}}
