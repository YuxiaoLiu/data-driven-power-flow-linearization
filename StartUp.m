% The algorithm in this file is based on the following publications: 
% Liu Y, Zhang N, Wang Y, et al. Data-Driven Power Flow Linearization: A Regression Approach. IEEE Transactions on Smart Grid, 2018.
% This is the start up m-file of the data-driven power flow linearization master
clc;
clear;
%% define parameters
generate_data = 1;%1,data generation is needed; 0,data is already generated
generate_test_data = 1;%1,data generation is needed; 0,data is already generated
upper_bound = 1.2;%upper bound of generated load
lower_bound = 0.8;%lower bound of generated load
regression = 1; %0-least squares 1-pls regression 2-bayesian linear regression 
for_or_inv = 1;% 0-forward regression;1-inverse regression 

G_range = 0.1; %range of power generation variations
Q_range = 0.25; %range of Q variations
Q_per = 0.2; %Q percentage on P
V_range = 0.01; %range of voltage magnitude variations of PV buses
L_range = 0.05; %range of load in different nodes
L_corr = 0.9; %covariance
Va_range = 7;%degree
Va_num = [];
dc_ac = 1; %0-dc;1-ac;
random_load = 1; %1,random 0,not random with bounder 2,not random with covariance

data_size = 500;% training data size
data_size_test = 300;% testing data size
case_name = 'case5';
address = '';% address to read and save the data filess

%%  training data generation
data_name = [address case_name '_training_data'];
if (generate_data)
    mpc = ext2int(loadcase(case_name));
    [ref, pv, pq] = bustypes(mpc.bus, mpc.gen);
    DataGeneration(case_name, Q_per, data_name, dc_ac, G_range, ...
        upper_bound, lower_bound, Q_range, V_range, data_size, L_range, ...
        random_load, Va_range, ref, L_corr);      
end
load([data_name,'.mat']);

%%  linear regression
%  get bus index lists of each type of bus
mpc = ext2int(loadcase(case_name));
[ref, pv, pq] = bustypes(mpc.bus, mpc.gen);

[Xp_dlpf, Xq_dlpf,~, ~, ~] = DLPF(mpc);
Xp_dlpf = full(Xp_dlpf);
Xq_dlpf = full(Xq_dlpf);

if (for_or_inv == 0)
    [Xp, Xq, Xpf, Xqf, Xpt, Xqt] =...
        RegressionForward(regression, num_load, data, address, case_name);
else 
    [Xva, Xv, Xpf, Xqf] =...
        RegressionInverse(regression, num_load, data, ref, address, case_name);
end

%% generate testing data
upper_bound = 1.2;
lower_bound = 0.8;
data_name = [address case_name '_testing_data'];
if (generate_test_data)
    DataGeneration(case_name, Q_per, data_name, dc_ac, G_range,...
        upper_bound, lower_bound, Q_range, V_range, data_size_test, L_range, ...
        random_load, Va_range, ref, L_corr); 
end
load([data_name,'.mat']);
num_train = size(data.P, 1);

%% verify the accuracy
if (for_or_inv == 0)
    [delta, test] = ...
        TestAccuracyForward(num_train, data, Xp, Xq, Xp_dlpf, Xq_dlpf, B);
else
    [ref, pv, pq] = bustypes(mpc.bus, mpc.gen);
    [data, delta] = ...
        TestAccuracyInverse(num_train, data, Xv, Xva, ref, pv, pq, num_load);
end
