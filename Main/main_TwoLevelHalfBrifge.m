filename = 'TwoLevel_HalfBridge.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc�����������������ֱ����ѹ��ȥ���ֱ����ѹ
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load��matlab�Ĺؼ���, ����cload
waves = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.TwoLevel_SPWM);
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
% h = figure(1);
% h = waves.Output_Waves_Display(h);
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
devices = [SiC_MOSFET.device SiC_MOSFET.device];
parallel_nums = [2 2]; % ������������
Switching_Voltage = [Vdc Vdc];
Rg = [5, 5; 5, 5];
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, Rg);
losses.Conduction_Losses_Calc();
losses.Switching_Losses_Calc();
