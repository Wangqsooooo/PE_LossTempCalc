filename = 'ThreeLevel_ANPC.txt';
Topology_Data = importdata(filename);
index = cellfun(@(x) strcmp(x, 'V'), Topology_Data.textdata(:, 3));
Vdc = 800; % �����ֱ����ĸ�ߵ�ѹ
Topology_Data.data = Vdc ./ 2 .* index + Topology_Data.data .* ~index;
topology = Topology('Data', Topology_Data);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc�����������������ֱ����ѹ��ȥ���ֱ����ѹ
cload = Load(Vdc, 30e3, 0.02, 150e-6, 400, 100e3, 100, 1, 'PF', 0.9524); % load��matlab�Ĺؼ���, ����cload
waves = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
% h = figure(1);
% h = waves.Output_Waves_Display(h);
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device Si_IGBT.device Si_IGBT.device];
parallel_nums = [3 6 6 3 3 3]; % 3 .* ones(1, topology.Nums); % ������������
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
Rg = [4, 23; 5, 5; 5, 5; 4, 23; 4, 23; 4, 23];
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, Rg);
losses.Temperature_Losses_Calc(0.1);
% losses.JunctionTemperatureSet(85);
% losses.Conduction_Losses_Calc();
% losses.Switching_Losses_Calc();
