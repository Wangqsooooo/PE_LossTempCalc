filename = 'ThreeLevel_ANPC.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
waves = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.ThreeLevel_ANPC_SingleCurrentPath);
waves.ShortCircuit_Check(topology.HB_Restriction);
waves.Output_Waves_Calc(topology.Path, cload);

Period = waves.Period; T = waves.T; Ts = waves.Ts;
current_S1 = waves.Device_FlowingCurrent_Calc(1, topology.Path);
current_S1 = current_S1(round((Period-T)/Ts+1):round(Period/Ts+1));
h = figure(1); clf(h, 'reset');
subplot(3, 1, 1);
plot(0:Ts:T, current_S1);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 10; a.FontWeight = 'bold';
a.XTickLabel = {''};
position1 = a.Position;

current_S2 = waves.Device_FlowingCurrent_Calc(2, topology.Path);
current_S2 = current_S2(round((Period-T)/Ts+1):round(Period/Ts+1));
subplot(3, 1, 2);
plot(0:Ts:T, current_S2);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 10; a.FontWeight = 'bold';
a.XTickLabel = {''};
position2 = a.Position;

current_S5 = waves.Device_FlowingCurrent_Calc(5, topology.Path);
current_S5 = current_S5(round((Period-T)/Ts+1):round(Period/Ts+1));
subplot(3, 1, 3);
plot(0:Ts:T, current_S5);
a = gca;
a.FontName = 'Times New Roman'; a.FontSize = 10; a.FontWeight = 'bold';
a.XTickLabel = {'0', '', '', '', '', '\pi', '', '', '', '', '2\pi'};
position3 = a.Position;

f = gcf;
height = 0.25;
f.Children(1).Position = [position3(1) position3(2) position3(3) 0.21];
f.Children(2).Position = [position2(1) position2(2)-(0.35-position2(4))/2 position2(3) 0.35];
f.Children(3).Position = [position1(1) position1(2)-0.21+position1(4) position1(3) 0.21];
