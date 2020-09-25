classdef Device < handle
    properties(SetAccess = private, GetAccess = public)
        Filename
        Type
        Fittype
        Conduction
        Switching
        Recovery
        Rthch
        Rthjc
        RDthjc % 特指IGBT反并联二极管的热阻
    end
    % 如果热阻网络参数提取失败, 可以自己进行拟合然后手动设置Zthjc和ZDthjc
    properties
        Zthch
        Zthjc
        ZDthjc % 特指IGBT反并联二极管的热阻网络, 其他器件类型该值均为{0}
    end
    
    methods
        function obj = Device(filename, type, options)
            arguments
                filename (1, 1) string
                type DeviceType
                options.Forward = struct([]), options.Reverse = struct([])
                options.Switch_Eon = struct([]), options.Switch_Eoff = struct([])
            end
            
            obj.Filename = filename;
            obj.Type = type;
            obj.Fittype = obj.Type.StandardFittype();
            obj.StructAppend('Forward', options.Forward);
            obj.StructAppend('Reverse', options.Reverse);
            obj.StructAppend('Switch_Eon', options.Switch_Eon);
            obj.StructAppend('Switch_Eoff', options.Switch_Eoff);
            % 参数提取
            obj.Conduction_Params_Extraction('Forward');
            obj.Conduction_Params_Extraction('Reverse');
            obj.Switching_Params_Extraction('Switch_Eon');
            obj.Switching_Params_Extraction('Switch_Eoff');
            obj.Recovery_Params_Extraction();
            obj.Rth_Params_Extraction();
        end
        Conduction_Params_Extraction(obj, fieldname);
        Switching_Params_Extraction(obj, fieldname);
        function Recovery_Params_Extraction(obj)
            if strcmp(obj.Fittype.Recovery, 'linear')
                try
                    [data, ~] = xlsread(obj.Filename, 'Recovery');
                    ft = fittype('poly1');
                    temp_data = data(:, 1:2);
                    temp_data(isnan(temp_data(:, 1)), :) = [];
                    [xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
                    [fitresult, ~] = fit(xData, yData, ft);
                    obj.Recovery = {1, [fitresult.p1 fitresult.p2]};
                catch E
                    if strcmp(E.identifier, 'MATLAB:xlsread:WorksheetNotFound')
                        obj.Recovery = {0};
                        warning('This device don''t have recovery loss information!');
                    end
                end
            else
                obj.Recovery = {0};
            end
        end
        Rth_Params_Extraction(obj);
        DeviceModel_Verify(obj, imgname, state, axes, varargin);
        
        % current和Tj都要是一维的
        % 如果Tj是1x1的, 那么输出变量forward, reverse都是一维的
        % 如果Tj是1xN的, 那么输出变量forward, reverse是containers.Map的格式
        function [forward, reverse] = Conduction_Loss(obj, current, Tj, options)
            arguments
                obj, current (1, :) double, Tj (1, :) double
                options.Mode (1, 1) string {mustBeMember(options.Mode, {'IGBTModeON', 'IGBTModeOFF'})} = 'IGBTModeON'
            end
            Tlength = length(Tj);
            if Tlength == 1 || (Tlength == 2 && strcmp(options.Mode, 'IGBTModeON'))
                if Tlength == 1
                    Tj = [Tj, Tj];
                end
                temp_current = current .* (current>=0);
                forward = obj.VoltageCalc('Forward', temp_current, Tj(1)) .* temp_current;
                temp_current = current .* (current<0); temp_current = - temp_current;
                reverse = obj.VoltageCalc('Reverse', temp_current, Tj(2)) .* temp_current;
            else
                forward = containers.Map; reverse = containers.Map;
                for i = 1:Tlength
                    temp_current = current .* (current>=0);
                    forward(strcat('Tj', num2str(Tj(i)))) = obj.VoltageCalc('Forward', temp_current, Tj(i)) .* temp_current;
                    temp_current = current .* (current<0); temp_current = -temp_current;
                    reverse(strcat('Tj', num2str(Tj(i)))) = obj.VoltageCalc('Reverse', temp_current, Tj(i)) .* temp_current;
                end
            end
        end
        % 输入当current, V, Tj, Rg中只有一个1xN的数组且有效时, 输出E也为一维数组
        % 有效指器件模型中包含有相应的信息, 比如器件模型没有关于Rg变量的关系, 则输入'Rg'是无效的
        % 输入当current, V, Tj, Rg中有大于等于2个1xN的数组且有效时, 输出E为containers.Map格式
        function E = Switching_Loss(obj, state, current, varargin)
            p = inputParser;
            addRequired(p, 'current', @(x)validateattributes(x, {'numeric'}, {'row'}));
            addParameter(p, 'V', 400, @(x)validateattributes(x, {'numeric'}, {'row'}));
            addParameter(p, 'Tj', 25, @(x)validateattributes(x, {'numeric'}, {'row'}));
            addParameter(p, 'Rg', 5, @(x)validateattributes(x, {'numeric'}, {'row'}));
            parse(p, current, varargin{:});
            if obj.Switching.(state){1} == 0
                E = zeros(size(current));
                return;
            end
            [flag, error_text, varargin_name] = obj.Switching_Loss_InputCheck(state, varargin);
            if flag == 0
                error_msg = sprintf('Please offer value of ''%s''', cell2mat(error_text(1)));
                for i = error_text(2:end)
                    error_msg = strcat(error_msg, sprintf(', ''%s''', cell2mat(i)));
                end
                error_msg = strcat(error_msg, '!');
                error(error_msg);
            end
            if sum([length(p.Results.current) length(p.Results.V) length(p.Results.Tj) length(p.Results.Rg)]==1) == 4 ...
                    || sum([length(p.Results.current) length(p.Results.V) length(p.Results.Tj) length(p.Results.Rg)]==1) == 3
                E = 1;
                for i = varargin_name
                    axes = strcat('E_vs_', i{1});
                    value_list = varargin(2:2:end);
                    value = value_list(strcmp(i{1}, varargin(1:2:end))); value = value{1};
                    if isempty(regexp(obj.Fittype.(state).(axes), '^poly', 'once'))
                        E = E .* (value./obj.Switching.(strcat(i{1}, 'base'))) ...
                            .^obj.Switching.(state){strcmp('V', i{1})*3+strcmp('Tj', i{1})*4+strcmp('Rg', i{1})*5};
                    else
                        E = E .* polyval(obj.Switching.(state){strcmp('V', i{1})*3+strcmp('Tj', i{1})*4+strcmp('Rg', i{1})*5}, ...
                            value./obj.Switching.(strcat(i{1}, 'base')));
                    end
                end
                E = E .* polyval(obj.Switching.(state){2}, p.Results.current) .* (p.Results.current>=0);
                E(E<0) = 0; % 开关损耗不可能为负数
            else
                E = obj.VariableNumber_ForCycle(state, p.Results.current, varargin_name, varargin);
            end
        end
        function E = Recovery_Loss(obj, current, V, Tj)
            if obj.Recovery{1} == 1
                E = ones(1, length(current)) .* V .* polyval(obj.Recovery{2}, Tj) .* (current<0);
            else
                E = zeros(1, length(current));
            end
        end
    end
    
    methods(Access=private)
        function StructAppend(obj, fieldname, addstruct)
            names = fieldnames(addstruct);
            for i = 1:size(names, 1)
                obj.Fittype.(fieldname).(names{i}) = addstruct.(names{i});
            end
        end
        function voltage = VoltageCalc(obj, state, current, Tj)
            arguments
                obj
                state (1, 1) string {mustBeMember(state, {'Forward', 'Reverse'})}
                current double {mustBeNonnegative}
                Tj (1, 1) double
            end
            if strcmp(state, 'Forward')
                if obj.Conduction.Forward{1} == 2
                    voltage = polyval(obj.Conduction.Forward{2}, Tj) ...
                        + polyval(obj.Conduction.Forward{3}, Tj) ...
                        .* current .^ obj.Conduction.Forward{4};
                else
                    Ron = polyval(obj.Conduction.Forward{2}, Tj/obj.Conduction.Tjbase) ...
                        .* obj.Conduction.Forward{3}(current);
                    voltage = Ron' .* current;
                end
            else
                if obj.Conduction.Reverse{1} == 2
                    voltage = polyval(obj.Conduction.Reverse{2}, Tj) ...
                        + polyval(obj.Conduction.Reverse{3}, Tj) ...
                        .* current .^ obj.Conduction.Reverse{4};
                else
                    Ron = obj.Conduction.Reverse{2}(Tj);
                    voltage = Ron' .* current;
                end
            end
            voltage(voltage<0) = 0; % 最小电压电压限制
        end
        function [flag, error_text, varargin_out] = Switching_Loss_InputCheck(obj, state, varargin_text, count)
            arguments
                obj, state, varargin_text
                count (1, 1) double = 5 
            end
            if count >= 3
                [flag, error_text, varargin_out] = obj.Switching_Loss_InputCheck(state, varargin_text, count-1);
                if ~isequal(obj.Switching.(state){count}, 0) && ~isequal(obj.Switching.(state){count}, 1)
                    switch count
                        case 3
                            varargin_name = 'V';
                        case 4
                            varargin_name = 'Tj';
                        case 5
                            varargin_name = 'Rg';
                    end
                    if ~any(strcmp(varargin_name, varargin_text(1:2:end)))
                        flag = 0;
                        error_text = [error_text varargin_name];
                    else
                        varargin_out = [varargin_out varargin_name];
                    end
                end
            else
                flag = 1; error_text = {}; varargin_out = {};
            end
        end
        function E = VariableNumber_ForCycle(obj, state, current, name, varargs, floor, record, E)
            arguments
                obj, state, current, name, varargs, 
                floor = 1, record = [], E = containers.Map;
            end
            if floor <= length(name)
                allvalue_list = varargs(2:2:end);
                value_list = allvalue_list(strcmp(name{floor}, varargs(1:2:end)));
                value_list = value_list{1};
                for i = value_list
                    temp_record = [record i];
                    E = obj.VariableNumber_ForCycle(state, current, name, varargs, floor+1, temp_record, E);
                end
            else
                key = ''; Loss = 1;
                for i = 1:length(name)
                    key = strcat(key, name{i}); key = strcat(key, num2str(record(i)));
                    axes = strcat('E_vs_', name{i});
                    if isempty(regexp(obj.Fittype.(state).(axes), '^poly', 'once'))
                        Loss = Loss * (record(i)/obj.Switching.(strcat(name{i}, 'base'))) ...
                            ^ obj.Switching.(state){strcmp('V', name{i})*3+strcmp('Tj', name{i})*4+strcmp('Rg', name{i})*5};
                    else
                        Loss = Loss * polyval(obj.Switching.(state){strcmp('V', name{i})*3+strcmp('Tj', name{i})*4+strcmp('Rg', name{i})*5}, ...
                            record(i)/obj.Switching.(strcat(name{i}, 'base')));
                    end
                end
                Loss = Loss .* polyval(obj.Switching.(state){2}, current) .* (current>=0);
                E(key) = Loss;
            end
        end
    end
end
