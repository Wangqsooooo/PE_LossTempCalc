function Output_Waves_Calc(obj, path, load, options)
arguments
    obj, path, load
    options.Object (1, 1) string {mustBeMember(options.Object, {'Current', 'Voltage', 'Both'})} = 'Both'
    options.Neutral (1, :) double = inf
end

if obj.Ready == 1
    obj.Upwm = zeros(1, length(0:obj.Ts:obj.Period));
    for i = 1:size(path, 1)
        if path(i, end-1) ~= 0 && path(i, end) >= 0
            logic = obj.Control(abs(path(i, 1)), :);
            extra_logic_nums = find(path(i+1:end, end)>0, 1) - 1;
            for k = 1:extra_logic_nums
                if path(i+k, 1) ~= 0
                    logic = logic | obj.Control(abs(path(i+k, 1)), :);
                end
            end
            for j = 2:find(path(i, 1:end-2)==0, 1)-1
                temp_logic = obj.Control(abs(path(i, j)), :);
                for k = 1:extra_logic_nums
                    if path(i+k, j) ~= 0
                        temp_logic = temp_logic | obj.Control(abs(path(i+k, j)), :);
                    end
                end
                logic = logic & temp_logic;
            end
            obj.Upwm = obj.Upwm + path(i, end-1) .* logic;
        end
    end
    if length(options.Neutral) == length(obj.Upwm) && options.Neutral(1) ~= inf
        obj.Upwm = obj.Upwm - options.Neutral;
    end
    % ״̬�ռ䷽�̼���һ�λ�����Ҫһ����ʱ���, ��Ϊ��ļ���ʱֻ��Ҫ����, ����Ҫ��ѹ����
    % �����������һ������
    if load.PF == 1 % PF = 1ʱ��һ��һ�׵�״̬�ռ䷽��, ���������Ϊ���׵�
        init_state = 0;
    else
        init_state = [0; 0];
    end
    if strcmp(options.Object, 'Current')
        obj.Current = lsim(load.sys_current, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
        % �����ͺ�ʱ, ���������ֻ��һ���˲���е�����´��ںܴ��ֱ������, �����޷�����
        % �Ⲣ��˵�����������, �Ѿ���֤�������������������ȫ�����
        % �������һ: ���˲�����ϴ���һ������, �����С�Ļ���ǰ��ļ���Ӱ���С, ����Ҫ��������ֱ��������Ҫ�ǳ�����ʱ��
        % �������һ����ĵ���, ��ôǰ��ļ��㶼Ҫ��д, ���������ͻ�ܿ�ﵽƽ��
        % ���������: ֱ�ӽ�������ֱ��������ȥ, ���������ЧΪ���˲�����ϴ���һ����С�ĵ���
        % Ȼ�󾭹������ʱ��ֱ����������ﵽ��ƽ��
        if load.PF_flag == 2
            DC_component = sum(obj.OneCycleCurrent) * obj.Ts / obj.T;
            obj.Current = obj.Current - DC_component;
        end
    elseif strcmp(options.Object, 'Voltage')
        obj.Voltage = lsim(load.sys_voltage, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
    else
        obj.Current = lsim(load.sys_current, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
        % ͬ��, ���ص�ѹ����Ҫ�ò���
        if load.PF_flag == 2
            DC_component = sum(obj.OneCycleCurrent) * obj.Ts / obj.T;
            obj.Current = obj.Current - DC_component;
        end
        obj.Voltage = lsim(load.sys_voltage, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
    end
else
    obj.NotReady_Information();
end
end
