function [data, delta] = ...
        TestAccuracyInverse(num_train, data, Xv, Xva, ref, pv, pq, num_load)
% this function test the accuracy of inverse regression
% note that the regression matrix is reordered
%   |Va_pq |    |         ||P_pq |    |  |
%   |Va_pv |    |X11  X12 ||P_pv |    |C1|
%   |P_ref |    |         ||1    |    |  |
%   |V_pq  | =  |         ||Q_pq | +  |  |
%   |      |    |         ||     |    |  |
%   |V_pv  |    |X21  X22 ||Q_pv |    |C2|
%   |V_ref |    |         ||Q_ref|    |  |
%   Y = X * a
X11 = [Xva([pq; pv; ref], [pq; pv; ref; pq + num_load]);...
    Xv(pq, [pq; pv; ref; pq + num_load])];
X12 = [Xva([pq; pv; ref], [pv; ref] + num_load);...
    Xv(pq, [pv; ref] + num_load)];
X21 = Xv([pv; ref], [pq; pv; ref; pq + num_load]);
X22 = Xv([pv; ref], [pv; ref] + num_load);
C1 = [Xva([pq; pv; ref],2*num_load + 1);Xv(pq,2*num_load + 1)];
C2 = Xv([pv; ref],2*num_load + 1);

P = data.P;
P(:, ref) = data.Va(:, ref);
Va = data.Va;
Va(:, ref) = data.P(:, ref);

%% calculate the results by data-driven linearized equations
for i = 1:num_train
    Y2 = data.V(i, [pv; ref])';
    a1 = [P(i, [pq; pv; ref])'; data.Q(i, pq)'];
    a2 = X22 \ (Y2 - X21 * a1 - C2);
    
    num_pq = size(pq,1);
    num_pv = size(pv,1);
    Q_pv = a2(1:num_pv);
    Q_ref = a2(num_pv + 1:num_pv + 1);
    
    Y1 = X11 * a1 + X12 * a2 + C1;

    
    V = zeros(num_load, 1);
    Va = zeros(num_load, 1);
    Q = data.Q(i, :);
    V([pv; ref]) = data.V(i, [pv; ref]);
    V(pq) = Y1(num_load + 1: num_load + num_pq);
    Va(ref) = data.Va(i, ref);
    Va([pq; pv]) = Y1(1: num_pq + num_pv) / pi * 180;
    P(i, ref) = Y1(num_pq + num_pv + 1);
    Q([pv; ref]) = [Q_pv; Q_ref]';
    
    data.V_fitting(i, :) = V';
    data.Va_fitting(i, :) = Va';
    data.P_fitting(i, :) = P(i, :);
    data.Q_fitting(i, :) = Q;
end

%% calculate the errors, note that the value of nan or inf is removed
    temp = abs((data.Va - data.Va_fitting));
    temp(find(isnan(temp)==1)) = [];
    temp(find(isinf(temp)==1)) = [];
    delta.va.fitting = mean(mean(temp));
    
    temp = abs((data.V(:,pq) - data.V_fitting(:,pq)));
    temp(find(isnan(temp)==1)) = [];
    temp(find(isinf(temp)==1)) = [];
    delta.v.fitting = mean(mean(temp));
    
    temp = abs((data.Va - data.Va_dlpf));
    temp(find(isnan(temp)==1)) = [];
    temp(find(isinf(temp)==1)) = [];
    delta.va.dlpf = mean(mean(temp));
    
    temp = abs((data.V(:,pq) - data.V_dlpf(:,pq)));
    temp(find(isnan(temp)==1)) = [];
    temp(find(isinf(temp)==1)) = [];
    delta.v.dlpf = mean(mean(temp));
    
    temp = abs((data.PF - data.PF_dc)./data.PF);
    temp(find(isnan(temp)==1)) = [];
    temp(find(isinf(temp)==1)) = [];
    delta.pf.dcpf = mean(mean(temp)) * 100;
    
    temp = abs((data.PF - data.PF_dlpf)./data.PF);
    temp(find(isnan(temp)==1)) = [];
    temp(find(isinf(temp)==1)) = [];
    delta.pf.dlpf = mean(mean(temp)) * 100;

end
    