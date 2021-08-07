filename = 'ThreeLevel_ANPC.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(Vdc, 30000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
% phase A
waves_phaseA = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 0, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
waves_phaseA.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseA.Output_Waves_Calc(topology.Path, cload);
Period = waves_phaseA.Period; T = waves_phaseA.T; Ts = waves_phaseA.Ts;
% phase B
waves_phaseB = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 2*pi/3, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
waves_phaseB.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseB.Output_Waves_Calc(topology.Path, cload);
% phase C
waves_phaseC = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 4*pi/3, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
waves_phaseC.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseC.Output_Waves_Calc(topology.Path, cload);

current_phaseA = waves_phaseA.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
% current_phaseA = waves_phaseA.Device_FlowingCurrent_Calc(1, topology.Path);
current_phaseA = current_phaseA(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseB = waves_phaseB.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
% current_phaseB = waves_phaseB.Device_FlowingCurrent_Calc(1, topology.Path);
current_phaseB = current_phaseB(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseC = waves_phaseC.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
% current_phaseC = waves_phaseC.Device_FlowingCurrent_Calc(1, topology.Path);
current_phaseC = current_phaseC(round((Period-T)/Ts+1):round(Period/Ts+1));
upper_cap = current_phaseA + current_phaseB + current_phaseC;

current_phaseA1 = waves_phaseA.Device_FlowingCurrent_Calc(2, topology.Path, 'Mode', 'Fundamental');
current_phaseA1 = current_phaseA1(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseA2 = waves_phaseA.Device_FlowingCurrent_Calc(3, topology.Path, 'Mode', 'Fundamental');
current_phaseA2 = current_phaseA2(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseB1 = waves_phaseB.Device_FlowingCurrent_Calc(2, topology.Path, 'Mode', 'Fundamental');
current_phaseB1 = current_phaseB1(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseB2 = waves_phaseB.Device_FlowingCurrent_Calc(3, topology.Path, 'Mode', 'Fundamental');
current_phaseB2 = current_phaseB2(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseC1 = waves_phaseC.Device_FlowingCurrent_Calc(2, topology.Path, 'Mode', 'Fundamental');
current_phaseC1 = current_phaseC1(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseC2 = waves_phaseC.Device_FlowingCurrent_Calc(3, topology.Path, 'Mode', 'Fundamental');
current_phaseC2 = current_phaseC2(round((Period-T)/Ts+1):round(Period/Ts+1));
middle_cap = -current_phaseA1 + current_phaseA2 - current_phaseB1 + current_phaseB2 ...
    - current_phaseC1 + current_phaseC2;

current_phaseA = waves_phaseA.Device_FlowingCurrent_Calc(4, topology.Path, 'Mode', 'Fundamental');
current_phaseA = current_phaseA(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseB = waves_phaseB.Device_FlowingCurrent_Calc(4, topology.Path, 'Mode', 'Fundamental');
current_phaseB = current_phaseB(round((Period-T)/Ts+1):round(Period/Ts+1));
current_phaseC = waves_phaseC.Device_FlowingCurrent_Calc(4, topology.Path, 'Mode', 'Fundamental');
current_phaseC = current_phaseC(round((Period-T)/Ts+1):round(Period/Ts+1));
down_cap = current_phaseA + current_phaseB + current_phaseC; down_cap = -down_cap;

% 画图
h = figure(1); clf(h, 'reset'); hold on;
plot(0:Ts:T, upper_cap);
plot(0:Ts:T, down_cap);
h = figure(2); clf(h, 'reset'); hold on;
C = 500e-6;
upper = cumsum((upper_cap-mean(upper_cap)) ./ (2*C) .* Ts);
plot(0:Ts:T, upper);
h = figure(3); clf(h, 'reset'); hold on;
plot(0:Ts:T, middle_cap);
middle = cumsum(middle_cap ./ (2*C) .* Ts);
plot(0:Ts:T, middle);
