classdef Waves < handle
    properties(SetAccess = public, GetAccess = public)
        Control % 各个开关器件的驱动信号
    end
    properties(SetAccess = private, GetAccess = public)
        Current % 输出电流, 线电流
        Voltage % 负载上的相电压
        Upwm % 逆变器输出电压
        ControlSet % 使能位, 用来判断各个开关器件的驱动信号是否已经给定
        SCheck % 使能位, 是否存在短路问题, 如果存在短路问题, 说明驱动信号存在问题
        Period % 持续时间
        T % 周期时长
        Ts % 计算精度
    end
    properties(Dependent)
        Ready
        OneCycleUpwm
        OneCycleCurrent
        OneCycleVoltage
        OneCycleControl
        DC_Component
        Fundamental_Component
    end
    events
        ControlChanged
    end
    
    methods
        function obj = Waves(load, nums, period, Ts, options)
            arguments
                load Load
                nums (1, 1) {mustBePositive, mustBeInteger}
                period (1, 1) {mustBePositive, mustBeReal} = 0.1
                Ts (1, 1) {mustBePositive, mustBeReal} = 5e-8
                options.Topology TopologyType = TopologyType.TwoLevel_HalfBridge
                options.Order (1, :) double = 0
                options.SampleTech (1, 1) string {mustBeMember(options.SampleTech, {'SingleEdge', 'Natural'})} = 'SingleEdge'
                options.PhaseShift (1, 1) double = 0
                options.Defined_Modulation ModulationType = ModulationType.None
            end
            obj.Control = zeros(nums, round(period/Ts)+1);
            obj.addlistener('ControlChanged', @updateControlSet);
            obj.Period = period; obj.T = load.T; obj.Ts = Ts;
            obj.ControlSet = zeros(nums, 1); obj.SCheck = false;
            if options.Topology.isAvailableModulation(options.Defined_Modulation)
                switch options.Defined_Modulation
                    case ModulationType.TwoLevel_SPWM
                        disp('TwoLevel SPWM Method is applied!');
                        obj.SPWM_Config(load.freq, load.T, load.ma, options.PhaseShift, [-1, 1], options.Order, ...
                            'SampleTech', options.SampleTech);
                    case ModulationType.TwoLevel_SVM
                        disp('TwoLevel SVM Method is applied!');
                        obj.SVM_Config(load.freq, load.T, load.ma, options.PhaseShift, options.Order, ...
                            'SampleTech', options.SampleTech);
                    case ModulationType.ThreeLevel_ANPC_DualCurrentPath
                        disp('ThreeLevel ANPC Dual-Current-Path Method is applied!');
                        obj.ThreeLevel_ANPC_DualCurrentPath(load, options.PhaseShift, options.Order);
                    case ModulationType.ThreeLevel_ANPC_SingleCurrentPath
                        disp('ThreeLevel ANPC Single-Current-Path Method is applied!');
                        obj.ThreeLevel_ANPC_SingleCurrentPath(load, options.PhaseShift, options.Order);
                end
            end
        end
        
        [modulation, carrier, control] = SPWM_Config(obj, freq, T, ma, phi, MinMax, position, options); % SPWM波配置
        function [h, modulation, carrier, control] = SPWM_Display(obj, h, t_begin, t_end, freq, T, ma, phi, MinMax, options)
            arguments
                obj, h
                t_begin (1, 1) double, t_end (1, 1) double
                freq, T, ma, phi
                MinMax (1, 2) double = [-1 1]
                options.SampleTech (1, 1) string {mustBeMember(options.SampleTech, {'SingleEdge', 'Natural'})} = 'SingleEdge'
                options.CarrierPhaseShift (1, 1) double = 0
            end
            [modulation, carrier, control] = obj.SPWM_Config(freq, T, ma, phi, MinMax, 0, ...
                'SampleTech', options.SampleTech, 'CarrierPhaseShift', options.CarrierPhaseShift);
            h = obj.Display(h, t_begin, t_end, modulation, carrier, control);
        end
        
        [modulation, carrier, control] = SVM_Config(obj, freq, T, ma, phi, position, options); % SVM波配置, 和SPWM波很像
        function [h, modulation, carrier, control] = SVM_Display(obj, h, t_begin, t_end, freq, T, ma, phi, options)
            arguments
                obj, h
                t_begin (1, 1) double, t_end (1, 1) double
                freq, T, ma, phi
                options.SampleTech (1, 1) string {mustBeMember(options.SampleTech, {'SingleEdge', 'Natural'})} = 'SingleEdge'
                options.CarrierPhaseShift (1, 1) double = 0
            end
            [modulation, carrier, control] = obj.SVM_Config(freq, T, ma, phi, [0 0], ...
                'SampleTech', options.SampleTech, 'CarrierPhaseShift', options.CarrierPhaseShift);
            h = obj.Display(h, t_begin, t_end, modulation, carrier, control);
        end
        
        % 三电平ANPC电路双电流通路调制方法
        % 最后一个参数是这个调制方法中的暂态过程的持续时间transient, 默认为3e-6
        [modulation, carrier, control] = ThreeLevel_ANPC_DualCurrentPath(obj, load, phaseshift, order, transient, options);
        function [h, modulation, carrier, control] = ThreeLevel_ANPC_DualCurrentPath_Display(obj, h, t_begin, t_end, load, options)
            arguments
                obj, h
                t_begin (1, 1) double, t_end (1, 1) double
                load Load
                options.PhaseShift (1, 1) double = 0 % 调制波的相移角
            end
            [modulation, carrier, control] = obj.ThreeLevel_ANPC_DualCurrentPath(load, options.PhaseShift, 'DisplayMode', 'Yes');
            h = obj.Display(h, t_begin, t_end, modulation, carrier, control);
        end
        % 三电平ANPC电路单电流通路调制方法
        [modulation, carrier, control] = ThreeLevel_ANPC_SingleCurrentPath(obj, load, phaseshift, order, options);
        function [h, modulation, carrier, control] = ThreeLevel_ANPC_SingleCurrentPath_Display(obj, h, t_begin, t_end, load, options)
            arguments
                obj, h
                t_begin (1, 1) double, t_end (1, 1) double
                load Load
                options.PhaseShift (1, 1) double = 0 % 调制波的相移角
            end
            [modulation, carrier, control] = obj.ThreeLevel_ANPC_SingleCurrentPath(load, options.PhaseShift, 'DisplayMode', 'Yes');
            h = obj.Display(h, t_begin, t_end, modulation, carrier, control);
        end
        
        % 判断是否有可能会产生短路情况
        function ShortCircuit_Check(obj, restriction)
            if all(obj.ControlSet)
                for i = 1:size(restriction, 1)
                    if any(obj.Control(restriction(i, 1), :) & obj.Control(restriction(i, 2), :))
                        error('The circuit have short-circuit error!');
                    end
                    obj.SCheck = true;
                end
            else
                error('Please configure all drive signals first!');
            end
        end
        Output_Waves_Calc(obj, path, load, options); % 输出波形计算
        current = Device_FlowingCurrent_Calc(obj, position, path);
        function h = Output_Waves_Display(obj, h)
            if isempty(obj.Upwm)
                disp('No output waves available!');
            else
                clf(h, 'reset');
                subplot(2, 1, 1);
                plot(0:obj.Ts:obj.Period, obj.Upwm, 'LineWidth', 1.0, 'DisplayName', 'Uo'); legend;
                subplot(2, 1, 2); hold on;
                if ~isempty(obj.Current)
                    plot(0:obj.Ts:obj.Period, obj.Current, 'LineWidth', 1.0, 'DisplayName', 'Output Current');
                end
                if ~isempty(obj.Voltage)
                    plot(0:obj.Ts:obj.Period, obj.Voltage, 'LineWidth', 1.0, 'DisplayName', 'Load Volatge');
                end
                legend;
                h.Children(4).Title.String = 'Phase A';
            end
        end
        
        % 控制信号使能位更新
        function updateControlSet(scr, ~)
            for i = find(scr.ControlSet'==0)
                if ~isequal(scr.Control(i, :), zeros(size(scr.Control(i, :))))
                    scr.ControlSet(i) = 1;
                end
            end
        end
        % 使能位, 所有位置的开关器件的驱动信号都设置完成后, Ready置1, 可以接下去计算输出波形
        function Ready = get.Ready(obj)
            if all(obj.ControlSet) && obj.SCheck == true
                Ready = 1;
            else
                Ready = 0;
            end
        end
        function NotReady_Information(obj)
            if ~all(obj.ControlSet)
                disp('Please configure all drive signals first!');
            else
                disp('Please check whether the circuit have short-circuit problem before calculating output waves!');
                disp('You can use ''ShortCircuit_Check'' method.');
            end
        end
        % 截取一个周期的输出波形和驱动波形
        function OneCycleUpwm = get.OneCycleUpwm(obj)
            if (length(obj.Upwm) == round(obj.Period/obj.Ts+1)) && (obj.Period >= obj.T)
                OneCycleUpwm = obj.Upwm(round((obj.Period-obj.T)/obj.Ts+1):round(obj.Period/obj.Ts+1));
            else
                error('No Upwm data or period less than T.');
            end
        end
        function OneCycleCurrent = get.OneCycleCurrent(obj)
            if (length(obj.Current) == round(obj.Period/obj.Ts+1)) && (obj.Period >= obj.T)
                OneCycleCurrent = obj.Current(round((obj.Period-obj.T)/obj.Ts+1):round(obj.Period/obj.Ts+1));
            else
                error('No Current data or period less than T.');
            end
        end
        function OneCycleVoltage = get.OneCycleVoltage(obj)
            if (length(obj.Voltage) == round(obj.Period/obj.Ts+1)) && (obj.Period >= obj.T)
                OneCycleVoltage = obj.Voltage(round((obj.Period-obj.T)/obj.Ts+1):round(obj.Period/obj.Ts+1));
            else
                error('No Voltage data or period less than T.');
            end
        end
        function OneCycleControl = get.OneCycleControl(obj)
            if (size(obj.Control, 2) == round(obj.Period/obj.Ts+1)) && (obj.Period >= obj.T)
                OneCycleControl = obj.Control(:, round((obj.Period-obj.T)/obj.Ts+1):round(obj.Period/obj.Ts+1));
            else
                error('No Control data or period less than T.');
            end
        end
        function DC_Component = get.DC_Component(obj)
            DC_Component = sum(obj.OneCycleCurrent) * obj.Ts / obj.T;
        end
        function Fundamental_Component = get.Fundamental_Component(obj)
            t = 0:obj.Ts:obj.T;
            a1 = sum(obj.OneCycleCurrent' .* cos(2.*pi.*t./obj.T)) * obj.Ts * 2 / obj.T;
            b1 = sum(obj.OneCycleCurrent' .* sin(2.*pi.*t./obj.T)) * obj.Ts * 2 / obj.T;
            Fundamental_Component = [sqrt(a1^2+b1^2), atan2(a1, b1)];
        end
    end
    
    methods(Access = private)
        function h = Display(obj, h, t_begin, t_end, modulation, carrier, control)
            clf(h, 'reset');
            if t_end <= obj.Period && t_begin >= 0
                modulation = modulation(round(t_begin./obj.Ts)+1:round(t_end/obj.Ts)+1);
                carrier = carrier(:, round(t_begin./obj.Ts)+1:round(t_end/obj.Ts)+1);
                control = control(:, round(t_begin./obj.Ts)+1:round(t_end/obj.Ts)+1);
                subplot(2, 1, 1); hold on;
                plot(t_begin:obj.Ts:t_end, modulation);
                plot(t_begin:obj.Ts:t_end, carrier);
                subplot(2, 1, 2); hold on;
                num = size(control, 1);
                for i = 1:num
                    plot(t_begin:obj.Ts:t_end, control(i, :)+(num-i)*1.5);
                end
                h.Children(2).Title.String = 'One Phase';
            else
                error('Error time period!');
            end
        end
    end
end
