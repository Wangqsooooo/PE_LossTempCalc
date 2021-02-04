classdef Load < handle
    properties(SetAccess = private, GetAccess = public)
        Vdc % 逆变器输出直流电压范围, 最高输出直流电压减去最低输出直流电压
        freq % 载波频率
        T % 基波周期
        L % 滤波电感
        Vac % 负载线电压, 详情见LoadExplanation.tif图片
        P % 三相负载额定有功功率
        P_rate % 负载百分比, P_rate=100说明是满载, P_rate=50则是半载
        Q % 三相负载无功功率
        PF % 功率因数
        PF_flag % 超前或滞后的标志位, PF_flag=1说明超前, PF_flag=2说明滞后
        R_load % 负载上的电阻阻值
        C_load % 负载上的电容阻值, 当PF_flag=2时, C_load=0
        L_load % 负载上的电感阻值, 当PF_flag=1时, L_load=0
    end
    properties(Dependent)
        ma % 幅度调制比
        Irms % 线电流有效值
        Iphi % 输出线电流与输出相电压之间的相位差, 根据负载计算出来的值
        Vrms % 相电压有效值
        sys_current % 负载电路的状态空间方程, 输出为线电流
        sys_voltage % 负载电路的状态空间方程, 输出为负载相电压
    end
    
    methods
        function obj = Load(Vdc, freq, T, L, Vac, P, P_rate, PF_flag, options)
            arguments
                Vdc, freq, T, L, Vac, P, P_rate
                PF_flag (1, 1) {mustBeMember(PF_flag, [1 2])} = 1
                options.Q (1, 1) double = -1
                options.PF (1, 1) {mustBeGreaterThanOrEqual(options.PF, 0), mustBeLessThanOrEqual(options.PF, 1)} = 1 
            end
            obj.Vdc = Vdc; obj.freq = freq; obj.T = T;
            obj.L = L; obj.Vac = Vac; obj.P = P; obj.P_rate = P_rate;
            obj.PF_flag = PF_flag;
            obj.R_load = obj.Vac^2/obj.P/(obj.P_rate/100);
            if options.Q < 0
                obj.PF = options.PF;
                obj.Q = sqrt(1-obj.PF^2)*obj.Vac^2/obj.R_load/obj.PF;
            else
                obj.Q = options.Q;
                obj.PF = sqrt((obj.P*obj.P_rate/100)^2/((obj.P*obj.P_rate/100)^2+obj.Q^2));
            end
            w = 2*pi/obj.T;
            if obj.PF_flag == 1
                obj.C_load = sqrt(1-obj.PF^2)/w/obj.R_load/obj.PF;
                obj.L_load = 0;
            else
                obj.C_load = 0;
                obj.L_load = obj.R_load*obj.PF/w/sqrt(1-obj.PF^2);
            end
        end
        
        % 打印计算信息
        function Display(obj)
            if obj.PF_flag == 1
                fprintf('Load: L=%d, Rload=%d, Cload=%d, P=%d, Q=%d, PF=%d(电流超前)\n', ...
                    obj.L, obj.R_load, obj.C_load, obj.P*obj.P_rate/100, obj.Q, obj.PF);
                fprintf('Output: Vrms=%d, Irms=%d, phase difference between current and upwm: %d\n', ...
                    obj.Vrms, obj.Irms, obj.Iphi*180/pi);
            else
                fprintf('Load: L=%d, Rload=%d, Lload=%d, P=%d, Q=%d, PF=%d(电流滞后)\n', ...
                    obj.L, obj.R_load, obj.L_load, obj.P*obj.P_rate/100, obj.Q, obj.PF);
                fprintf('Output: Vrms=%d, Irms=%d, phase difference between current and upwm: %d\n', ...
                    obj.Vrms, obj.Irms, obj.Iphi*180/pi);
            end
            fprintf('ma=%d\n', obj.ma);
        end
        
        % 非独立属性的计算方法
        function ma = get.ma(obj)
            w = 2*pi/obj.T;
            if obj.PF_flag == 1
                ma = abs(obj.Vac*sqrt(2)/sqrt(3)*(1-w^2*obj.L*obj.C_load+1i*w*obj.L/obj.R_load))/(obj.Vdc/2);
            else
                ma = abs(obj.Vac*sqrt(2)/sqrt(3)*(1+obj.L/obj.L_load+1i*w*obj.L/obj.R_load))/(obj.Vdc/2);
            end
        end
        function Irms = get.Irms(obj)
            w = 2*pi/obj.T;
            if obj.PF_flag == 1
                Irms = obj.Vac/sqrt(3)*abs(1/obj.R_load+1i*w*obj.C_load);
            else
                Irms = obj.Vac/sqrt(3)*abs(1/obj.R_load-1i/w/obj.L_load);
                
            end
        end
        function Iphi = get.Iphi(obj)
            w = 2*pi/obj.T;
            if obj.PF_flag == 1
                Iphi = angle(1/(1i*w*obj.L+obj.R_load/(1+1i*w*obj.R_load*obj.C_load)));
            else
                Iphi = angle(1/(1i*w*obj.L+1i*w*obj.R_load*obj.L_load/(1i*w*obj.L_load+obj.R_load)));
            end
        end
        function Vrms = get.Vrms(obj)
            Vrms = obj.Vac/sqrt(3);
        end
        function sys_current = get.sys_current(obj)
            if obj.PF == 1
                A = -obj.R_load/obj.L;
                B = 1/obj.L;
                C = 1; D = 0; 
            elseif obj.PF_flag == 1
                A = [0 -1/obj.L; 1/obj.C_load -1/obj.R_load/obj.C_load];
                B = [1/obj.L 0]';
                C = [1 0];
                D = 0;
            else
                A = [0 -1/obj.L; 0 -obj.R_load/obj.L-obj.R_load/obj.L_load];
                B = [1/obj.L obj.R_load/obj.L]';
                C = [1 0];
                D = 0;
            end
            sys_current = ss(A, B, C, D);
        end
        function sys_voltage = get.sys_voltage(obj)
            if obj.PF == 1
                A = -obj.R_load/obj.L;
                B = 1/obj.L;
                C = obj.R_load; D = 0;
            elseif obj.PF_flag == 1
                A = [0 -1/obj.L; 1/obj.C_load -1/obj.R_load/obj.C_load];
                B = [1/obj.L 0]';
                C = [0 1];
                D = 0;
            else
                A = [0 -1/obj.L; 0 -obj.R_load/obj.L-obj.R_load/obj.L_load];
                B = [1/obj.L obj.R_load/obj.L]';
                C = [0 1];
                D = 0;
            end
            sys_voltage = ss(A, B, C, D);
        end
    end
end
