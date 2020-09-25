function Conduction_Losses_Calc(obj)
if ~isempty(obj.Device_InParallel)
    obj.Current_Coefficient_Calc();
end
% ��ʼ��, ��Forward Reverseȫ������
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
    % �п��ܴ��ڶ������ͨ·, ��Щ�����Ҫ�ų�
    % ����: three-level ANPC��·�� [S2 S5], [S3 S6], [S2 S3 S5 S6]��ͨʱ�����Ϊ��
    % ���ڵ�����ͨ·[S2 S5]�������˵, ����Ĵ����ܱ�֤[S2 S5]���ǵ�ͨ��
    % ���ǲ��ܱ�֤[S3 S6]��������ͨ·��ͬ, ����Ĳ��־���Ϊ��ȥ�����������
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
            continue % ���ȫ��, ���������ͨ·ʵ�ʲ�û�г���, ������������ĵ�ͨ��ļ���
        end
    end
    % ��ļ���
    current = obj.Current .* logic ./ floor(path(i, end));
    for j = 1:find(path(i, 1:end-2)==0, 1)-1
        position = abs(path(i, j)); current_coefficient = 1;
        if path(i, end) - floor(path(i, end)) > 0.4 % ����������������������һ�ж���.5��β��
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
