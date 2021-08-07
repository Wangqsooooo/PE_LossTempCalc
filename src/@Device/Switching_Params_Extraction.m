function Switching_Params_Extraction(obj, fieldname)
try
    [data, text] = xlsread(obj.Filename, fieldname);
catch ME
    if strcmp(ME.identifier, 'MATLAB:xlsread:WorksheetNotFound')
        warning('The excel file don''t have %s part.', fieldname);
        obj.Switching.(fieldname) = {0};
        return;
    else
        rethrow(ME);
    end
end
% no 'E_vs_I' data, return 0 
if isempty(data)
    obj.Switching.(fieldname) = {0}; return;
end
temp_data = data(:, 1:2);
temp_data(isnan(temp_data(:, 1)), :) = [];
if isempty(temp_data)
    obj.Switching.(fieldname) = {0}; return;
end
% excel表中从左到右, 第二项到第四项分别是E_vs_V E_vs_Tj E_vs_Rg
fit_type = {obj.Fittype.(fieldname).E_vs_I obj.Fittype.(fieldname).E_vs_V ...
    obj.Fittype.(fieldname).E_vs_Tj obj.Fittype.(fieldname).E_vs_Rg};
% E_vs_I fit
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
ft = fittype(fit_type{1});
[fitresult, ~] = fit(xData, yData, ft);
polyparams = PolyParams(fitresult);
obj.Switching.(fieldname) = {1, polyparams};
% E_vs_V, E_vs_Tj, E_vs_Rg fit
for i = 2:4
    type = fit_type{i};
    if i <= (length(text)+1)/3
        base = regexp(text{3*i-1}, '-?\d+', 'match');
    else
        base = [];
    end
    if ~isempty(base) && i <= round((size(data, 2)+1)/3)
        base = str2double(base{1});
        switch i
            case 2
                obj.Switching.Vbase = base;
            case 3
                obj.Switching.Tjbase = base;
            case 4
                if strcmp(fieldname, 'Switch_Eon')
                    obj.Switching.Rgbase(1) = base;
                else
                    obj.Switching.Rgbase(2) = base;
                end
        end
        
        temp_data = data(:, 3*i-2:3*i-1);
        temp_data(isnan(temp_data(:, 1)), :) = [];
        temp_data(isnan(temp_data(:, 2)), :) = [];
        if isempty(temp_data)
            if isempty(regexp(type, '^poly', 'once'))
                obj.Switching.(fieldname){i+1} = 0;
            else
                obj.Switching.(fieldname){i+1} = 1;
            end
        else
            if isempty(regexp(type, '^poly', 'once')) % 指数函数拟合
                ft = fittype('poly1');
                [fitresult, ~] = fit(log(temp_data(:, 1)), log(temp_data(:, 2)), ft);
                obj.Switching.(fieldname){i+1} = fitresult.p1;
            else % 多项式拟合
                ft = fittype(type);
                if isempty(regexp(text{3*i-1}, 'Normalized', 'once'))
                    [xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
                    [fitresult, ~] = fit(xData, yData, ft);
                    polyparams = PolyParams(fitresult);
                    temp_data(:, 2) = temp_data(:, 2) ./ polyval(polyparams, base);
                end
                [fitresult, ~] = fit(temp_data(:, 1) ./ base, temp_data(:, 2), ft);
                polyparams = PolyParams(fitresult);
                obj.Switching.(fieldname){i+1} = polyparams;
            end
        end
    else
        switch i
            case 2
                obj.Switching.Vbase = -1;
            case 3
                obj.Switching.Tjbase = -1;
            case 4
                obj.Switching.Rgbase = -1;
        end
        
        if isempty(regexp(type, '^poly', 'once'))
            obj.Switching.(fieldname){i+1} = 0;
        else
            obj.Switching.(fieldname){i+1} = 1;
        end
    end
end
end

% 将多项式拟合结果cfit结构中各系数转化为数组的形式
function polyparams = PolyParams(fitresult)
% input :
% fitresult : fit result, cfit type data
names = coeffnames(fitresult);
polyparams = cellfun(@(x) fitresult.(x), names');
end
