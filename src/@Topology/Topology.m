classdef Topology < handle
    properties(Constant)
        HB_G = graph([1 1 2], [2 3 3]); % 半桥结构图
        HB_G_split = graph([1 1 2 3], [2 4 3 4]); % 也是半桥结构图, 电压裂变为两个串联, 这样可以多出一个零电压节点
    end
    properties(SetAccess = private, GetAccess = public)
        RawData % 输入文件的地址
        HB_Restriction % 半桥结构限制
                       % 储存组成半桥结构且有电压支撑的两个管子的序号, 组成半桥结构的两个管子不能直通
        Path % 电流通路矩阵
        Device_InParallel % 拓扑上构成并联的器件编号
        Nums % 开关器件的数量
        Type % 拓扑类型, 是TopologyType中的一种
        Order % 对于用文件输入的情况, 有可能输入的拓扑是已经定义过的拓扑, 即是TopologyType中的一种
              % 但是其器件标号有可能会存在差别, Order是输入拓扑与已定义拓扑的器件标号的对应情况
    end
    
    methods
        function obj = Topology(options)
            arguments
                options.Data struct = struct([])
                options.Filename (1, 1) string = 'TwoLevel_HalfBridge.txt'
                options.Topology TopologyType = TopologyType.Unknown
            end
            
            if options.Topology == TopologyType.Unknown
                % 判断拓扑是否是已定义的拓扑, 即TopologyType中的一种
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
                % 用有向图表示, 两节点之间是电压则只有从正到负的箭头, 若为开关器件则有正反两个箭头
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
            obj.Topology_Explanation(); % 求出 HB_Restriction、Path
                                        % 顺便给出 Nums
        end
        
        Topology_Explanation(obj);
    end
end
