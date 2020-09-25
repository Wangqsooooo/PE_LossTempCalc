function Conduction_Losses_Calc(obj)
if ~isempty(obj.Device_InParallel)
    obj.Current_Coefficient_Calc();
end
% 初始化, 将Forward Reverse全部清零
obj.Forward = zeros(size(obj.Control));
obj.Reverse = zeros(size(obj.Control));
if ~isempty(obj.Simplified_Path)
    path = obj.Simplified_Path; count = 0;
else
    path = obj.Path; obj.Simplified_Path = zeros(size(path)); count = 1;
end
for i = 1:size(path, 1)
    logic = obj.Control(abs(path(i, 1)), :);
    for j = 2:find(path(i, 1:end-2)==0, 1)-1
        logic = logic & obj.Control(abs(path(i, j)), :);
    end
    % 有可能存在多电流的通路, 这些情况需要排除
    % 例子: three-level ANPC电路中 [S2 S5], [S3 S6], [S2 S3 S5 S6]开通时输出均为零
    % 对于单电流通路[S2 S5]的情况来说, 上面的代码能保证[S2 S5]均是导通的
    % 但是不能保证[S3 S6]这条电流通路不同, 下面的部分就是为了去除这样的情况
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
                    logic = logic & ~obj.Control(abs(off_device(m)), :);
                end
                break;
            end
        end
    end
    if count > 0
        if any(logic)
            obj.Simplified_Path(count, :) = path(i, :);
            count = count + 1;
        else
            continue % 如果全零, 则该条电流通路实际并没有出现, 可以跳过下面的导通损耗计算
        end
    end
    % 损耗计算
    current = obj.Current .* logic ./ floor(path(i, end));
    for j = 1:find(path(i, 1:end-2)==0, 1)-1
        position = abs(path(i, j)); current_coefficient = 1;
        if path(i, end) - floor(path(i, end)) > 0.4 % 存在器件层面混合情况下最后一列都是.5结尾的
            pdevices_potential = find(obj.Device_InParallel(position, :)~=0);
            if ~isempty(pdevices_potential)
                pdevices_real = sum(abs(path(i,1:end-2))==pdevices_potential(:), 2);
                pdevices_real = pdevices_real' .* pdevices_potential;
                pdevices_real(pdevices_real==0) = [];
                if ~isempty(pdevices_real)
                    F = obj.Device_InParallel_Coefficient(num2str([position, pdevices_real]));
                    current_coefficient = F(sign(path(i, j)) .* current);
                end
            end
        end
        [forward, reverse] = obj.Devices(position).Conduction_Loss(sign(path(i, j)) ...
            .*current./obj.Parallel_Nums(position).*current_coefficient, obj.Tj{position});
        obj.Forward(position, :) = obj.Forward(position, :) + forward;
        obj.Reverse(position, :) = obj.Reverse(position, :) + reverse;
    end
end
obj.Simplified_Path(obj.Simplified_Path(:, end)==0, :) = [];
end
