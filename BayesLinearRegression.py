# -*- coding: utf-8 -*-
"""
Created on Wed Apr  5 14:25:50 2017

@author: Yuxiao Liu
"""

import numpy as np
from sklearn.linear_model import ARDRegression
import pandas as pd

def bayeslr_python(fname, threshold):
# this function conducts the bayesian linear regression
# the data interaction from matlab is through excel files due to the restriction of matrix interation
    X = pd.read_excel(fname, sheetname=0, header=None, index=None)
    Y = pd.read_excel(fname, sheetname=1, header=None, index=None)
    X_row,X_col = X.shape
    Y_row,Y_col = Y.shape
    
    judge_Y = ~(pd.DataFrame.sum(Y, axis=0) == np.zeros(Y_col))
    
    X_blr = np.zeros((Y_col,X_col+1))
    sigma_blr = np.zeros((Y_col,X_col))
    
    for i in range(0,Y_col):
        if judge_Y[i]:
            y = Y.ix[:,i]
            clf = ARDRegression()
    #            clf.n_iter = 500
            clf.threshold_lambda = threshold
            
            clf.fit(X, y)
            coef = clf.coef_.T
            X_blr[i, :] = np.hstack((coef,clf.intercept_))
    
    X_blr = pd.DataFrame(X_blr)
    with pd.ExcelWriter(fname) as writer:
        X_blr.to_excel(writer, sheet_name=str(0), index=None, header=None)
