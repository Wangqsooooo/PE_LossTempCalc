% 存在器件层面上的混合情况, 即存在不同器件并联的情况
% 这类并联器件同时导通时, 电流并不是平均分配的, 需要额外考虑
% 为了实现对器件层面混合场合下的计算, 导致源代码多处进行了修改, 使得更难以阅读
filename = 'ThreeLevel_ANPC_withDeviceHybrid.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
waves = Waves(cload, topology.Nums, 0.06);
waves.ThreeLevel_ANPC_SingleCurrentPath(cload, 0, [1 2 3 4 5 6]);
delay = 5e-6;
shift1 = zeros(size(waves.Control(2, :))); shift2 = shift1;
shift1(1:end-1) = circshift(waves.Control(2, 1:end-1), round(delay/waves.Ts));
shift1(end) = waves.Control(2, end-round(delay/waves.Ts));
shift2(1:end-1) = circshift(waves.Control(2, 1:end-1), -round(delay/waves.Ts));
shift2(end) = waves.Control(2, 1+round(delay/waves.Ts));
waves.Control(7, :) = waves.Control(2, :)>0.5 & shift1>0.5 & shift2>0.5;
shift1(1:end-1) = circshift(waves.Control(3, 1:end-1), round(delay/waves.Ts));
shift1(end) = waves.Control(3, end-round(delay/waves.Ts));
shift2(1:end-1) = circshift(waves.Control(3, 1:end-1), -round(delay/waves.Ts));
shift2(end) = waves.Control(3, 1+round(delay/waves.Ts));
waves.Control(8, :) = waves.Control(3, :)>0.5 & shift1>0.5 & shift2>0.5;
waves.notify('ControlChanged'); % 由于是自己配置了一部分控制信号(7号和8号开关器件的信号)
                                % 因此需要发出一个通知
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
h = figure(1);
h = waves.Output_Waves_Display(h);
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device ...
    Si_IGBT.device Si_IGBT.device Si_IGBT.device Si_IGBT.device];
parallel_nums = [3 3 3 3 3 3 3 3]; % 3 .* ones(1, topology.Nums); % 器件并联个数
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, topology.Device_InParallel);
% 计算开关管上的电流
% 由于存在器件层面的混合, 只有在明确了具体的器件以及具体的结温后才能计算开关管上的电流
losses.JunctionTemperatureSet(85);
losses.Current_Coefficient_Calc();
current2 = waves.Device_FlowingCurrent_Calc(2, losses.Path, losses.Device_InParallel, ...
    losses.Device_InParallel_Coefficient);
current2 = current2(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
current7 = waves.Device_FlowingCurrent_Calc(7, losses.Path, losses.Device_InParallel, ...
    losses.Device_InParallel_Coefficient);
current7 = current7(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
t = 0:waves.Ts:waves.T;
figure(2); hold on;
plot(t, current2); plot(t, current7);
