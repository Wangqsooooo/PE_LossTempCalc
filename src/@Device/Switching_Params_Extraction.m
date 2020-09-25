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
if isempty(data)
    obj.Switching.(fieldname) = {0}; return;
end
temp_data = data(:, 1:2);
temp_data(isnan(temp_data(:, 1)), :) = [];
if isempty(temp_data)
    obj.Switching.(fieldname) = {0}; return;
end
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
ft = fittype(obj.Fittype.(fieldname).E_vs_I);
[fitresult, ~] = fit(xData, yData, ft);
polyparams = PolyParams(fitresult);
obj.Switching.(fieldname) = {1, polyparams};
for i = 2:4
    if i <= round((size(data, 2)+1)/3)
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
            % excel表中从左到右, 第二项到第四项分别是E_vs_V E_vs_Tj E_vs_Rg
            switch i
                case 2
                    type = obj.Fittype.(fieldname).E_vs_V;
                    base = regexp(text{3*i-1}, '-?\d+', 'match'); base = str2double(base{1});
                    obj.Switching.Vbase = base;
                case 3
                    type = obj.Fittype.(fieldname).E_vs_Tj;
                    base = regexp(text{3*i-1}, '-?\d+', 'match'); base = str2double(base{1});
                    obj.Switching.Tjbase = base;
                case 4
                    type = obj.Fittype.(fieldname).E_vs_Rg;
                    base = regexp(text{3*i-1}, '-?\d+', 'match'); base = str2double(base{1});
                    obj.Switching.Rgbase = base;
            end
            if isempty(regexp(type, '^poly', 'once'))
                ft = fittype('poly1');
                [fitresult, ~] = fit(log(temp_data(:, 1)), log(temp_data(:, 2)), ft);
                obj.Switching.(fieldname){i+1} = fitresult.p1;
            else
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
        if isempty(regexp(type, '^poly', 'once'))
            obj.Switching.(fieldname){i+1} = 0;
        else
            obj.Switching.(fieldname){i+1} = 1;
        end
        if i == 2
            obj.Switching.Vbase = 1;
        elseif i == 3
            obj.Switching.Tjbase = 1;
        else
            obj.Switching.Rgbase = 1;
        end
    end
end
end

function polyparams = PolyParams(fitresult)
names = fieldnames(fitresult); row = size(names, 1);
polyparams = zeros(1, row);
for i = 1:row
    polyparams(i) = fitresult.(names{i});
end
end
