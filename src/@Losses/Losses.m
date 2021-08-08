classdef Losses < handle
    properties(Constant)
        Tambient = 25
        Threshold = 0.5
        Init_JunctionTemperature = 85
    end
    properties(SetAccess = private, GetAccess = public)
        T % ����
        Ts % ʱ�侫��
        Current
        Control
        Path % ����ͨ·����
        Device_InParallel % ����������ڲ������������
        Device_InParallel_Coefficient % ��������֮��ĵ�������ϵ��
        Simplified_Path % �õ��Ʒ�����ʵ�ʴ��ڵĵ���ͨ·��ɵľ���
                        % ��Path����ɾ��һЩ����·����õ��ļ򻯾���
        Devices
        Parallel_Nums
        Switching_Voltage
        Rg % ��������
        Theatsink % ɢ�����¶�
        Tcase % ����
        Tj % ����
        Tj_Dynamic % ��̬����
        Forward % ����ͨ���
        Reverse % ����ͨ���
        Switch_Eon % ��ͨ���
        Switch_Eoff % �ض����
        Recovery % ����ָ����
    end
    properties(Dependent)
        Device_Loss % �����ϲ��������
        Diode_Loss % �����������������ϲ��������
                   % ����IBGT�м��������������ܵ�ɢ�����衢������������һ��, �������Ҫ�ֿ�
                   % MOSFET��CoolMOSû�зֿ�
        % ����MOSFET��CoolMOS, Device_Loss = Forward + Reverse + Switch_Eon + Switch_Eoff
        %                     Diode_Loss = 0, Recovery = 0 (û�з���ָ����) 
        % ����IGBT, Device_Loss = Forward + Switch_Eon + Switch_Eoff
        %          Diode_Loss = Reverse + Recovery
        
        Loss % ��Ľ��
    end
    
    methods
        function obj = Losses(T, Ts, current, control, path, devices, parallel_nums, switching_voltage, Rg, device_inparallel)
            if nargin >= 9
                obj.T = T; obj.Ts = Ts;
                obj.Current = current';
                obj.Control = control;
                obj.Devices = devices;
                obj.Parallel_Nums = parallel_nums;
                obj.Switching_Voltage = switching_voltage;
                obj.Rg = Rg;
                % ���³�ʼ��
                obj.Tj = cell(size(obj.Control, 1), 1);
                obj.JunctionTemperatureSet(obj.Init_JunctionTemperature);
                % ��ĳ�ʼ��
                obj.Forward = zeros(size(obj.Control));
                obj.Reverse = zeros(size(obj.Control));
                obj.Switch_Eon = zeros(size(obj.Control));
                obj.Switch_Eoff = zeros(size(obj.Control));
                obj.Recovery = zeros(size(obj.Control));
                % �������еĵ���ͨ·
                % ��path���һ��ȫ��������ʱ��ͬ��obj.Path=path
                position = find(path(:, end)'>0);
                if length(position) == size(path, 1)
                    obj.Path = path;
                else
                    if nargin == 10
                        obj.Device_InParallel = device_inparallel;
                    else
                        error('Please enter one more input named ''device_inparallel''!');
                    end
                    max = 128;
                    row = (2^(size(path,2)-2)>max)*max + (2^(size(path,2)-2)<=max)*2^(size(path,2)-2); % ���Ե���2^(n-2)������
                    obj.Path = zeros(row, size(path,2)); 
                    dif = diff([position size(path,1)+1]);
                    count = 1;
                    for i = 1:length(position)
                        num = find(path(position(i),:)==0, 1)-1;
                        array = cell(1, num);
                        for j = 1:num
                            array{j} = path(position(i):position(i)+dif(i)-1, j)';
                        end
                        perm_result = obj.perm(array{:});
                        obj.Path(count:count+size(perm_result,1)-1, 1:size(perm_result,2)) = perm_result;
                        obj.Path(count:count+size(perm_result,1)-1, end-1:end) = ones(size(perm_result,1),1) * path(position(i), end-1:end) + 0.5 .* (sum(perm_result~=0,2)>num) * [0 1];
                        count = count + size(perm_result,1);
                    end
                    obj.Path(obj.Path(:, end)==0, :) = [];
                end
            end
        end
        
        function JunctionTemperatureSet(obj, T, TD)
            arguments
                obj, T
                TD (1, :) double = -100
            end
            
            if isa(T, 'double') && length(T) == 1 && TD == -100
                for i = 1:size(obj.Control, 1)
                    if obj.Devices(i).Type == DeviceType.IGBT
                        obj.Tj{i} = [T, T];
                    else
                        obj.Tj{i} = T;
                    end
                end
            elseif isa(T, 'double') && length(T) == size(obj.Control, 1) && length(TD) == size(obj.Control, 1)
                for i = 1:size(obj.Control, 1)
                    if obj.Devices(i).Type == DeviceType.IGBT
                        obj.Tj{i} = [T(i), TD(i)];
                    else
                        obj.Tj{i} = T(i);
                    end
                end
            elseif isa(T, 'cell') && length(T) == size(obj.Control, 1)
                obj.Tj = T;
            else
                error('Wrong format! Error in input parameter ''Temperature''.');
            end
        end
        % ������������������¸����������ĵ����������
        function Current_Coefficient_Calc(obj)
            max_current = max(obj.Current); sample_nums = 201; % ��Ҫ����Ϊ����
            obj.Device_InParallel_Coefficient = containers.Map;
            for i = 1:size(obj.Device_InParallel,1)
                position = find(obj.Device_InParallel(i, :)~=0);
                if ~isempty(position)
                    current_range = linspace(-max_current/(length(position)+1), max_current/(length(position)+1), sample_nums);
                    reci_range = 1 ./ current_range; reci_range(reci_range==Inf) = 0;
                    record1 = zeros(length(position)+1, sample_nums);
                    record2 = record1;
                    [record1(1, :), record2(1, :)] = obj.Devices(i).Conduction_Loss(current_range...
                        ./obj.Parallel_Nums(i), obj.Tj{i});
                    record1(1, :) = record1(1, :) .* reci_range .* obj.Parallel_Nums(i);
                    record2(1, :) = record2(1, :) .* reci_range .* obj.Parallel_Nums(i);
                    for j = 1:length(position)
                        if full(obj.Device_InParallel(i,position(j))) == 1
                            [record1(j+1, :), record2(j+1, :)] = obj.Devices(position(j)).Conduction_Loss(current_range...
                                ./obj.Parallel_Nums(position(j)), obj.Tj{position(j)});
                        else
                            [record2(j+1, :), record1(j+1, :)] = obj.Devices(position(j)).Conduction_Loss(current_range...
                                ./obj.Parallel_Nums(position(j)), obj.Tj{position(j)});
                            record1(j+1, :) = record1(j+1, end:-1:1);
                            record2(j+1, :) = record2(j+1, end:-1:1);
                        end
                        record1(j+1, :) = record1(j+1, :) .* reci_range .* obj.Parallel_Nums(position(j));
                        record2(j+1, :) = record2(j+1, :) .* reci_range .* obj.Parallel_Nums(position(j));
                    end
                    
                    voltage_range1 = max(max(record1, [], 2));
                    voltage_range2 = min(min(record2, [], 2));
                    voltage_range = linspace(voltage_range2, voltage_range1, sample_nums);
                    sum_current = zeros(1, sample_nums); j = 1;
                    while j <= length(position)+1
                        if ~any(record2(j, :)) % record2(j, :)ȫ������0�����, �������Ϊ����������Diode��IGBT�����
                            F = griddedInterpolant(record1(j, fix(sample_nums/2+1):sample_nums), ...
                                current_range(fix(sample_nums/2+1):sample_nums));
                            sum_current = sum_current + F(voltage_range.*(voltage_range>=0));
                        elseif ~any(record1(j, :)) % record1(j, :)ȫ������0�����, �������ΪIGBT����������Diode�ҷ����������
                            F = griddedInterpolant(record2(j, 1:fix(sample_nums/2+1)), ...
                                current_range(1:fix(sample_nums/2+1)));
                            sum_current = sum_current + F(voltage_range.*(voltage_range<0));
                        else
                            F = griddedInterpolant(record1(j,:)+record2(j,:), current_range);
                            sum_current = sum_current + F(voltage_range);
                        end
                        if j == 1
                            current = sum_current;
                        end
                        j = j + 1;
                    end
                    F = griddedInterpolant(sum_current, current./sum_current);
                    obj.Device_InParallel_Coefficient(num2str([i, position])) = F;
                end
            end
        end
        Conduction_Losses_Calc(obj);
        Switching_Losses_Calc(obj);
        Temperature_Losses_Calc(obj);
        
        function Device_Loss = get.Device_Loss(obj)
            Device_Loss = zeros(size(obj.Forward));
            for i = 1:size(obj.Control, 1)
                if obj.Devices(i).Type == DeviceType.IGBT
                    Device_Loss(i, :) = obj.Forward(i, :) + obj.Switch_Eon(i, :) + obj.Switch_Eoff(i, :);
                else
                    Device_Loss(i, :) = obj.Forward(i, :) + obj.Reverse(i, :) + ...
                        obj.Switch_Eon(i, :) + obj.Switch_Eoff(i, :);
                end
            end
        end
        function Diode_Loss = get.Diode_Loss(obj)
            Diode_Loss = zeros(size(obj.Forward));
            for i = 1:size(obj.Control, 1)
                if obj.Devices(i).Type == DeviceType.IGBT
                    Diode_Loss(i, :) = obj.Reverse(i, :) + obj.Recovery(i, :);
                end
            end
        end
        function Loss = get.Loss(obj)
            Loss = [sum(obj.Forward, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums'; ...
                sum(obj.Reverse, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums'; ...
                sum(obj.Switch_Eon, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums'; ...
                sum(obj.Switch_Eoff, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums'; ...
                sum(obj.Recovery, 2) .* obj.Ts ./ obj.T .* obj.Parallel_Nums'];
        end
    end
    
    methods(Access = private)
        function result = perm(obj, array)
            arguments
                obj
            end
            arguments (Repeating)
                array (1, :) double
            end
            if nargin > 2
                temp_result = obj.perm(array{2:nargin-1});
                temp_array = array{1};
                temp_array(temp_array==0) = [];
                num = size(temp_array, 2); count = 1;
                [row, col] = size(temp_result);
                result = zeros((2^num-1)*row, num+col);
                for i = 1:num
                    opts = nchoosek(temp_array, i);
                    for j = 1:size(opts, 1)
                        result(count+row*(j-1):count+row*j-1, 1:size(opts(j,:),2)+col) = [ones(row, 1)*opts(j,:) temp_result];
                    end
                    count = count + row*size(opts, 1);
                end
            else
                temp_array = array{1};
                temp_array(temp_array==0) = [];
                num = size(temp_array, 2); count = 1;
                result = zeros(2^num-1, num);
                for i = 1:num
                    opts = nchoosek(temp_array, i);
                    result(count:count+size(opts,1)-1, 1:size(opts,2)) = opts;
                    count = count + size(opts, 1);
                end
            end
        end
    end
end
