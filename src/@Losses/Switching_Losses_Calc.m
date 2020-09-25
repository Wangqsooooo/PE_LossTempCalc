function Switching_Losses_Calc(obj)
turn_on = zeros(size(obj.Control)); % 具体器件的开通时刻
turn_off = zeros(size(obj.Control)); % 具体器件的关断时刻
% 所有开通时刻, 开通时刻本身就包含另一些器件的关断, 因此不需要再考虑关断时刻了
All_SwitchON = zeros(1, size(obj.Control, 2));
for i = 1:size(turn_on, 1)
    turn_on(i, :) = (obj.Control(i, :)==1) & (circshift(obj.Control(i, :), 1)==0);
    turn_off(i, :) = (obj.Control(i, :)==0) & (circshift(obj.Control(i, :), 1)==1);
    All_SwitchON = All_SwitchON | turn_on(i, :);
end
SwitchON = find(All_SwitchON~=0);
Sep_SwitchON = cell(size(obj.Control, 1), 1);
Sep_SwitchOFF = cell(size(obj.Control, 1), 1);
for i = 1:size(obj.Control, 1)
    Sep_SwitchON{i} = find(turn_on(i, :)~=0);
    Sep_SwitchOFF{i} = find(turn_off(i, :)~=0);
end
path = obj.Simplified_Path;
for i = 1:size(path, 1)
    logic = obj.Control(abs(path(i, 1)), SwitchON);
    for j = 2:find(path(i, 1:end-2)==0, 1)-1
        logic = logic & obj.Control(abs(path(i, j)), SwitchON);
    end
    % 对于含有多电流通路的情况下来说, 上面得到的并不准确
    % 例子: three-level ANPC电路中 [S2 S5], [S3 S6], [S2 S3 S5 S6]开通时输出均为零
    % 那么只判断[S2 S5]导通并不能说明此时处于[S2 S5]导通[S3 S6]关断的情况
    % 还要排除多电流通路如[S2 S3 S5 S6]同时导通时的情况
    equal_nums = sum(path(i:end, end-1)==path(i, end-1));
    if equal_nums > 1
        for k = i+equal_nums-1:-1:i+1
            flag = 1;
            for m = 1:j
                if ~any(path(k, 1:end-2)==path(i, m))
                    flag = 0; break;
                end
            end
            if flag == 1
                off_device = ~(path(k, 1:end-2)==path(i, 1));
                for m = 2:j
                    off_device = off_device & ~(path(k, 1:end-2)==path(i, m));
                end
                off_device = path(k, 1:end-2) .* off_device; off_device(off_device==0) = [];
                for m = 1:length(off_device)
                    logic = logic & ~obj.Control(abs(off_device(m)), SwitchON);
                end
                break;
            end
        end
    end
    SwitchON_part = SwitchON(logic~=0); % 切换到当前电流通路的开通时刻
    % 寻找前一个状态是哪一个电流通路
    SwitchON_record = zeros(size(SwitchON_part)); bias = 1; % SwitchON_record记录已经计算过的开关时刻
    % 在所有电流通路中从后往前找, 从后往前找先验证多电流通路的情况
    % 然后在单电流通路情况下可以通过检查是否重复来确认, 省去了一个环节
    list = size(path, 1):-1:1; list = list(list~=i);
    for j = list
        SwitchON_part_last = SwitchON_part-1; % SwitchON_part的上一个时刻
        % SwitchON_part_last中会存在等于零的情况, 由于只表示了一个周期
        % 因此这种情况需要进行循环平移, 即为周期的最后一个时刻
        SwitchON_part_last(SwitchON_part_last==0) = size(obj.Control, 2);
        logic_pp = obj.Control(abs(path(j, 1)), SwitchON_part_last);
        for k = 2:find(path(j, 1:end-2)==0, 1)-1
            logic_pp = logic_pp & obj.Control(abs(path(j, k)), SwitchON_part_last);
        end
        SwitchON_pp = SwitchON_part(logic_pp~=0);
        Intersect = intersect(SwitchON_record(SwitchON_record~=0), SwitchON_pp);
        SwitchON_pp = setdiff(SwitchON_pp, Intersect);
        if ~isempty(SwitchON_pp)
            % 开关损耗计算
            flag = 1;
            if path(i, end-1)==path(j, end-1)
                num1 = find(path(i, 1:end-2)~=0, 1, 'last'); num2 = find(path(j, 1:end-2)~=0, 1, 'last');
                if max(num1, num2) == length(union(path(i, 1:num1), path(j, 1:num2)))
                    flag = 0;
                end
            end
            if flag == 1
                for k = 1:find(path(i, 1:end-2)==0, 1)-1
                    position = abs(path(i, k));
                    Intersect = intersect(SwitchON_pp, Sep_SwitchON{position});
                    current = obj.Current(Intersect) .* sign(path(i, k)) ./ obj.Parallel_Nums(position) ./ floor(path(i, end));
                    if ~isempty(current)
                        if path(i, end) - floor(path(i, end)) > 0.4 % 存在器件层面混合情况下最后一列都是.5结尾的
                            pdevices_potential = find(obj.Device_InParallel(position, :)~=0);
                            if ~isempty(pdevices_potential)
                                pdevices_real = sum(abs(path(i,1:end-2))==pdevices_potential(:), 2);
                                pdevices_real = pdevices_real' .* pdevices_potential;
                                pdevices_real(pdevices_real==0) = [];
                                if ~isempty(pdevices_real)
                                    F = obj.Device_InParallel_Coefficient(num2str([position, pdevices_real]));
                                    current_coefficient = F(sign(path(i, k)) .* obj.Current(Intersect));
                                else
                                    current_coefficient = 1;
                                end
                                current = current .* current_coefficient;
                            end
                        end
                        E = obj.Devices(position).Switching_Loss('Switch_Eon', current, ...
                            'V', obj.Switching_Voltage(position), 'Tj', obj.Tj{position}(1));
                        obj.Switch_Eon(position, Intersect) = E;
                    end
                end
                for k = 1:find(path(j, 1:end-2)==0, 1)-1
                    position = abs(path(j, k));
                    Intersect = intersect(SwitchON_pp, Sep_SwitchOFF{position});
                    current = obj.Current(Intersect) .* sign(path(j, k)) ./ obj.Parallel_Nums(position) ./ floor(path(j, end));
                    if ~isempty(current)
                        if path(j, end) - floor(path(j, end)) > 0.4
                            pdevices_potential = find(obj.Device_InParallel(position, :)~=0);
                            if ~isempty(pdevices_potential)
                                pdevices_real = sum(abs(path(j,1:end-2))==pdevices_potential(:), 2);
                                pdevices_real = pdevices_real' .* pdevices_potential;
                                pdevices_real(pdevices_real==0) = [];
                                if ~isempty(pdevices_real)
                                    F = obj.Device_InParallel_Coefficient(num2str([position, pdevices_real]));
                                    current_coefficient = F(sign(path(j, k)) .* obj.Current(Intersect));
                                else
                                    current_coefficient = 1;
                                end
                                current = current .* current_coefficient;
                            end
                        end
                        E = obj.Devices(position).Switching_Loss('Switch_Eoff', current, ...
                            'V', obj.Switching_Voltage(position), 'Tj', obj.Tj{position}(1));
                        obj.Switch_Eoff(position, Intersect) = E;
                        if obj.Devices(position).Type == DeviceType.IGBT
                            E = obj.Devices(position).Recovery_Loss(current, obj.Switching_Voltage(position), ...
                                obj.Tj{position}(2));
                            obj.Recovery(position, Intersect) = E;
                        end
                    end
                end
            end
            % 记录已经计算过的开通时刻
            SwitchON_record(bias:bias+length(SwitchON_pp)-1) = SwitchON_pp;
            bias = bias + length(SwitchON_pp);
            if bias > length(SwitchON_record)
                break;
            end
        end
    end
end
obj.Switch_Eon = obj.Switch_Eon ./ obj.Ts;
obj.Switch_Eoff = obj.Switch_Eoff ./ obj.Ts;
obj.Recovery = obj.Recovery ./ obj.Ts;
end
