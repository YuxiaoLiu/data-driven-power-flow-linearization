function [Xva, Xv, Xpf, Xqf] =...
        RegressionInverse(regression, num_load, data, ref, address ,case_name, is_sigma)
% this function conduct the inverse regression by calling different regressioin algorithms
switch regression
	case 0 % ordinary least squares
		for i = 1:num_load 
			P = data.P;
			P(:, ref) = zeros;
			PQ_va = [P data.Q ones(size(data.V, 1), 1)];
			[b,~,~,~,~] = regress(data.Va(:, i) * pi / 180, PQ_va);
			Xva(i, :) = b';
			[b,~,~,~,~] = regress(data.V(:, i), PQ_va);
			Xv(i, :) = b';
		end
		Xpf = [];
		Xqf = [];
	case 1 % partial least squares
		P = data.P;
		P(:, ref) = zeros;
		k = rank(P) + rank(data.Q) + 1;
		k = min(k, size(data.P, 1) - 1);
		X_pls = [P data.Q];
		Y_va_pls = data.Va  * pi / 180;
		Y_va_pls(:, ref) = data.P(:, ref);
		[~,~,~,~,Xva] = plsregress(X_pls, Y_va_pls, k);
		Xva = Xva';
		temp = Xva(:,1);Xva(:,1) = [];Xva = [Xva temp];

		Y_v_pls = data.V;
		[~,~,~,~,Xv] = plsregress(X_pls, Y_v_pls, k);
		Xv = Xv';
		temp = Xv(:,1);Xv(:,1) = [];Xv = [Xv temp];

		Y_pf_pls = data.PF;
		[~,~,~,~,Xpf] = plsregress(X_pls, Y_pf_pls, k);
		Xpf = Xpf';
		temp = Xpf(:,1);Xpf(:,1) = [];Xpf = [Xpf temp];

		Y_qf_pls = data.QF;
		[~,~,~,~,Xqf] = plsregress(X_pls, Y_qf_pls, k);
		Xqf = Xqf';
		temp = Xqf(:,1);Xqf(:,1) = [];Xqf = [Xqf temp];
	case 2 % bayesian linear regression
		threshold = 900000;
		P = data.P;
		P(:, ref) = zeros;
		X = [P data.Q];
		Y_va_pls = data.Va  * pi / 180;
		Y_va_pls(:, ref) = data.P(:, ref);
		Y_v_pls = data.V;
		Y = [Y_va_pls Y_v_pls];
		X_blr = BayesianLR_python( X,Y, threshold, address, case_name);
		
		[row, ~] = size(X_blr);
		row = row/2;
		Xva = X_blr(1:row, :);
		Xv = X_blr(row + 1:2 * row, :);

		Y_pf_pls = data.PF;
		Y_qf_pls = data.QF;
		Y = [Y_pf_pls Y_qf_pls];
		[X_blr] = BayesianLR_python( X,Y, threshold, address, case_name);
		
		[row, ~] = size(X_blr);
		row = row/2;
		Xpf = X_blr(1:row, :);
		Xqf = X_blr(row + 1:2 * row, :);
	otherwise
		error('no such regression method');
end
