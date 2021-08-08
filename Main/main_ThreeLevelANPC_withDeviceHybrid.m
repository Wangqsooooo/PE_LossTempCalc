% �������������ϵĻ�����, ��ʱ����������������һ����, �������ź�Ҳ�п��ܲ�һ��
% Ϊ��ʵ�ֶ����������ϳ����µļ���, ����Դ����ദ�������޸�, ��ᵼ��Դ�����Կ���
filename = 'ThreeLevel_ANPC_withDeviceHybrid.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc�����������������ֱ����ѹ��ȥ���ֱ����ѹ
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load��matlab�Ĺؼ���, ����cload
waves = Waves(cload, topology.Nums, 0.06);
waves.ThreeLevel_ANPC_SingleCurrentPath(cload, 0, [1 2 3 4 5 6]);
delay = 1e-6;
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
waves.notify('ControlChanged'); % �������Լ�������һ���ֿ����ź�(7�ź�8�ſ����������ź�)
                                % �����Ҫ����һ��֪ͨ
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
% h = figure(2);
% h = waves.Output_Waves_Display(h);
SiC_MOSFET = load('.\devices\Cree_C3M0015065K_SiC_650V.mat');
Si_IGBT = load('Infineon_IKZ75N65EL5_650V_withoutRecovery.mat');
Si_IGBT_parallel = load('.\devices\Infineon_IGZ100N65H5_650V.mat');
devices = [Si_IGBT.device SiC_MOSFET.device SiC_MOSFET.device Si_IGBT.device ...
    Si_IGBT.device Si_IGBT.device Si_IGBT.device Si_IGBT.device];
parallel_nums = [3 3 3 3 3 3 3 3]; % 3 .* ones(1, topology.Nums); % ������������
Switching_Voltage = Vdc./2 .* ones(1, topology.Nums);
Rg = [4, 23; 5, 5; 5, 5; 4, 23; 4, 23; 4, 23];
losses = Losses(waves.T, waves.Ts, waves.OneCycleCurrent, waves.OneCycleControl, ...
    topology.Path, devices, parallel_nums, Switching_Voltage, Rg, topology.Device_InParallel);
% losses.Temperature_Losses_Calc(0.07);
losses.JunctionTemperatureSet(85);
losses.Conduction_Losses_Calc();
losses.Switching_Losses_Calc();
% Display
fprintf('The conduction losses of S2 (SiC ones in hybrid switch) is %d.\n', ...
    sum(losses.Loss(2:8:10)));
fprintf('The conduction losses of S7 (Si ones in hybrid switch) is %d.\n', ...
    sum(losses.Loss(7:8:15)));
fprintf('Total conduction losses is %d.\n', sum(losses.Loss(2:8:10))+sum(losses.Loss(7:8:15)));
