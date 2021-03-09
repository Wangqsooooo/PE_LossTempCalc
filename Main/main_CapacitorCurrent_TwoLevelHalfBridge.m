filename = 'TwoLevel_HalfBridge.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc�����������������ֱ����ѹ��ȥ���ֱ����ѹ
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load��matlab�Ĺؼ���, ����cload
% Phase A
waves_phaseA = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 0, 'Defined_Modulation', ModulationType.TwoLevel_SPWM);
waves_phaseA.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseA.Output_Waves_Calc(topology.Path, cload);
Period = waves_phaseA.Period; T = waves_phaseA.T; Ts = waves_phaseA.Ts;
current_phaseA = waves_phaseA.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
current_phaseA = current_phaseA(round((Period-T)/Ts+1):round(Period/Ts+1));
% Phase B
waves_phaseB = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 2*pi/3, 'Defined_Modulation', ModulationType.TwoLevel_SPWM);
waves_phaseB.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseB.Output_Waves_Calc(topology.Path, cload);
current_phaseB = waves_phaseB.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
current_phaseB = current_phaseB(round((Period-T)/Ts+1):round(Period/Ts+1));
% Phase C
waves_phaseC = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 4*pi/3, 'Defined_Modulation', ModulationType.TwoLevel_SPWM);
waves_phaseC.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseC.Output_Waves_Calc(topology.Path, cload);
current_phaseC = waves_phaseC.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
current_phaseC = current_phaseC(round((Period-T)/Ts+1):round(Period/Ts+1));

h = figure(1); clf(h, 'reset');
plot(0:Ts:T, current_phaseA+current_phaseB+current_phaseC);
h = figure(2); clf(h, 'reset');
Cap_current = current_phaseA+current_phaseB+current_phaseC - ...
    mean(current_phaseA+current_phaseB+current_phaseC);
C = 500e-6;
Cap_voltage = cumsum(Cap_current ./ C .* Ts);
plot(0:Ts:T, Cap_voltage);
