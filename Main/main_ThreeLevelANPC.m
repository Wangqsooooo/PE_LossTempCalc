filename = 'ThreeLevel_ANPC.txt';
topology = Topology('Filename', filename);
% Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
Vdc = 600;
cload = Load(Vdc, 30000, 0.02, 150e-6, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
waves = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
% h = figure(1);
% h = waves.Output_Waves_Display(h);
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device Si_IGBT.device Si_IGBT.device];
parallel_nums = [3 6 6 3 3 3]; % 3 .* ones(1, topology.Nums); % 器件并联个数
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage);
% losses.Temperature_Losses_Calc(0.1);
losses.JunctionTemperatureSet(85);
losses.Conduction_Losses_Calc();
losses.Switching_Losses_Calc();
