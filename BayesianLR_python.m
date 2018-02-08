function [ X_blr ] = BayesianLR_python( X,Y,threshold, address, case_name)
% this function conduct the Bayesian linear regression by calling the python function

fname = 'bayesian_lr.xlsx';
fname = [address case_name '_' fname];

if (exist(fname, 'file') == 2)
    delete(fname)
end

sheet = 1;
xlswrite(fname, X, sheet)
sheet = 2;
xlswrite(fname, Y, sheet)
py.BayesLinearRegression.bayeslr_python(fname, threshold)
sheet = 1;
X_blr = xlsread(fname, sheet);

end

