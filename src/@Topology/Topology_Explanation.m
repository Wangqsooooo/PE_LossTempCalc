function Topology_Explanation(obj)
data = obj.RawData;
% 搜索拓扑中所有具有电压支撑的半桥结构
s = str2double(data.textdata(1:end-1, 1))';
t = str2double(data.textdata(1:end-1, 2))';
type = cell2mat(data.textdata(1:end-1, 3))';
G = graph(s, t);
% 部分连接电压的节点组合, 考虑到为了得到零电压节点, 可能会将一个电压拆成两个串联的电压
% 因此还要寻找到两个串联的电压节点组合, 如在两电平半桥结构中, 为了得到零电压节点就需要多插入一个节点
Vnode_part = [s(type=='V')', t(type=='V')'];
if size(Vnode_part, 1) == 1
    Vnode_more = [];
else
    Vnode_more = nchoosek(1:size(Vnode_part, 1),2);
end
Vnode = zeros(size(Vnode_part, 1)+size(Vnode_more, 1), 3);
Vnode(1:size(Vnode_part, 1), 1:2) = Vnode_part; count = size(Vnode_part, 1);
for k = 1:size(Vnode_more, 1)
    i = Vnode_more(k, 1); j = Vnode_more(k, 2);
    if length(unique([Vnode_part(i, :), Vnode_part(j, :)])) == 3
        count = count + 1;
        Vnode(count, :) = [setdiff([Vnode_part(i, :), Vnode_part(j, :)], intersect(Vnode_part(i, :), Vnode_part(j, :))) ...
            intersect(Vnode_part(i, :), Vnode_part(j, :))];
    end
end
Vnode(Vnode(:, 1)==0, :) = []; % 去除全零行
nodes_num = max([s, t]);
obj.HB_Restriction = zeros(100, 2); count = 1;
for l = 1:size(Vnode, 1)
    i = Vnode(l, 1); j = Vnode(l, 2); n = Vnode(l, 3);
    for k = find(1:nodes_num~=i & 1:nodes_num~=j & 1:nodes_num~=n)
        if n ~= 0
            Gsub = subgraph(G, [i, j, k, n]);
        else
            Gsub = subgraph(G, [i, j, k]);
        end
        if isisomorphic(obj.HB_G, Gsub) || isisomorphic(obj.HB_G_split, Gsub)
            device1 = (s==i & t==k) | (t==i & s==k);
            device1 = data.data(device1);
            device2 = (s==j & t==k) | (t==j & s==k);
            device2 = data.data(device2);
            obj.HB_Restriction(count, :) = [device1, device2];
            count = count + 1;
        end
    end
end
obj.HB_Restriction(obj.HB_Restriction(:, 1)==0, :) = []; % 去除全零行
% 搜索拓扑中从gnd到output所有可能的路径
path = Search_Path(data);
path = sortrows(path, size(path, 2)); i = 1;
switch_nums = max(data.data(type=='S')); obj.Nums = switch_nums;
obj.Device_InParallel = sparse(obj.Nums, obj.Nums);
obj.Path = zeros([size(path, 1)+20, switch_nums+2]); count = 1;
while 1
    equal_nums = sum(path(:, end)==path(i, end));
    for j = i:i+equal_nums-1
        l = 1; max_length = 1;
        for k = 1:size(path, 2)-2
            element1 = s==path(j, k) & t==path(j, k+1);
            element2 = s==path(j, k+1) & t==path(j, k);
            if any(element1) && ~any(element2)
                if any(type(element1)=='S')
                    le = length(data.data(element1));
                    if le > max_length
                        max_length = le;
                    end
                    % 如果拓扑中没有构成并联的器件, 那么只有下面两句是有效的
                    temp_data = data.data(element1);
                    obj.Path(count:count+le-1, l) = -temp_data; l = l + 1;
                    % 若拓扑中存在并联的器件, 那么创建关联矩阵
                    if le > 1
                        if ~isequal(find(obj.Device_InParallel(temp_data(1), :)), temp_data(2:end)')
                            temp_device_inparallel = zeros(obj.Nums, obj.Nums);
                            for m = 2:le
                                temp_device_inparallel(temp_data(m-1), temp_data(m:le)) = 1;
                            end
                            temp_device_inparallel = temp_device_inparallel + temp_device_inparallel';
                            obj.Device_InParallel = obj.Device_InParallel + sparse(temp_device_inparallel);
                        end
                    end
                end
            elseif any(element2) && ~any(element1)
                if any(type(element2)=='S')
                    le = length(data.data(element2));
                    if le > max_length
                        max_length = le;
                    end
                    temp_data = data.data(element2);
                    obj.Path(count:count+le-1, l) = temp_data; l = l + 1;
                    if le > 1
                        if ~isequal(find(obj.Device_InParallel(temp_data(1), :)), temp_data(2:end)')
                            temp_device_inparallel = zeros(obj.Nums, obj.Nums);
                            for m = 2:le
                                temp_device_inparallel(temp_data(m-1), temp_data(m:le)) = 1;
                            end
                            temp_device_inparallel = temp_device_inparallel + temp_device_inparallel';
                            obj.Device_InParallel = obj.Device_InParallel + sparse(temp_device_inparallel);
                        end
                    end
                end
            elseif any(element1) && any(element2)
                if any(type(element1)=='S') && any(type(element2)=='S')
                    le = length(data.data(element1)) + length(data.data(element2));
                    if le > max_length
                        max_length = le;
                    end
                    temp1_data = data.data(element1); temp2_data = data.data(element2);
                    obj.Path(count:count+le-1, l) = [-temp1_data; temp2_data]; l = l + 1;
                    temp_data = [temp1_data; temp2_data];
                    if ~isequal(find(obj.Device_InParallel(temp_data(1), :)), temp_data(2:end)')
                        n = length(temp1_data);
                        temp_device_inparallel = zeros(obj.Nums, obj.Nums);
                        for m = 2:le
                            if m-1 <= n
                                temp_device_inparallel(temp_data(m-1), temp_data(m:n)) = 1;
                                temp_device_inparallel(temp_data(m-1), temp_data(n+1:le)) = -1;
                            else
                                temp_device_inparallel(temp_data(m-1), temp_data(m:le)) = 1;
                            end
                        end
                        temp_device_inparallel = temp_device_inparallel + temp_device_inparallel';
                        obj.Device_InParallel = obj.Device_InParallel + sparse(temp_device_inparallel);
                    end
                end
            end
        end
        obj.Path(count:count+max_length-1, end-1) = path(j, end);
        obj.Path(count, end) = 1;
        if max_length > 1
            obj.Path(count+1:count+max_length-1, end) = -1;
        end
        count = count + max_length;
    end
    if equal_nums == 1
        i = i + 1;
    elseif equal_nums > 1
        real_c = find(obj.Path(:, end)>0);
        for j = 2:equal_nums
            c = nchoosek(i:i+equal_nums-1, j);
            for k = 1:size(c, 1)
                raw = obj.Path(real_c(c), 1:end-2); raw = raw(:)'; raw = raw(raw~=0);
                processed = unique(raw);
                if length(raw)-length(processed) == 0 && Short_Circuit_SymbolCheck(obj.HB_Restriction, processed)
                    obj.Path(count, 1:length(processed)) = processed;
                    obj.Path(count, end-1) = path(i, end); obj.Path(count, end) = j;
                    max_length = 1;
                    for m = 1:length(processed)
                        record_device_inparallel = find(full(obj.Device_InParallel(abs(processed(m)), :)));
                        record_device_inparallel = full(obj.Device_InParallel(abs(processed(m)), record_device_inparallel)) ...
                            .* record_device_inparallel;
                        if ~isempty(record_device_inparallel)
                            obj.Path(count+1:count+length(record_device_inparallel), m) = sign(processed(m)) .* record_device_inparallel';
                            if length(record_device_inparallel)+1 > max_length
                                max_length = length(record_device_inparallel)+1;
                            end
                        end
                    end
                    obj.Path(count+1:count+max_length-1, end-1) = obj.Path(count, end-1);
                    obj.Path(count+1:count+max_length-1, end) = -1;
                    count = count + max_length;
                end
            end
        end
        i = i + equal_nums;
    end
    if i > size(path, 1)
        break
    end
end
obj.Path(obj.Path(:, end)==0, :) = [];
end

function result_path = Search_Path(data)
% 预处理
if strcmp(data.textdata{end, 1}, 'gnd') && strcmp(data.textdata{end, 3}, 'output')
    gnd = str2double(data.textdata{end, 2});
    output = data.data(end);
elseif strcmp(data.textdata{end, 3}, 'gnd') && strcmp(data.textdata{end, 1}, 'output')
    gnd = data.data(end);
    output = str2double(data.textdata{end, 2});
else
    error('GND or Output is missing!');
end
nodedata = str2double(data.textdata(1:end-1, 1:2));
row = max(max(nodedata));
circuit_matrix = zeros(row);
[line_num, ~] = size(data.textdata(1:end-1, :));
for i = 1:line_num
    circuit_matrix(nodedata(i, 1), nodedata(i, 2)) = 1;
    circuit_matrix(nodedata(i, 2), nodedata(i, 1)) = 1;
end
% 路径寻找
stack = zeros(1, row); % 堆栈
for i = 1:row
    eval(['n', num2str(i), '=', 'Node(', num2str(i), ')', ';']);
    if any(output==i)
        eval(['n', num2str(i), '.type', '=', 'NodeType.Output', ';']);
    elseif any(gnd==i)
        eval(['n', num2str(i), '.type', '=', 'NodeType.Gnd', ';']);
        stack(1) = i; % gnd为初始起点
    end
end
for i = 1:row
    for j = 1:row
        if circuit_matrix(i, j) ~= 0
            eval(['n', num2str(i), '.connect(', 'n', num2str(j), ')', ';']);
        end
    end
end
eval(['h', '=', 'n', num2str(stack(1)), ';']);
path = zeros(100, row+1); % 假设路径不超过100条, 一般不会超出
[~, path(:, 1:end-1)] = DFSA(h, stack, path(:, 1:end-1));
path(path(:, 1)==0, :) = []; % 删除全零行, 保留有效路径
s = str2double(data.textdata(1:end-1, 1))';
t = str2double(data.textdata(1:end-1, 2))';
type = cell2mat(data.textdata(1:end-1, 3))';
for i = 1:size(path, 1)
    for j = 1:row-1
        if path(i, j+1)~=0
            element1 = s==path(i, j) & t==path(i, j+1);
            element2 = s==path(i, j+1) & t==path(i, j);
            if any(element1) && all(type(element1)=='V')
                path(i, end) = path(i, end) + data.data(element1);
            elseif any(element2) && all(type(element2)=='V')
                path(i, end) = path(i, end) - data.data(element2);
            end
        end
    end
end

result_path = path;
end

function flag = Short_Circuit_SymbolCheck(restriction, processed)
for i = 1:size(restriction, 1)
    if any(processed==restriction(i, 1)) && any(processed==restriction(i, 2))
        flag = false;
    else
        flag = true;
    end
end
end

% 图的深度优先搜索
function [result, path] = DFSA(node, stack, p)
for i = 1:node.connection_nums
    next = node.connection(num2str(i));
    h = next{1};
    if ~any(stack==h.index)
        stack = circshift(stack, 1); stack(1) = h.index;
        [stack, p] = DFSA(h, stack, p);
        if h.type == NodeType.Output
            path = stack; path = circshift(path, 1); path(1) = h.index;
            p = circshift(p, [1 0]); p(1, :) = path;
        end
    end
end
stack(1) = 0; stack = circshift(stack, -1);
result = stack;
path = p;
end
