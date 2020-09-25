filename = 'ThreeLevel_ANPC.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(1100, 1200, 0.02, 4e-3, 690, 110e3, 100, 'PF', 0.92); % load是matlab的关键词, 换成cload
waves = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
h = figure(1);
[~, modulation_sample, carrier, control] = waves.ThreeLevel_ANPC_SingleCurrentPath_Display(h, 0.04, 0.06, cload);
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
current1 = waves.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
current1 = current1(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
current2 = waves.Device_FlowingCurrent_Calc(2, topology.Path, 'Mode', 'Fundamental');
current2 = current2(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
current5 = waves.Device_FlowingCurrent_Calc(5, topology.Path, 'Mode', 'Fundamental');
current5 = current5(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
modulation_sample = modulation_sample(:, round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
carrier = carrier(:, round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
control = control(:, round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));

% 画图
t = 0:waves.Ts:waves.T;
figure(2);
subplot(5, 1, 1); hold on;
modulation = cload.ma.*sin(100.*pi.*t); % modulation_sample;
modulation = modulation + (modulation < 0);
plot(t, modulation);
plot(t, carrier(1, :));
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold'; a.XTickLabel = {};
position1 = a.Position;

subplot(5, 1, 2); hold on;
yyaxis left;
modulation = cload.ma.*sin(100.*pi.*t); % modulation_sample;
Upwm = modulation >= carrier(1, :);
Upwm = Upwm - (modulation < carrier(2, :));
plot(t, 400.*Upwm);
yyaxis right;
current = waves.Fundamental_Component(1).*sin(100.*pi.*t+waves.Fundamental_Component(2));
% current = waves.Fundamental_Component(1).*sin(100.*pi.*t+0.4);
plot(t, current);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold'; a.XTickLabel = {};
position2 = a.Position;

subplot(5, 1, 3); hold on;
current_switch = current .* (Upwm == 1) .* (current >= 0);
current_diode = current .* (Upwm == 1) .* (current < 0); current_diode = -current_diode;
plot(t, current_switch);
plot(t, current_diode);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold'; a.XTickLabel = {};
position3 = a.Position;
% txt = {'S1'};
% text(0.001, 90, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
% txt = {'\leftarrow switch current'};
% text(0.006232, 96.79, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');

subplot(5, 1, 4); hold on;
Upwm_fundamental = sin(100.*pi.*t);
current_switch = current .* (Upwm == 1) .* (current >= 0) + current .* (Upwm_fundamental < 0) .* (Upwm == 0) .* (current >= 0);
current_diode = current .* (Upwm == 1) .* (current < 0) + current .* (Upwm_fundamental < 0) .* (Upwm == 0) .* (current < 0); 
current_diode = -current_diode;
plot(t, current_switch);
plot(t, current_diode);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold'; a.XTickLabel = {};
position4 = a.Position;
% txt = {'S2'};
% text(0.001, 90, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
% txt = {'\leftarrow switch current'};
% text(0.006232, 96.79, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
% txt = {'diode current\rightarrow'};
% text(0.0077, 78, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');

subplot(5, 1, 5); hold on;
current_diode = current .* (Upwm_fundamental < 0) .* (Upwm == 0) .* (current >= 0);
current_switch = current .* (Upwm_fundamental < 0) .* (Upwm == 0) .* (current < 0); 
current_switch = -current_switch;
plot(t, current_switch);
plot(t, current_diode);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold';
position5 = a.Position;
% txt = {'S5'};
% text(0.001, 90, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
% txt = {'switch current\rightarrow'};
% text(0.0075, 78, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
a.XTickLabel = {'0', '', '\pi', '', '2\pi'};

f = gcf;
f.Units = 'centimeter'; f.Position = [0 0 9.71 13.4];
height = 0.15;
f.Children(1).Position = [position5(1) position5(2)-0.05 position5(3) height];
f.Children(2).Position = [position4(1) position4(2)-(height-position4(4))/2-0.025 position4(3) height];
f.Children(3).Position = [position3(1) position3(2)-(height-position3(4))/2 position3(3) height];
f.Children(4).Position = [position2(1) position2(2)-(height-position2(4))/2+0.025 position2(3) height];
f.Children(5).Position = [position1(1) position1(2)-height+position1(4)+0.05 position1(3) height];
