classdef Node < handle
    properties
        connection
        connection_nums
        index
        type
    end
    methods
        function obj = Node(n, type_value)
            obj.connection = containers.Map;
            obj.connection_nums = 0;
            obj.index = n;
            if nargin == 2
                obj.type = type_value;
            else
                obj.type = NodeType.Normal;
            end
        end
        function connect(obj, no)
            obj.connection_nums = obj.connection_nums + 1;
            obj.connection(num2str(obj.connection_nums)) = {no, no.index};
        end
        function set.type(obj, type_value)
            if isa(type_value, 'NodeType')
                obj.type = type_value;
            else
                error('Invalid Node Type!');
            end
        end
    end
end
