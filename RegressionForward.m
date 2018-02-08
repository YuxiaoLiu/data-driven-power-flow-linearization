function [Xp, Xq, Xpf, Xqf, Xpt, Xqt] =...
    RegressionForward(regression, num_load, data, address, case_name)
% this function conduct the forward regression by calling different regressioin algorithms
switch regression
    case 0 % ordinary least squares
        for i = 1:num_load 
            p = data.P(:, i);
            V_Va_p = [data.Va * pi / 180 data.V ones(size(data.V, 1), 1)];
            b = regress(p, V_Va_p);
            Xp(i, :) = b';
            q = data.Q(:, i);
            V_Va_q = [data.Va * pi / 180 data.V ones(size(data.V, 1), 1)];
            b = regress(q, V_Va_q);
            Xq(i, :) = b';
        end

        Xpf = [];
        Xqf = [];
        Xpt = [];
        Xqt = [];
    case 1 % partial least squares
        k = rank(data.V) + rank(data.Va);
        k = min(k, size(data.P,1)-1);
        X_pls = [data.Va * pi / 180 data.V];
        Y_p_pls = data.P;
        [~,~,~,~,Xp] = plsregress(X_pls, Y_p_pls, k);
        Xp = Xp';
        temp = Xp(:,1);Xp(:,1) = [];Xp = [Xp temp];

        Y_q_pls = data.Q;
        [~,~,~,~,Xq] = plsregress(X_pls, Y_q_pls, k);
        Xq = Xq';
        temp = Xq(:,1);Xq(:,1) = [];Xq = [Xq temp];

        Xpf = [];
        Xqf = [];
        Xpt = [];
        Xqt = [];
    case 2 % bayesian linear regression
        threshold = 10000;
        X = [data.Va * pi / 180 data.V];
        Y = [data.P data.Q];
        X_blr = BayesianLR_python( X,Y ,threshold, address, case_name);
        [row, ~] = size(X_blr);
        row = row/2;
        Xp = X_blr(1:row, :);
        Xq = X_blr(row + 1:2 * row, :);
        Xpf = [];
        Xqf = [];
        Xpt = [];
        Xqt = [];
    otherwise
        error('no such regression method');
end
