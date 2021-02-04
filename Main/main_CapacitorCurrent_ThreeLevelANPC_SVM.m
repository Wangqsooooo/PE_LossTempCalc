filename = 'ThreeLevel_ANPC.txt';
topology = Topology('Filename', filename);
% Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
Vdc = 800;
cload = Load(Vdc, 30000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
waves_phaseA = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 0, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SVM);
% h = figure(4);
% [h, modulation, carrier, control] = waves.ThreeLevel_ANPC_SVM_Display(h, 0, 0.06, cload);
waves_phaseA.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseA.Output_Waves_Calc(topology.Path, cload);
% g = figure(5);
% g = waves.Output_Waves_Display(g);

waves_phaseB = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 2*pi/3, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SVM);
waves_phaseB.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseB.Output_Waves_Calc(topology.Path, cload);

waves_phaseC = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 4*pi/3, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SVM);
waves_phaseC.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseC.Output_Waves_Calc(topology.Path, cload);

NeutralPoint_Voltage = (waves_phaseA.Upwm + waves_phaseB.Upwm + waves_phaseC.Upwm) ./ 3;
waves_phaseA.Output_Waves_Calc(topology.Path, cload, 'Neutral', NeutralPoint_Voltage);
waves_phaseB.Output_Waves_Calc(topology.Path, cload, 'Neutral', NeutralPoint_Voltage);
waves_phaseC.Output_Waves_Calc(topology.Path, cload, 'Neutral', NeutralPoint_Voltage);

SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device Si_IGBT.device Si_IGBT.device];
parallel_nums = [3 6 6 3 3 3];
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
losses = Losses(waves_phaseA.T, waves_phaseA.Ts, waves_phaseA.OneCycleCurrent, waves_phaseA.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage);
% losses.Temperature_Losses_Calc(0.1);
losses.JunctionTemperatureSet(85);
losses.Conduction_Losses_Calc();
losses.Switching_Losses_Calc();
 
% Period = waves_phaseA.Period; T = waves_phaseA.T; Ts = waves_phaseA.Ts;
% current_phaseA = waves_phaseA.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
% current_phaseA = current_phaseA(round((Period-T)/Ts+1):round(Period/Ts+1));
% current_phaseB = waves_phaseB.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
% current_phaseB = current_phaseB(round((Period-T)/Ts+1):round(Period/Ts+1));
% current_phaseC = waves_phaseC.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
% current_phaseC = current_phaseC(round((Period-T)/Ts+1):round(Period/Ts+1));
% upper_cap = current_phaseA + current_phaseB + current_phaseC;
% 
% current_phaseA = waves_phaseA.Device_FlowingCurrent_Calc(4, topology.Path, 'Mode', 'Fundamental');
% current_phaseA = current_phaseA(round((Period-T)/Ts+1):round(Period/Ts+1));
% current_phaseB = waves_phaseB.Device_FlowingCurrent_Calc(4, topology.Path, 'Mode', 'Fundamental');
% current_phaseB = current_phaseB(round((Period-T)/Ts+1):round(Period/Ts+1));
% current_phaseC = waves_phaseC.Device_FlowingCurrent_Calc(4, topology.Path, 'Mode', 'Fundamental');
% current_phaseC = current_phaseC(round((Period-T)/Ts+1):round(Period/Ts+1));
% down_cap = current_phaseA + current_phaseB + current_phaseC;
% 
% h = figure(1); clf(h, 'reset'); hold on;
% plot(0:Ts:T, upper_cap);
% plot(0:Ts:T, down_cap);
% h = figure(2); clf(h, 'reset'); hold on;
% C = 500e-6;
% upper = cumsum((upper_cap-mean(upper_cap)) ./ (2*C) .* Ts);
% plot(0:Ts:T, upper);
% down = cumsum((down_cap-mean(down_cap)) ./ (2*C) .* Ts);
% plot(0:Ts:T, down);
