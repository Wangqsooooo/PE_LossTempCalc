classdef Load < handle
    properties(SetAccess = private, GetAccess = public)
        Vdc % ��������ֱ����ѹ��Χ, ������ֱ����ѹ��ȥ������ֱ����ѹ
        freq % �ز�Ƶ��
        T % ��������
        L % �˲����
        Vac % �����ߵ�ѹ, �����LoadExplanation.tifͼƬ
        P % ���ฺ�ض�й�����
        P_rate % ���ذٷֱ�, P_rate=100˵��������, P_rate=50���ǰ���
        Q % ���ฺ���޹�����
        PF % ��������
        PF_flag % ��ǰ���ͺ�ı�־λ, PF_flag=1˵����ǰ, PF_flag=2˵���ͺ�
        R_load % �����ϵĵ�����ֵ
        C_load % �����ϵĵ�����ֵ, ��PF_flag=2ʱ, C_load=0
        L_load % �����ϵĵ����ֵ, ��PF_flag=1ʱ, L_load=0
    end
    properties(Dependent)
        ma % ���ȵ��Ʊ�
        Irms % �ߵ�����Чֵ
        Iphi % ����ߵ�����������ѹ֮�����λ��, ���ݸ��ؼ��������ֵ
        Vrms % ���ѹ��Чֵ
        sys_current % ���ص�·��״̬�ռ䷽��, ���Ϊ�ߵ���
        sys_voltage % ���ص�·��״̬�ռ䷽��, ���Ϊ�������ѹ
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
        
        % ��ӡ������Ϣ
        function Display(obj)
            if obj.PF_flag == 1
                fprintf('Load: L=%d, Rload=%d, Cload=%d, P=%d, Q=%d, PF=%d(������ǰ)\n', ...
                    obj.L, obj.R_load, obj.C_load, obj.P*obj.P_rate/100, obj.Q, obj.PF);
                fprintf('Output: Vrms=%d, Irms=%d, phase difference between current and upwm: %d\n', ...
                    obj.Vrms, obj.Irms, obj.Iphi*180/pi);
            else
                fprintf('Load: L=%d, Rload=%d, Lload=%d, P=%d, Q=%d, PF=%d(�����ͺ�)\n', ...
                    obj.L, obj.R_load, obj.L_load, obj.P*obj.P_rate/100, obj.Q, obj.PF);
                fprintf('Output: Vrms=%d, Irms=%d, phase difference between current and upwm: %d\n', ...
                    obj.Vrms, obj.Irms, obj.Iphi*180/pi);
            end
            fprintf('ma=%d\n', obj.ma);
        end
        
        % �Ƕ������Եļ��㷽��
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
