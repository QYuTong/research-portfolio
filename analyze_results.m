%% analyze_results.m 
% Usage:Detailed analysis and visualization of simulation results
% Run: analyze_results('results/simulation_results_xxx.mat')
%      or analyze_results (Automatically load the latest results)

function analyze_results(result_file)

%% 1. Load result file
if nargin < 1
    %Automatically find the latest result file
    files = dir('results/simulation_results_*.mat');
    if isempty(files)
        error('Result file not found, please run the simulation first');
    end
    [~, idx] = max([files.datenum]);
    result_file = fullfile('results', files(idx).name);
    fprintf('Automatically load the latest results: %s\n', files(idx).name);
end

load(result_file);
load('IEEE33_parameters.mat');

fprintf('\n========================================\n');
fprintf('  IEEE 33-Node System Result Analysis\n');
fprintf('========================================\n\n');

%% 2.Voltage Analysis
if isfield(results, 'bus_voltages')
    fprintf('[1] Voltage Analysis\n');
    fprintf('----------------------------------------\n');
    
    % Extract steady-state value
    steady_start = round(0.9 * length(results.time));
    V_steady = mean(results.bus_voltages(steady_start:end, :), 1);
    
    % Statistics
    fprintf('Minimum Voltage: %.4f p.u. (node %d)\n', ...
            min(V_steady), find(V_steady == min(V_steady), 1));
    fprintf('Maximum voltage: %.4f p.u. (node %d)\n', ...
            max(V_steady), find(V_steady == max(V_steady), 1));
    fprintf('Average voltage: %.4f p.u.\n', mean(V_steady));
    fprintf('Voltage deviation: %.4f p.u.\n', max(abs(V_steady - 1.0)));
    
    % Low-voltage node
    low_voltage_nodes = find(V_steady < 0.95);
    if ~isempty(low_voltage_nodes)
        fprintf(' Low Voltage Node (<0.95 p.u.): %s\n', ...
                mat2str(low_voltage_nodes));
    else
        fprintf(' All node voltages are within the normal range\n');
    end
    
    %% Voltage curve chart
    figure('Name', 'Voltage Analysis', 'Position', [100 100 1200 800]);
    
    % Subfigure 1: Steady-state voltage distribution
    subplot(2,2,1);
    plot(1:length(V_steady), V_steady, '-o', 'LineWidth', 2, 'MarkerSize', 6);
    hold on;
    yline(1.0, 'k--', 'LineWidth', 1.5);
    yline(0.95, 'r--', 'LineWidth', 1, 'Alpha', 0.5);
    yline(1.05, 'r--', 'LineWidth', 1, 'Alpha', 0.5);
    grid on;
    xlabel('Node Number', 'FontSize', 12);
    ylabel('Voltage (p.u.)', 'FontSize', 12);
    title('Steady-state voltage distribution', 'FontSize', 14, 'FontWeight', 'bold');
    xlim([1 33]);
    ylim([min(V_steady)-0.02, max(V_steady)+0.02]);
    legend('Node Voltage', 'Nominal value', '±5% Limit value', 'Location', 'best');
    
    % Subfigure 2: Timeline（Select a few key points）
    subplot(2,2,2);
    key_nodes = [1, 18, 33];  % head end、Middle、end
    plot(results.time, results.bus_voltages(:, key_nodes), 'LineWidth', 2);
    grid on;
    xlabel('time (s)', 'FontSize', 12);
    ylabel('voltage (p.u.)', 'FontSize', 12);
    title('Critical node voltage time history', 'FontSize', 14, 'FontWeight', 'bold');
    legend(arrayfun(@(x) sprintf('node %d', x), key_nodes, 'UniformOutput', false), ...
           'Location', 'best');
    
    % Subfigure 3: Voltage Deviation Histogram
    subplot(2,2,3);
    voltage_deviation = abs(V_steady - 1.0) * 100;
    bar(voltage_deviation, 'FaceColor', [0.3 0.6 0.9]);
    grid on;
    xlabel('Node Number', 'FontSize', 12);
    ylabel('Voltage deviation (%)', 'FontSize', 12);
    title('Voltage deviation at each node', 'FontSize', 14, 'FontWeight', 'bold');
    xlim([0 34]);
    
    % Subfigure 4: Network Topology Voltage Heatmap
    subplot(2,2,4);
    % Simplified Topology Visualization
    [~, sorted_idx] = sort(V_steady);
    imagesc(reshape(V_steady(sorted_idx), [], 1)');
    colorbar;
    colormap(jet);
    title('Voltage Level Heatmap (Sorted)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Voltage level');
    set(gca, 'XTick', []);
    
    fprintf('\n');
end

%% 3. Power Loss Analysis
if isfield(results, 'line_currents') && isfield(results, 'power_flow')
    fprintf('[2] Power Loss Analysis\n');
    fprintf('----------------------------------------\n');
    
    % Power Loss Analysis
    I_steady = mean(abs(results.line_currents(steady_start:end, :)), 1);
    
    % Loss on each line P_loss = 3 * I^2 * R
    line_losses = zeros(size(line_data, 1), 1);
    for i = 1:size(line_data, 1)
        R_ohm = line_data(i, 3);
        line_losses(i) = 3 * I_steady(i)^2 * R_ohm / 1000;  % kW
    end
    
    total_loss = sum(line_losses);
    total_load = sum(load_data(:, 2));
    loss_percentage = (total_loss / total_load) * 100;
    
    fprintf('Total Power Loss: %.2f kW\n', total_loss);
    fprintf('Total Load Power: %.2f kW\n', total_load);
    fprintf('Loss Ratio: %.2f%%\n', loss_percentage);
    
    % Find the line with the highest loss
    [max_loss, max_loss_line] = max(line_losses);
    fprintf('Maximum line loss: %.2f kW (Route %d-%d)\n', ...
            max_loss, line_data(max_loss_line, 1), line_data(max_loss_line, 2));
    
    %% Loss Analysis Chart
    figure('Name', 'Power Loss Analysis', 'Position', [150 150 1200 600]);
    
    % Subfigure 1: Line Loss Distribution
    subplot(1,2,1);
    bar(line_losses, 'FaceColor', [0.9 0.3 0.3]);
    grid on;
    xlabel('Line Number', 'FontSize', 12);
    ylabel('Power loss (kW)', 'FontSize', 12);
    title('Power loss of each line', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Subfigure 2: Loss Pie Chart
    subplot(1,2,2);
    % Select the top 10 lines with the highest losses
    [sorted_losses, sorted_idx] = sort(line_losses, 'descend');
    top10_losses = sorted_losses(1:min(10, length(sorted_losses)));
    other_losses = sum(sorted_losses(11:end));
    
    pie_data = [top10_losses; other_losses];
    pie_labels = [arrayfun(@(x) sprintf('Line %d', sorted_idx(x)), ...
                           1:length(top10_losses), 'UniformOutput', false), ...
                  {'Other Routes'}];
    pie(pie_data);
    legend(pie_labels, 'Location', 'bestoutside', 'FontSize', 10);
    title('Power Loss Distribution', 'FontSize', 14, 'FontWeight', 'bold');
    
    fprintf('\n');
end

%% 4. Load Flow Analysis
fprintf('[3] Trend Analysis\n');
fprintf('----------------------------------------\n');

% Calculate the power flow of each branch
branch_flow = zeros(size(line_data, 1), 1);
for i = 1:size(line_data, 1)
    from_bus = line_data(i, 1);
    to_bus = line_data(i, 2);
    
    % Find all downstream loads
    downstream_loads = find(load_data(:, 1) >= to_bus);
    branch_flow(i) = sum(load_data(downstream_loads, 2));
end

fprintf('Maximum branch power flow: %.2f kW (Route %d-%d)\n', ...
        max(branch_flow), line_data(find(branch_flow == max(branch_flow), 1), 1:2));
fprintf('Average Branch Power Flow: %.2f kW\n', mean(branch_flow));

%% Trend Distribution Map
figure('Name', 'Trend Analysis', 'Position', [200 200 1000 600]);
plot(branch_flow, '-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('Branch Number', 'FontSize', 12);
ylabel('Active power (kW)', 'FontSize', 12);
title('Branch Power Flow Distribution', 'FontSize', 14, 'FontWeight', 'bold');

%% 5. Generate Report
fprintf('\n========================================\n');
fprintf(' Generate Report\n');
fprintf('========================================\n');
fprintf('The chart has been generated, please check it.Figure 窗口\n');
fprintf('Detailed data has been saved in: %s\n', result_file);
fprintf('\n');

%% 6. Export Report (Optional)
% Generate PDF Report
% print(gcf, '-dpdf', 'results/analysis_report.pdf');

end
