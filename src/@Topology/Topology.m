classdef Topology < handle
    properties(Constant)
        HB_G = graph([1 1 2], [2 3 3]); % ���Žṹͼ
        HB_G_split = graph([1 1 2 3], [2 4 3 4]); % Ҳ�ǰ��Žṹͼ, ��ѹ�ѱ�Ϊ��������, �������Զ��һ�����ѹ�ڵ�
    end
    properties(SetAccess = private, GetAccess = public)
        RawData % �����ļ��ĵ�ַ
        HB_Restriction % ���Žṹ����
                       % ������ɰ��Žṹ���е�ѹ֧�ŵ��������ӵ����, ��ɰ��Žṹ���������Ӳ���ֱͨ
        Path % ����ͨ·����
        Device_InParallel % �����Ϲ��ɲ������������
        Nums % ��������������
        Type % ��������, ��TopologyType�е�һ��
        Order % �������ļ���������, �п���������������Ѿ������������, ����TopologyType�е�һ��
              % ��������������п��ܻ���ڲ��, Order�������������Ѷ������˵�������ŵĶ�Ӧ���
    end
    
    methods
        function obj = Topology(options)
            arguments
                options.Data struct = struct([])
                options.Filename (1, 1) string = 'TwoLevel_HalfBridge.txt'
                options.Topology TopologyType = TopologyType.Unknown
            end
            
            if options.Topology == TopologyType.Unknown
                % �ж������Ƿ����Ѷ��������, ��TopologyType�е�һ��
                if isempty(options.Data)
                    obj.RawData = importdata(options.Filename);
                    data = obj.RawData;
                else
                    obj.RawData = options.Data;
                    data = obj.RawData;
                end
                s = str2double(data.textdata(1:end-1, 1))';
                t = str2double(data.textdata(1:end-1, 2))';
                type = cell2mat(data.textdata(1:end-1, 3))';
                % ������ͼ��ʾ, ���ڵ�֮���ǵ�ѹ��ֻ�д��������ļ�ͷ, ��Ϊ����������������������ͷ
                source = find(type=='V');
                extra_s = (data.data(source)>=0)' .* t(source) + (data.data(source)<0)' .* s(source);
                extra_t = (data.data(source)>=0)' .* s(source) + (data.data(source)<0)' .* t(source);
                G = digraph([s, t], [t, s]);
                G = rmedge(G, extra_s, extra_t);
                obj.Type = TopologyType.Unknown; obj.Order = [];
                topotype = enumeration('TopologyType');
                for i = 1:size(topotype, 1)
                    if topotype(i) ~= TopologyType.Unknown && topotype(i).isDefinedTopologyGraph(G, 1)
                        obj.Type = topotype(i); order = topotype(i).isDefinedTopologyGraph(G, 2);
                        device_order = (s==order(:, 1) & t==order(:, 2)) | (s==order(:, 2) & t==order(:, 1));
                        device_order_row = size(device_order, 1);
                        obj.Order = zeros(device_order_row, 1);
                        for j = 1:device_order_row
                            obj.Order(j) = data.data(device_order(j, :));
                        end
                    end
                end
            else
                [obj.RawData, obj.Order] = options.Topology.DefinedTopologyPathAndOrder();
                obj.Type = options.Topology;
            end
            obj.Topology_Explanation(); % ��� HB_Restriction��Path
                                        % ˳����� Nums
        end
        
        Topology_Explanation(obj);
    end
end
