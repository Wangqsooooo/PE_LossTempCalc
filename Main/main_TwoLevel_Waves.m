filename = 'TwoLevel_HalfBridge.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(1100, 1200, 0.02, 4e-3, 690, 110e3, 100, 'PF', 0.92);
waves = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.TwoLevel_SPWM);
h = figure(1);
[~, modulation, carrier, control] = waves.SPWM_Display(h, 0.04, 0.06, cload.freq, ...
    cload.T, cload.ma, 0, [-1, 1], 'SampleTech', 'Natural');
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);
current = waves.Device_FlowingCurrent_Calc(1, topology.Path, 'Mode', 'Fundamental');
current = current(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
modulation = modulation(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
carrier = carrier(round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));
control = control(:, round((waves.Period-waves.T)/waves.Ts+1):round(waves.Period/waves.Ts+1));

% 画图
t = 0:waves.Ts:waves.T;
figure(2);
subplot(3, 1, 1); hold on;
plot(t, modulation);
plot(t, carrier);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold'; a.XTickLabel = {};
position1 = a.Position;

subplot(3, 1, 2); hold on;
yyaxis left;
plot(t, waves.OneCycleUpwm);
yyaxis right;
plot(t, waves.Fundamental_Component(1).*sin(100.*pi.*t+waves.Fundamental_Component(2)));
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold'; a.XTickLabel = {};
position2 = a.Position;

subplot(3, 1, 3); hold on;
current1 = current .* (current >= 0);
current2 = current .* (current < 0); current2 = -current2;
plot(t, current1);
plot(t, current2);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 8; a.FontWeight = 'bold';
% txt = {'S1'};
% text(0.001, 90, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
% txt = {'\leftarrow switch current'};
% text(0.006232, 96.79, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
% txt = {'diode current\rightarrow'};
% text(0.0077, 78, txt, 'FontName', 'Times New Roman', 'FontSize', 8, 'FontWeight', 'bold');
a.XTickLabel = {'0', '', '\pi', '', '2\pi'};
position3 = a.Position;

f = gcf;
f.Units = 'centimeter'; f.Position = [0 0 9.71 8];
f.Children(1).Position = [position3(1:3), 0.24];
f.Children(2).Position = [position2(1) position2(2)-(0.24-position2(4))/2 position2(3) 0.24];
f.Children(3).Position = [position1(1) position1(2)-0.24+position1(4) position1(3) 0.24];
