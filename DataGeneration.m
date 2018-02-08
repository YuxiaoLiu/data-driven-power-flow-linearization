function [] = ...
    DataGeneration(case_name, Q_per, data_name, dc_ac, G_range, ...
    upper_bound, lower_bound, Q_range, V_range, data_size, L_range, ...
    random_load, Va_range, ref, L_corr)
%   this function generates the data of P, Q, V, and theata
define_constants;

mpc = ext2int(loadcase(case_name));

num_load = size(mpc.bus, 1);
num_branch = size(mpc.branch, 1);
num_train = data_size;
%% generate the load based on the assumption that the load is random or is correlated
if (random_load == 1)
    load_index = rand([data_size, num_load]) * (upper_bound - lower_bound) ...
    + lower_bound * ones(data_size, num_load);
elseif (random_load == 0)
    load_index = rand([data_size, 1]) * (upper_bound - lower_bound) ...
        + lower_bound * ones(data_size, 1);
    load_index = load_index * ones(1, num_load) ...
        + rand([data_size, num_load]) * L_range;
else
    
end
X_load = load_index * diag(mpc.bus(:, PD)');
%%   data generation through power flow calculation, the Matpower Toolbox is required
data.P = zeros(num_train, num_load);
data.Va = zeros(num_train, num_load);
if(dc_ac)
    data.Q = zeros(num_train, num_load);
    data.V = zeros(num_train, num_load);
    data.Va_dc = zeros(num_train, num_load);
    data.P_dc = zeros(num_train, num_load);
end
gen_ini = mpc.gen(:, PG);
bus_ini = mpc.gen(:, VG);
for i = 1:num_train
    mpc.bus(:, PD) = X_load(i, :)';
    mpc.bus(:, QD) = mpc.bus(:, PD) .* (Q_per * ones(size(mpc.bus(:, QD))) ...
        + Q_range * rand(size(mpc.bus(:, QD))));
    mpc.gen(:, PG) = gen_ini + rand(size(mpc.gen(:, PG))) - 0.5 * ones(size(mpc.gen(:, PG))) * G_range;    
    mpc.gen(:, VG) = bus_ini + (rand(size(mpc.gen(:, VG))) - 0.5 * ones(size(mpc.gen(:, VG)))) * V_range;
	%% generate the data based on AC power flow equations or based on DC power flow equations
    if(dc_ac)
        [MVAbase, bus, gen, branch] = runpf(mpc);
        mpc.bus(:,VM) = bus(:,VM);
        [I2E, bus, gen, branch] = ext2int(bus, gen, branch);
        [MVAbase_dc, bus_dc, gen_dc, branch_dc] = rundcpf(mpc);
        [I2E, bus_dc, gen_dc, branch_dc] = ext2int(bus_dc, gen_dc, branch_dc);
        [~, ~, data.P_dlpf(i, :), data.PF_dlpf(i, :), data.Va_dlpf(i, :), data.V_dlpf(i, :)] = DLPF(mpc);
        data.Va_dc(i, :) = bus_dc(:, VA)';
        
        Sbus_dc = makeSbus(MVAbase_dc, bus_dc, gen_dc);
        data.P_dc(i, :) = real(Sbus_dc)';
        data.PF_dc(i, :) = branch_dc(:, PF)';
    else
        [MVAbase, bus, gen, branch] = rundcpf(mpc);
    end
	%% save the generation results into the data struct
    Sbus = makeSbus(MVAbase, bus, gen);
    data.P(i, :) = real(Sbus)';
    data.Q(i, :) = imag(Sbus)';
    data.V(i, :) = bus(:, VM)';
    data.Va(i, :) = bus(:, VA)';
    data.PF(i, :) = branch(:, PF)';
    data.PT(i, :) = branch(:, PT)';
    data.QF(i, :) = branch(:, QF)';
    data.QT(i, :) = branch(:, QT)';
end
B = makeBdc(MVAbase, bus, mpc.branch);
%% save to files
eval(['save ', data_name, ' data num_load num_branch B;']);
end

