function current = Device_FlowingCurrent_Calc(obj, position, path, device_inparallel, current_coefficient, options)
arguments
    obj
    position (1, 1) {mustBeInteger(position), mustBeGreaterThan(position, 0)}
    path
    device_inparallel = []
    current_coefficient = []
    options.Mode (1, 1) string {mustBeMember(options.Mode, {'Fundamental', 'Fundamental_withHarmonic'})} = 'Fundamental_withHarmonic'
end

if ~isempty(find(path(:,end)-floor(path(:,end))>0.4, 1))
    if isempty(device_inparallel) || isempty(current_coefficient)
        error('Please input ''device_inparallel'' and ''current_coefficient'' parameters!');
    end
end
if ~isempty(obj.Current) && position <= size(obj.Control, 1)
    current = zeros(size(obj.Current'));
    for i = 1:size(path, 1)
        if any(abs(path(i, 1:end-2))==position)
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
                            flag = 0;
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
            if ~any(logic)
                continue
            end
            % ��ȡ���λ�ÿ��ع���Ե����ķ���
            direction = abs(path(i, 1:end-2))==position;
            direction = path(i, 1:end-2) .* direction; direction(direction==0) = [];
            if strcmp(options.Mode, 'Fundamental_withHarmonic')
                temp_current = obj.Current' .* logic ./ floor(path(i, end)) .* sign(direction);
            else
                if obj.DC_Component > obj.Fundamental_Component(1) * 0.01
                    warning('Output current contains too much DC component, please give a bigger ''Period'' parameter.');
                end
                 temp_current = obj.Fundamental_Component(1).*sin(2.*pi.*(0:obj.Ts:obj.Period)./obj.T+obj.Fundamental_Component(2)) ...
                    .* logic ./ floor(path(i, end)) .* sign(direction);
            end
            % ��������������Ļ��, ����ȡ����������ϵ��
            if path(i, end) - floor(path(i, end)) > 0.4
                pdevices_potential = find(device_inparallel(position, :)~=0);
                if ~isempty(pdevices_potential)
                    pdevices_real = sum(abs(path(i,1:end-2))==pdevices_potential(:), 2);
                    pdevices_real = pdevices_real' .* pdevices_potential;
                    pdevices_real(pdevices_real==0) = [];
                    if ~isempty(pdevices_real)
                        F = current_coefficient(num2str([position, pdevices_real]));
                        temp_current = temp_current .* F(temp_current);
                    end
                end
            end
            current = current + temp_current;
        end
    end
elseif position > size(obj.Control, 1)
    error('There is only %d switches, %d is out of range!', size(obj.Control, 1), position);
else
    error('No current information available. Please calculate output current first!');
end
end
