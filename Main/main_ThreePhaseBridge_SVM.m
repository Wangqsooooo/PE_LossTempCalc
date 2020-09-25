filename = 'TwoLevel_HalfBridge.txt';
topology = Topology('Filename', filename);
Vdc = topology.Path(end, end-1)-topology.Path(1, end-1); % Vdc等于逆变器输出侧最高直流电压减去最低直流电压
cload = Load(Vdc, 4000, 0.02, 1e-3, 400, 100e3, 100, 1, 'PF', 0.9524); % load是matlab的关键词, 换成cload
% A相
wavesA = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'Defined_Modulation', ModulationType.TwoLevel_SVM);
wavesA.ShortCircuit_Check(topology.HB_Restriction);
wavesA.Output_Waves_Calc(topology.Path, cload);
h = figure(1);
wavesA.SVM_Display(h, 0, 0.06, cload.freq, cload.T, cload.ma, 0);
% B相
wavesB = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', -2*pi/3, 'Defined_Modulation', ModulationType.TwoLevel_SVM);
wavesB.ShortCircuit_Check(topology.HB_Restriction);
wavesB.Output_Waves_Calc(topology.Path, cload);
% C相
wavesC = Waves(cload, topology.Nums, 0.06, 'Topology', topology.Type, 'Order', topology.Order, ...
    'PhaseShift', -4*pi/3, 'Defined_Modulation', ModulationType.TwoLevel_SVM);
wavesC.ShortCircuit_Check(topology.HB_Restriction);
wavesC.Output_Waves_Calc(topology.Path, cload);
% IAB
figure(2);
plot(0:wavesA.Ts:wavesA.Period, wavesA.Current-wavesB.Current);
