%% init_voltage_control.m
% Purpose: Initialize the IEEE 33-node UK standard system and load REFIT data
% Corresponding paper: Section II.A, II.B

clear; clc;
fprintf('========================================\n');
fprintf(' UK 11kV Distribution Network Voltage Control Simulation Initialization\n');
fprintf(' Based on the IEEE 33-bus + REFIT dataset\n');
fprintf('========================================\n\n');

%% 1. Loading system data
fprintf('[1/7] Load system topology and parameters...\n');
[bus_data, line_data, load_data, pv_data] = IEEE33_UK_data();
fprintf('  Bus: %d, Line: %d, PV Node: %d\n', ...
        size(bus_data,1), size(line_data,1), size(pv_data,1));

%% 2.Baseline Setting (Thesis Section II.A)
fprintf('\n[2/7] Set baseline value (UK 11kV standard)...\n');
Vbase = 11e3;         % 11 kV line voltage
Sbase = 1e6;          % 1 MVA Base Power
Ibase = Sbase/(sqrt(3)*Vbase);
Zbase = Vbase^2/Sbase;
freq = 50;            % 50 Hz

% Voltage Limit (ESQCR Regulation 6)
V_min = 0.94;         % 0.94 pu
V_max = 1.06;         % 1.06 pu
V_statutory_min = 0.94;
V_statutory_max = 1.05;  % Legal ceiling

fprintf('     ✓ Reference Voltage: %.2f kV\n', Vbase/1e3);
fprintf('     ✓ Rated Power: %.2f MVA\n', Sbase/1e6);
fprintf('     ✓ Voltage range: %.2f - %.2f pu\n', V_min, V_max);

%% 3. Convert to per-unit value
fprintf('\n[3/7] Per-unit parameter...\n');

% Line parameters
line_data_pu = line_data;
for i = 1:size(line_data, 1)
    R_total = line_data(i, 3) * line_data(i, 5);  % Ω
    X_total = line_data(i, 4) * line_data(i, 5);  % Ω
    line_data_pu(i, 3) = R_total / Zbase;
    line_data_pu(i, 4) = X_total / Zbase;
end

% Load parameters
load_data_pu = load_data;
load_data_pu(:, 2) = load_data(:, 2) * 1000 / Sbase;  % kW -> pu
load_data_pu(:, 3) = load_data(:, 3) * 1000 / Sbase;  % kVar -> pu

% PV parameters
pv_data_pu = pv_data;
pv_data_pu(:, 2) = pv_data(:, 2) * 1000 / Sbase;  % kW -> pu

fprintf('Average R/X ratio: %.3f\n', mean(line_data_pu(:,3)./line_data_pu(:,4)));

%% 4. Load REFIT data (Paper uses 2014-07-24)
fprintf('\n[4/7] Load REFIT project data...\n');
[load_profiles, pv_profiles] = load_REFIT_data('2014-07-24');
fprintf('Load data points: %d (24h, 1min resolution)\n', size(load_profiles,1));
fprintf('PV Peak Irradiance: %.0f W/m²\n', max(pv_profiles(:,2)));

%% 5. OLTC Parameters (Paper Section II.B(1))
fprintf('\n[5/7] Configure OLTC controller...\n');
oltc_config.V_nominal = 1.0;          % pu
oltc_config.tap_range = [-8, 8];      % ±5%, 17 gears, 0.625% per gear
oltc_config.tap_step = 0.00625;       % 0.625% per step
oltc_config.dead_band = 0.01;         % 1% dead zone
oltc_config.delay = 60;               % 60s delay (optimized parameters)
oltc_config.V_trigger_high = 1.03;    % Trigger Voltage (Optimized)
oltc_config.V_trigger_low = 0.97;
oltc_config.mech_delay = 5;           % Mechanical action delay 5s
oltc_config.blocking_time = 300;      % Anti-oscillation blocking time 300s
oltc_config.lifetime = 200000;        % Rated for 200,000 cycles

fprintf('Gear range: %d ~ +%d (%.2f%% per gear)\n', ...
        oltc_config.tap_range(1), oltc_config.tap_range(2), ...
        oltc_config.tap_step*100);
fprintf('Trigger Voltage: %.3f / %.3f pu\n', ...
        oltc_config.V_trigger_low, oltc_config.V_trigger_high);

%% 6. PV Inverter Q(U) Droop Parameter (EN 50549-1:2019)
fprintf('\n[6/7] Configure PV inverter Q(U) curve...\n');
inverter_config.Q_max = 0.33;         % ±0.33 pu (±66 kVAr @200kW)
inverter_config.V_points = [0.95, 0.98, 1.02, 1.05];  % pu
inverter_config.Q_points = [0.33, 0, 0, -0.33];       % pu
inverter_config.response_time = 0.5;   % 0.5s response time
inverter_config.droop_slope = 0.33 / 0.07;  % 4.71 pu/pu

fprintf( Q range: ±%.2f pu (±%.0f kVAr)\n', ...
        inverter_config.Q_max, inverter_config.Q_max * 200);
fprintf( Sag Slope: %.2f pu/pu\n', inverter_config.droop_slope);

%% 7. Simulation Parameters
fprintf('\n[7/7] Configure simulation environment...\n');
sim_params.stop_time = 86400;         % 24 hours = 86,400 seconds
sim_params.sample_time = 1;           % 1-second sampling
sim_params.solver = 'ode23tb';        % Rigid solver
sim_params.max_step = 0.5e-3;         % 0.5ms maximum step size
sim_params.rel_tol = 1e-4;            % Relative tolerance

fprintf('Simulation duration: %d s (24 hours)\n', sim_params.stop_time);
fprintf('Sampling time: %d s\n', sim_params.sample_time);
fprintf('Solver: %s\n', sim_params.solver);

%% 8. Save to workspace and file
fprintf('\nSaving parameters to file and workspace...\n');
save('data/IEEE33_UK_parameters.mat', ...
     'bus_data', 'line_data', 'load_data', 'pv_data', ...
     'line_data_pu', 'load_data_pu', 'pv_data_pu', ...
     'load_profiles', 'pv_profiles', ...
     'Vbase', 'Sbase', 'Zbase', 'Ibase', 'freq', ...
     'V_min', 'V_max', 'V_statutory_min', 'V_statutory_max', ...
     'oltc_config', 'inverter_config', 'sim_params');

% Load into the base workspace for Simulink use
vars_to_base = who;
for i = 1:length(vars_to_base)
    assignin('base', vars_to_base{i}, eval(vars_to_base{i}));
end

fprintf('Parameters saved\n');

%% 9. System Statistics
fprintf('\n========================================\n');
fprintf('  System Statistics \n');
fprintf('========================================\n');
total_P = sum(load_data(:, 2));
total_Q = sum(load_data(:, 3));
total_PV = sum(pv_data(:, 2));
penetration = (total_PV / (total_P)) * 100;

fprintf('Total Load Capacity: %.2f MW + j%.2f MVAr\n', total_P/1000, total_Q/1000);
fprintf('Total PV Capacity: %.2f MW\n', total_PV/1000);
fprintf('PV penetration rate: %.1f%%\n', penetration);
fprintf('Peak irradiance: %.0f W/m²\n', max(pv_profiles(:,2)));

fprintf('\n========================================\n');
fprintf('  Initialization complete！\n');
fprintf('  The following simulation scenarios can be run:\n');
fprintf('  - Case 1: Uncontrolled (run_case1_no_control)\n');
fprintf('  - Case 2: OLTC only (run_case2_oltc_only)\n');
fprintf('  - Case 3: Coordinated control (run_case3_coordinated)\n');
fprintf('========================================\n\n');
