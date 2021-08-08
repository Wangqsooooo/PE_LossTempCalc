filename = 'ThreeLevel_ANPC.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc�����������������ֱ����ѹ��ȥ���ֱ����ѹ
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load��matlab�Ĺؼ���, ����cload
% phase A
waves_phaseA = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 0, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_DualCurrentPath);
waves_phaseA.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseA.Output_Waves_Calc(topology.Path, cload);
Period = waves_phaseA.Period; T = waves_phaseA.T; Ts = waves_phaseA.Ts;
% phase B
waves_phaseB = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 2*pi/3, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_DualCurrentPath);
waves_phaseB.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseB.Output_Waves_Calc(topology.Path, cload);
% phase C
waves_phaseC = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', 4*pi/3, 'Defined_Modulation', ModulationType.ThreeLevel_ANPC_DualCurrentPath);
waves_phaseC.ShortCircuit_Check(topology.HB_Restriction);
waves_phaseC.Output_Waves_Calc(topology.Path, cload);
% ��ļ���
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
SiC_MOSFET.device.Zthch = {[0.197000000000000 0.01]};
Si_IGBT.device.Zthch = {[0.197000000000000 0.01]};
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device Si_IGBT.device Si_IGBT.device];
parallel_nums = 3 .* ones(1, topology.Nums); % ������������
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
Rg = [4, 23; 5, 5; 5, 5; 4, 23; 4, 23; 4, 23];
losses_phaseA = Losses(waves_phaseA.T, waves_phaseA.Ts, waves_phaseA.OneCycleCurrent, waves_phaseA.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, Rg);
losses_phaseB = Losses(waves_phaseB.T, waves_phaseB.Ts, waves_phaseB.OneCycleCurrent, waves_phaseB.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, Rg);
losses_phaseC = Losses(waves_phaseC.T, waves_phaseC.Ts, waves_phaseC.OneCycleCurrent, waves_phaseC.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, Rg);
Zthha = {[0.1, 0.01]};
tic
losses_phaseA.Temperature_Losses_Calc(Zthha, 'ThreePhase', 'CalcMode', 'RealTime', 'PhaseB', losses_phaseB, 'PhaseC', losses_phaseC);
toc
% ���Ƴ��뵼�������Ľ��²���
t = 0:losses_phaseA.Ts:(size(losses_phaseA.Tj_Dynamic(1, :),2)-1)*losses_phaseA.Ts;
plot(t, losses_phaseA.Tj_Dynamic(1, :));
