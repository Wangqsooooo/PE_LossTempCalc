function Temperature_Losses_Calc(obj, Zthha, Phase, options)
arguments
    obj, Zthha
    Phase (1, 1) string {mustBeMember(Phase, {'SinglePhase', 'ThreePhase'})} = 'ThreePhase'
    options.CalcMode (1, 1) string {mustBeMember(options.CalcMode, {'RealTime', 'Average'})} = 'Average'
    options.PhaseB Losses = Losses()
    options.PhaseC Losses = Losses()
end

if isa(Zthha, 'cell')
    Zthha = cell2mat(Zthha);
end
Rthha = sum(Zthha(1:2:end));
if strcmp(options.CalcMode, 'Average') && isempty(options.PhaseB.Forward) && isempty(options.PhaseC.Forward)
    [Rthjc, RDthjc, Rthch] = Get_Rth(obj);
    Amp = strcmp(Phase, 'SinglePhase') * 1 + strcmp(Phase, 'ThreePhase') * 3;
    last_Tjunction = obj.Init_JunctionTemperature .* ones(1, size(obj.Control, 1));
    last_TDjunction = last_Tjunction;
    while 1
        obj.Conduction_Losses_Calc();
        obj.Switching_Losses_Calc();
        device_loss = sum(obj.Device_Loss, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums';
        diode_loss = sum(obj.Diode_Loss, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums';
        Theatsink = obj.Tambient + Amp * Rthha * sum(device_loss+diode_loss);
        Tcase = Theatsink + (device_loss+diode_loss)' .* Rthch ./ obj.Parallel_Nums;
        Tjunction = Tcase + device_loss' .* Rthjc ./ obj.Parallel_Nums;
        TDjunction = Tcase + diode_loss' .* RDthjc ./ obj.Parallel_Nums;
        obj.JunctionTemperatureSet(Tjunction, TDjunction);
        if all(abs(Tjunction-last_Tjunction)<obj.Threshold, 'all') && all(abs(TDjunction-last_TDjunction)<obj.Threshold, 'all')
            break;
        else
            last_Tjunction = Tjunction; last_TDjunction = TDjunction;
        end
    end
    obj.Theatsink = Theatsink; obj.Tcase = Tcase;
elseif ~isempty(options.PhaseB.Forward) && ~isempty(options.PhaseC.Forward)
    if strcmp(options.CalcMode, 'Average')
        [Rthjc_PhaseA, RDthjc_PhaseA, Rthch_PhaseA] = Get_Rth(obj);
        [Rthjc_PhaseB, RDthjc_PhaseB, Rthch_PhaseB] = Get_Rth(options.PhaseB);
        [Rthjc_PhaseC, RDthjc_PhaseC, Rthch_PhaseC] = Get_Rth(options.PhaseC);
        Rthjc = [Rthjc_PhaseA; Rthjc_PhaseB; Rthjc_PhaseC];
        RDthjc = [RDthjc_PhaseA; RDthjc_PhaseB; RDthjc_PhaseC];
        Rthch = [Rthch_PhaseA; Rthch_PhaseB; Rthch_PhaseC];
        last_Tjunction = obj.Init_JunctionTemperature .* ones(3, size(obj.Control, 1));
        last_TDjunction = last_Tjunction;
        while 1
            obj.Conduction_Losses_Calc(); options.PhaseB.Conduction_Losses_Calc(); options.PhaseC.Conduction_Losses_Calc();
            obj.Switching_Losses_Calc(); options.PhaseB.Switching_Losses_Calc(); options.PhaseC.Switching_Losses_Calc();
            device_loss = [sum(obj.Device_Loss, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums', ...
                           sum(options.PhaseB.Device_Loss, 2) .* options.PhaseB.Ts ./ options.PhaseB.T .* options.PhaseB.Parallel_Nums', ...
                           sum(options.PhaseC.Device_Loss, 2) .* options.PhaseC.Ts ./ options.PhaseC.T .* options.PhaseC.Parallel_Nums'];
            diode_loss = [sum(obj.Diode_Loss, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums', ...
                          sum(options.PhaseB.Diode_Loss, 2) .* options.PhaseB.Ts ./ options.PhaseB.T .* options.PhaseB.Parallel_Nums', ...
                          sum(options.PhaseC.Diode_Loss, 2) .* options.PhaseC.Ts ./ options.PhaseC.T .* options.PhaseC.Parallel_Nums'];
            Theatsink = obj.Tambient + Rthha * sum(device_loss+diode_loss, 'all');
            Tcase = Theatsink + (device_loss+diode_loss)' .* Rthch ./ [obj.Parallel_Nums; options.PhaseB.Parallel_Nums; options.PhaseC.Parallel_Nums];
            Tjunction = Tcase + device_loss' .* Rthjc ./ [obj.Parallel_Nums; options.PhaseB.Parallel_Nums; options.PhaseC.Parallel_Nums];
            TDjunction = Tcase + diode_loss' .* RDthjc ./ [obj.Parallel_Nums; options.PhaseB.Parallel_Nums; options.PhaseC.Parallel_Nums];
            obj.JunctionTemperatureSet(Tjunction(1, :), TDjunction(1, :));
            options.PhaseB.JunctionTemperatureSet(Tjunction(2, :), TDjunction(2, :));
            options.PhaseC.JunctionTemperatureSet(Tjunction(3, :), TDjunction(3, :));
            if all(abs(Tjunction-last_Tjunction)<obj.Threshold, 'all') && all(abs(TDjunction-last_TDjunction)<obj.Threshold, 'all')
                break;
            else
                last_Tjunction = Tjunction; last_TDjunction = TDjunction;
            end
        end
        obj.Theatsink = Theatsink; obj.Tcase = Tcase(1, :);
        options.PhaseB.Theatsink = Theatsink; options.PhaseB.Tcase = Tcase(2, :);
        options.PhaseC.Theatsink = Theatsink; options.PhaseC.Tcase = Tcase(3, :);
    else
        t = 0:obj.Ts:obj.T;
        Nums_Tch = 0; Nums_Tjc = 0; % case-heatsink之间热阻网络的阶数, junction-case之间热阻网络的阶数
        Nums_path = 0; % 热阻网络的路径数目, IGBT器件有两条热阻路径, 一条为器件本身, 另一条为其反并联二极管
                       %                    MOSFET器件只有一条热阻路径
        for i = 1:size(obj.Control, 1)
            Nums_Tch = Nums_Tch + length(obj.Devices(i).Zthch);
            Nums_Tjc = Nums_Tjc + length(obj.Devices(i).Zthjc);
            if obj.Devices(i).Type == DeviceType.IGBT
                Nums_Tjc = Nums_Tjc + length(obj.Devices(i).ZDthjc);
                Nums_path = Nums_path + 2;
            else
                Nums_path = Nums_path + 1;
            end
        end
        delta_Temperature = (obj.Init_JunctionTemperature - obj.Tambient) ./ 3 ...
            .* ones(Nums_Tjc+Nums_Tch+length(Zthha)/2, 1);
%         delta_Temperature = zeros(Nums_Tjc+Nums_Tch+length(Zthha)/2, 1);
        % 热阻网络求解
        Ajc = cell(0); Bjc = cell(0); Cjc = cell(0);
        Ach = cell(0); Bch = cell(0); Cch = cell(0);
        j = 1; parallel = ones(1, Nums_path);
        for i = 1:size(obj.Control, 1)
            [Ajc{j}, Bjc{j}, Cjc{j}, ~] = State_Space_Param(obj.Devices(i).Zthjc);
            Bjc{j} = Bjc{j}(:, 2); parallel(j) = obj.Parallel_Nums(i);
            j = j + 1;
            [Ach{i}, Bch{i}, Cch{i}, ~] = State_Space_Param(obj.Devices(i).Zthch);
            Bch{i} = Bch{i}(:, 2);
            if obj.Devices(i).Type == DeviceType.IGBT
                [Ajc{j}, Bjc{j}, Cjc{j}, ~] = State_Space_Param(obj.Devices(i).ZDthjc);
                Bjc{j} = Bjc{j}(:, 2); parallel(j) = obj.Parallel_Nums(i);
                j = j + 1;
                Bch{i} = [Bch{i}, Bch{i}];
            end
        end
        [Aha, Bha, ~, ~] = State_Space_Param(Zthha); Bha = Bha(:, 2);
        % 求出整个状态空间方程的A, B, C, D系数值
        A = blkdiag(Ajc{:}, Ach{:}, Aha);
        tempBjc = blkdiag(Bjc{:}); tempBch = blkdiag(Bch{:});
        tempB = [tempBjc; tempBch]; B = blkdiag(tempB, Bha);
        B(end-length(Bha)+1:end, 1:end-1) = Bha * parallel;
        C = eye(size(A));
        D = zeros(size(B));
        sys = ss(A, B, C, D);
        % 结温矩阵的系数, 状态空间方程求解得到的结果为每个热容两端的温差 
        % 要想计算得到器件结温或者说散热器的温度, 需要对结温矩阵进行相加
        coefficient_Tjc = zeros(2*size(obj.Control, 1), size(A, 2));
        coefficient_Tch = zeros(size(obj.Control, 1), size(A, 2));
        j = 1; posc1 = 1; posc2 = Nums_Tjc + 1;
        for i = 1:size(obj.Control, 1)
            last_posc1 = posc1; posc1 = posc1 + size(Ajc{j}, 1);
            last_posc2 = posc2; posc2 = posc2 + size(Ach{i}, 1);
            coefficient_Tjc(2*i-1, last_posc1:posc1-1) = ones(1, size(Ajc{j},1));
            coefficient_Tjc(2*i-1, last_posc2:posc2-1) = ones(1, size(Ach{i},1));
            coefficient_Tch(i, last_posc2:posc2-1) = ones(1, size(Ach{i},1));
            j = j + 1;
            if obj.Devices(i).Type == DeviceType.IGBT
                last_posc1 = posc1; posc1 = posc1 + size(Ajc{j}, 1);
                coefficient_Tjc(2*i, last_posc1:posc1-1) = ones(1, size(Ajc{j},1));
                coefficient_Tjc(2*i, last_posc2:posc2-1) = ones(1, size(Ach{i},1));
                j = j + 1;
            else
                coefficient_Tjc(2*i, :) = coefficient_Tjc(2*i-1, :);
            end
        end
        coefficient_Tjc(:, end-size(Aha,1)+1:end) = 1;
        coefficient_Tch(:, end-size(Aha,1)+1:end) = 1;
        coefficient_Tha = zeros(size(Aha, 1), size(A, 2));
        coefficient_Tha(:, end-size(Aha,1)+1:end) = 1;
        % 结温计算
        count1 = 0; count2 = 0;
        last_Tjunction = zeros(1, size(obj.Control, 1));
        last_TDjunction = zeros(1, size(obj.Control, 1));
        % 这个记录的数组太大了, 对于内存小的电脑可能跑不动
        % 对于规模大的电路也可能跑不动
        obj.Tj_Dynamic = zeros(2*size(obj.Control, 1), 10*(size(obj.Control, 2)-1)+1); 
        while 1
            obj.Conduction_Losses_Calc(); options.PhaseB.Conduction_Losses_Calc(); options.PhaseC.Conduction_Losses_Calc();
            obj.Switching_Losses_Calc(); options.PhaseB.Switching_Losses_Calc(); options.PhaseC.Switching_Losses_Calc();
            % 将热阻网络看作是一个整体进行计算, 此时状态空间方程的阶数会很高, 可能有几十阶
            % 但是计算时间并不会指数级上升, 这样一次性计算速度应该是最快的
            device_loss = obj.Device_Loss; diode_loss = obj.Diode_Loss;
            power_input = zeros(Nums_path, size(device_loss, 2)); % A相输入每条热阻路径的瞬时功率
            j = 1;
            for i = 1:size(obj.Control, 1)
                power_input(j, :) = device_loss(i, :); j = j + 1;
                if obj.Devices(i).Type == DeviceType.IGBT
                    power_input(j, :) = diode_loss(i, :); j = j + 1;
                end
            end
            % 求出整个状态空间的输入值
            twophase_loss = sum((options.PhaseB.Forward+options.PhaseB.Reverse+options.PhaseB.Switch_Eon+options.PhaseB.Switch_Eoff+options.PhaseB.Recovery).*options.PhaseB.Parallel_Nums', 1) ...
                + sum((options.PhaseC.Forward+options.PhaseC.Reverse+options.PhaseC.Switch_Eon+options.PhaseC.Switch_Eoff+options.PhaseC.Recovery).*options.PhaseC.Parallel_Nums', 1);
            input = [power_input; twophase_loss];
            Temperature = lsim(sys, input, t, delta_Temperature);
            delta_Temperature = delta_Temperature + Temperature(end, :)' - Temperature(1, :)';
            Tj = coefficient_Tjc * Temperature' + obj.Tambient;
            obj.Tj_Dynamic = circshift(obj.Tj_Dynamic, -size(Tj, 2)+1, 2);
            obj.Tj_Dynamic(:, end-size(Tj, 2)+1:end) = Tj;
            Tjunction = mean(Tj(1:2:end, :), 2); Tjunction = Tjunction';
            TDjunction = mean(Tj(2:2:end, :), 2); TDjunction = TDjunction';
            obj.JunctionTemperatureSet(Tjunction, TDjunction);
            options.PhaseB.JunctionTemperatureSet(Tjunction, TDjunction);
            options.PhaseC.JunctionTemperatureSet(Tjunction, TDjunction);
            if all(abs(Tjunction-last_Tjunction)<0.01, 'all') && all(abs(TDjunction-last_TDjunction)<0.01, 'all')
                count2 = count2 + 1;
            else
                count2 = 0;
            end
            count1 = count1 + 1;
            last_Tjunction = Tjunction; last_TDjunction = TDjunction;
            % 连续超过5次记录到平均结温变化小于0.01, 则跳出
            if count2 > 5
                break
            end
        end
        Tcase = coefficient_Tch * Temperature' + obj.Tambient; obj.Tcase = mean(Tcase, 2)';
        options.PhaseB.Tcase = obj.Tcase; options.PhaseC.Tcase = obj.Tcase;
        Theatsink = coefficient_Tha * Temperature' + obj.Tambient; obj.Theatsink = mean(Theatsink, 2)';
        options.PhaseB.Theatsink = obj.Theatsink; options.PhaseC.Theatsink = obj.Theatsink;
        if count1 < 10
            obj.Tj_Dynamic = obj.Tj_Dynamic(:, end-count1*(size(obj.Control,2)-1):end);
        end
    end
end
end

function [Rthjc, RDthjc, Rthch] = Get_Rth(onephase)
Rthjc = zeros(1, size(onephase.Control, 1));
RDthjc = zeros(1, size(onephase.Control, 1));
Rthch = zeros(1, size(onephase.Control, 1));
for i = 1:size(onephase.Control, 1)
    Rthjc(i) = onephase.Devices(i).Rthjc;
    RDthjc(i) = onephase.Devices(i).RDthjc;
    Rthch(i) = onephase.Devices(i).Rthch;
end
end

function [A, B, C, D] = State_Space_Param(Z)
if isa(Z, 'cell')
    Z = cell2mat(Z);
end
A = -diag(1./Z(2:2:end));
B = zeros(length(Z)/2, 2); B(:, 2) = (Z(1:2:end) ./ Z(2:2:end))';
C = tril(ones(length(Z)/2));
D = ones(length(Z)/2, 1) * [1 0];
end
