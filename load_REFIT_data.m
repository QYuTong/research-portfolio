function [load_profiles, pv_profiles] = load_REFIT_data(date_str)
% load_REFIT_data - Load 1-minute resolution data of the REFIT project
% 
% Input:
%   date_str - Date string，For example '2014-07-24'
% 
% Output:
%   load_profiles - Load curve [time, P(kW), Q(kVar)] (1440 lines, 24 hours × 60 minutes)
%   pv_profiles   - PV Output Curve [time, Irradiance(W/m²), Temperature(°C), P(kW)]

%% Configuration
data_folder = 'data/REFIT/';
if nargin < 1
    date_str = '2014-07-24';  % Dates used in the paper
end

fprintf('Loading REFIT data: %s...\n', date_str);

%% Load load data
% REFIT House 1 Data Format: [timestamp, P(W), Q(VAr)]
load_file = fullfile(data_folder, sprintf('House_1_%s.csv', date_str));

if ~exist(load_file, 'file')
    warning('REFIT data file not found, generating simulated data');
    load_profiles = generate_synthetic_load();
    pv_profiles = generate_synthetic_pv();
    return;
end

% Read CSV
data = readtable(load_file);
time_vec = data.Timestamp;
P_load = data.ActivePower / 1000;  % W -> kW
Q_load = data.ReactivePower / 1000; % VAr -> kVar

% Application Diversity Coefficient
diversity_factor = 0.85;
P_load = P_load * diversity_factor;
Q_load = Q_load * 0.75;  % Reactive Diversity Factor

load_profiles = [datenum(time_vec), P_load, Q_load];

%% Loading PV Data
% Irradiance and temperature data
pv_file = fullfile(data_folder, sprintf('Solar_%s.csv', date_str));

if exist(pv_file, 'file')
    pv_data = readtable(pv_file);
    irradiance = pv_data.Irradiance;  % W/m²
    temperature = pv_data.Temperature; % °C
    
    %Calculate PV Output (Simplified Model)
    % P_pv = η × A × G × [1 - β(T - 25)]
    eta = 0.18;  % Efficiency
    area = 1111; % 200 kW system area (m²)
    beta = 0.004; % Temperature coefficient
    
    P_pv = eta * area * irradiance .* (1 - beta * (temperature - 25)) / 1000; % kW
    P_pv = max(0, min(P_pv, 200)); % Limit to 0-200kW
    
    pv_profiles = [datenum(pv_data.Timestamp), irradiance, temperature, P_pv];
else
    pv_profiles = generate_synthetic_pv();
end

fprintf('Data loading complete: %d data point\n', size(load_profiles, 1));

end

%% Subroutine: Generate Simulated Data
function load_profiles = generate_synthetic_load()
    %24 hours, 1-minute intervals
    t = (0:1439)' / 60;  % hour
    
    % Typical daily load curve
    P_base = 50;  % Baseload kW
    P_peak = 150; % Peak load kW
    
    % Double-peak load curve
    P = P_base + (P_peak - P_base) * (...
        0.3 * exp(-((t-8).^2)/4) + ...    % Morning peak
        0.7 * exp(-((t-19).^2)/6));       % Evening peak
    
    Q = P * 0.5;  % Power factor is about 0.9
    
    % Add random fluctuations
    P = P .* (1 + 0.1 * randn(size(P)));
    Q = Q .* (1 + 0.15 * randn(size(Q)));
    
    load_profiles = [(0:1439)', P, Q];
end

function pv_profiles = generate_synthetic_pv()
    % 24 hours, 1-minute intervals
    t = (0:1439)' / 60;  % hour
    
    % Clear Sky Irradiance Curve (Gaussian Type)
    G = 900 * exp(-((t-13).^2)/20);  % W/m²
    G(t < 6 | t > 20) = 0;  % No irradiation at night
    
    % Cloud cover effect (around 14:10)
    cloud_effect = ones(size(t));
    cloud_idx = (t > 14.1 & t < 14.3);
    cloud_effect(cloud_idx) = 0.3;
    
    G = G .* cloud_effect;
    
    % Temperature curve
    T = 15 + 10 * exp(-((t-14).^2)/25);
    
    % PV output
    P_pv = 0.18 * 1111 * G .* (1 - 0.004 * (T - 25)) / 1000;
    P_pv = max(0, min(P_pv, 200));
    
    pv_profiles = [(0:1439)', G, T, P_pv];
end
