function [delta, test] = ...
    TestAccuracyForward(num_train, data, Xp, Xq, Xp_dlpf, Xq_dlpf, B)
% this function test the accuracy of forward regression
%% calculate the results by data-driven linearized equations
for i = 1:num_train
    test.p.fitting(i, :) = [data.Va(i,:) * pi / 180 data.V(i,:) 1] * Xp';
    test.p.dcpf(i, :) = B * data.Va(i, :)' * pi / 180;
    test.p.dlpf(i, :) = [data.Va(i,:) * pi / 180 data.V(i,:)]*Xp_dlpf';
    test.q.fitting(i, :) = [data.Va(i,:) * pi / 180 data.V(i,:) 1]*Xq';
    test.q.dlpf(i, :) = [data.Va(i,:) * pi / 180 data.V(i,:)]*Xq_dlpf';
end

%% calculate the errors, note that the value of nan or inf is removed
temp = abs((data.P - test.p.fitting)./data.P);
temp(find(isnan(temp)==1)) = [];
temp(find(isinf(temp)==1)) = [];
delta.p.fitting = mean(mean(temp)) * 100;

temp = abs((data.P - test.p.dcpf)./data.P);
temp(find(isnan(temp)==1)) = [];
temp(find(isinf(temp)==1)) = [];
delta.p.dcpf = mean(mean(temp)) * 100;

temp = abs((data.P - test.p.dlpf)./data.P);
temp(find(isnan(temp)==1)) = [];
temp(find(isinf(temp)==1)) = [];
delta.p.dlpf = mean(mean(temp)) * 100;

temp = abs((data.Q - test.q.fitting)./data.Q);
temp(find(isnan(temp)==1)) = [];
temp(find(isinf(temp)==1)) = [];
delta.q.fitting = mean(mean(temp)) * 100;

temp = abs((data.Q - test.q.dlpf)./data.Q);
temp(find(isnan(temp)==1)) = [];
temp(find(isinf(temp)==1)) = [];
delta.q.dlpf = mean(mean(temp)) * 100;
