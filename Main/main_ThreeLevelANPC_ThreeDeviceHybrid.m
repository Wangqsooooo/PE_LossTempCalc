% 三种器件的混合并联, 目的是为了SiC MOSFET + Si IGBT + SiC Diode混合并联用的
% 经过测试原来的程序可以直接使用
% 一个测试中将3 * SiC + 1 * Si + 1 * Si计算结果与 3 * SiC + 2 * Si计算结果进行比较
% 结果是完全一致的, 说明原来的程序是可以直接使用的
filename = 'ThreeLevel_ANPC_ThreeDeviceHybrid.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
waves = Waves(cload, topology.Nums, 0.06);
waves.ThreeLevel_ANPC_SingleCurrentPath(cload, 0, [1 2 3 4 5 6]);
delay = 1e-6;
shift1 = zeros(size(waves.Control(2, :))); shift2 = shift1;
shift1(1:end-1) = circshift(waves.Control(2, 1:end-1), round(delay/waves.Ts));
shift1(end) = waves.Control(2, end-round(delay/waves.Ts));
shift2(1:end-1) = circshift(waves.Control(2, 1:end-1), -round(delay/waves.Ts));
shift2(end) = waves.Control(2, 1+round(delay/waves.Ts));
waves.Control(7, :) = waves.Control(2, :)>0.5 & shift1>0.5 & shift2>0.5;
waves.Control(8, :) = waves.Control(7, :);
shift1(1:end-1) = circshift(waves.Control(3, 1:end-1), round(delay/waves.Ts));
shift1(end) = waves.Control(3, end-round(delay/waves.Ts));
shift2(1:end-1) = circshift(waves.Control(3, 1:end-1), -round(delay/waves.Ts));
shift2(end) = waves.Control(3, 1+round(delay/waves.Ts));
waves.Control(9, :) = waves.Control(3, :)>0.5 & shift1>0.5 & shift2>0.5;
waves.Control(10, :) = waves.Control(9, :);
waves.notify('ControlChanged'); % 由于是自己配置了一部分控制信号(7号和8号开关器件的信号)
                                % 因此需要发出一个通知
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
% h = figure(2);
% h = waves.Output_Waves_Display(h);
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
Si_IGBT_parallel = load('.\devices\Infineon_IGZ100N65H5_650V.mat');
Si_IGBT_parallelD = load('.\devices\Infineon_IGZ100N65H5_650V_Diode_C5D50065D.mat');
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device ...
    Si_IGBT.device Si_IGBT.device Si_IGBT_parallel.device Si_IGBT_parallelD.device ...
    Si_IGBT_parallel.device Si_IGBT_parallelD.device];
parallel_nums = [3 2 2 3 3 3 3 1 3 1]; % 3 .* ones(1, topology.Nums); % 器件并联个数
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, topology.Device_InParallel);
% losses.Temperature_Losses_Calc(0.07);
losses.JunctionTemperatureSet(85);
losses.Conduction_Losses_Calc();
losses.Switching_Losses_Calc();
% Display
fprintf('The conduction losses of S2 (SiC MOSFET in hybrid switch) is %d.\n', ...
    sum(losses.Loss([2 12])));
fprintf('The conduction losses of S7 (Si IGBT in hybrid switch) is %d.\n', ...
    sum(losses.Loss([7 8 17])));
fprintf('The conduction losses of S8 (SiC Schottky Diode in hybrid switch) is %d.\n', ...
    losses.Loss(18));
fprintf('Total conduction losses is %d.\n', sum(losses.Loss([2 7 8 12 17 18])));
