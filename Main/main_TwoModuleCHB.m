tic
filename = 'TwoModule_CHB.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(Vdc, 8000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
waves = Waves(cload, topology.Nums, 0.06);
waves.SPWM_Config(cload.freq, cload.T, cload.ma, 0, [-1, 1], [1 2], 'SampleTech', 'Natural');
waves.SPWM_Config(cload.freq, cload.T, cload.ma, 0, [-1, 1], [4 3], ...
    'SampleTech', 'Natural', 'CarrierPhaseShift', pi);
waves.SPWM_Config(cload.freq, cload.T, cload.ma, 0, [-1, 1], [5 6], ...
    'SampleTech', 'Natural', 'CarrierPhaseShift', pi/2);
waves.SPWM_Config(cload.freq, cload.T, cload.ma, 0, [-1, 1], [8 7], ...
    'SampleTech', 'Natural', 'CarrierPhaseShift', 3*pi/2);
waves.ShortCircuit_Check(topology.HB_Restriction);
toc
waves.Output_Waves_Calc(topology.Path, cload);
h = figure(1);
h = waves.Output_Waves_Display(h);
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
devices = [Si_IGBT.device Si_IGBT.device Si_IGBT.device Si_IGBT.device ...
    Si_IGBT.device Si_IGBT.device, Si_IGBT.device,Si_IGBT.device];
parallel_nums = 3 .* ones(1, topology.Nums); % 器件并联个数
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage);
losses.JunctionTemperatureSet(100);
losses.Conduction_Losses_Calc();
losses.Switching_Losses_Calc();
