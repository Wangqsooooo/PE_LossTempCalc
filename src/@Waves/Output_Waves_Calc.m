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
    % 状态空间方程计算一次还是需要一定的时间的, 因为损耗计算时只需要电流, 不需要电压波形
    % 因此这里多加了一个变量
    if load.PF == 1 % PF = 1时是一个一阶的状态空间方程, 其余情况下为二阶的
        init_state = 0;
    else
        init_state = [0; 0];
    end
    if strcmp(options.Object, 'Current')
        obj.Current = lsim(load.sys_current, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
        % 电流滞后时, 输出电流在只有一个滤波电感的情况下存在很大的直流分量, 而且无法消除
        % 这并不说明计算出错了, 已经验证过仿真结果与计算结果是完全相符的
        % 解决方案一: 在滤波电感上串联一个电阻, 电阻很小的话对前面的计算影响很小, 但是要消除电流直流分量需要非常长的时间
        % 如果串联一个大的电阻, 那么前面的计算都要改写, 这样电流就会很快达到平衡
        % 解决方案二: 直接将电流的直流分量减去, 这个方案等效为给滤波电感上串联一个很小的电阻
        % 然后经过了无穷长时间直到输出电流达到了平衡
        if load.PF_flag == 2
            DC_component = sum(obj.OneCycleCurrent) * obj.Ts / obj.T;
            obj.Current = obj.Current - DC_component;
        end
    elseif strcmp(options.Object, 'Voltage')
        obj.Voltage = lsim(load.sys_voltage, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
    else
        obj.Current = lsim(load.sys_current, obj.Upwm, 0:obj.Ts:obj.Period, init_state);
        % 同上, 负载电压不需要该操作
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
