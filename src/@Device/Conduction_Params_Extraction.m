function Conduction_Params_Extraction(obj, fieldname)
[data, text] = xlsread(obj.Filename, fieldname);
switch obj.Fittype.(fieldname).type 
    case 'exponential'
        obj.Conduction.(fieldname) = Exponential_Fit(data, text);
    case 'linear'
        if strcmp(fieldname, 'Forward')
            [obj.Conduction.(fieldname), obj.Conduction.Tjbase] = Linear_Fit_Forward(data, text, obj.Fittype.Forward.linear_fit_forward);
        else
            obj.Conduction.(fieldname) = Linear_Fit_Reverse(data, text);
        end
end
end

function model = Exponential_Fit(data, text)
try
    Tj1 = regexp(text{2}, '^-?\d+', 'match'); Tj1 = str2double(Tj1{1});
    Tj2 = regexp(text{5}, '^-?\d+', 'match'); Tj2 = str2double(Tj2{1});
catch ME
    if strcmp(ME.identifier, 'MATLAB:badsubscript')
        error('The information of temperature is missing!');
    else
        rethrow(ME);
    end
end
temp_data = data(:, 1:2);
temp_data(isnan(temp_data(:, 1)), :) = [];
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
ft = fittype('a*x^b+c', 'independent', 'x', 'dependent', 'y');
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0 0.5 0.5];
[fitresult1, ~] = fit(xData, yData, ft, opts);
temp_data = data(:, 4:5);
temp_data(isnan(temp_data(:, 1)), :) = [];
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
[fitresult2, ~] = fit(xData, yData, ft, opts);
c = (fitresult1.b + fitresult2.b) / 2;
eval(['myfittype', '=', '''a*x', '^', num2str(c), '+', 'c''', ';']);
ft = fittype(myfittype, 'independent', 'x', 'dependent', 'y');
opts.StartPoint = [0 0.5];
temp_data = data(:, 1:2);
temp_data(isnan(temp_data(:, 1)), :) = [];
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
[fitresult1, ~] = fit(xData, yData, ft, opts);
temp_data = data(:, 4:5);
temp_data(isnan(temp_data(:, 1)), :) = [];
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
[fitresult2, ~] = fit(xData, yData, ft, opts);
% 解二元一次方程组
d1 = [Tj1 1; Tj2 1]; d2 = [fitresult1.c 1; fitresult2.c 1];
d3 = [Tj1 fitresult1.c; Tj2 fitresult2.c];
a = det(d2) / det(d1); v0 = det(d3) / det(d1);
d2 = [fitresult1.a 1; fitresult2.a 1];
d3 = [Tj1 fitresult1.a; Tj2 fitresult2.a];
b = det(d2) / det(d1); r0 = det(d3) / det(d1);

model = {2, [a v0], [b r0], c};
end

function [model, Tbase] = Linear_Fit_Forward(data, text, type)
try
    Tj_base = regexp(text{2}, '^-?\d+', 'match'); Tj_base = str2double(Tj_base{1});
catch ME
    if strcmp(ME.identifier, 'MATLAB:badsubscript')
        error('Base temperature is missing!');
    else
        rethrow(ME);
    end
end
temp_data = data(:, 1:2);
temp_data(isnan(temp_data(:, 1)), :) = [];
ft = fittype(type);
if isempty(regexp(text{2}, 'Normalized', 'once'))
    [xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
    [fitresult, ~] = fit(xData, yData, ft);
    polyparams = PolyParams(fitresult);
    temp_data(:, 2) = temp_data(:, 2) ./ polyval(polyparams, Tj_base);
end
[xData, yData] = prepareCurveData(temp_data(:, 1)./Tj_base, temp_data(:, 2));
[fitresult, ~] = fit(xData, yData, ft);
polyparams = PolyParams(fitresult);
model = {1, polyparams};
temp_data = data(:, 4:5);
temp_data(isnan(temp_data(:, 1)), :) = [];
[xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
ft = 'linearinterp';
[Forward_Ron_vs_Ids, ~] = fit(xData, yData, ft, 'Normalize', 'on');
model{3} = Forward_Ron_vs_Ids;
Tbase = Tj_base;
end

function model = Linear_Fit_Reverse(data, text)
[~, col] = size(data);
if regexp(text{1}, '^Ron_vs_Tj')
    temp_data = data(:, 1:2);
    temp_data(isnan(temp_data(:, 1)), :) = [];
    [xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
    ft = 'linearinterp';
    [Reverse_Ron_vs_Tj, ~] = fit(xData, yData, ft, 'Normalize', 'on');
elseif regexp(text{1}, '^Ron_vs_Ids') && col >= 5
    Values = zeros(floor((col+1)/3), 2);
    for i = 1:floor((col+1)/3)
        Tj = regexp(text{i*3-1}, '^-?\d+', 'match'); Tj = str2double(Tj{1});
        temp_data = data(:, i*3-2:i*3-1);
        temp_data(isnan(temp_data(:, 1)), :) = [];
        [xData, yData] = prepareCurveData(temp_data(:, 1), temp_data(:, 2));
        ft = fittype( 'a*x', 'independent', 'x', 'dependent', 'y' );
        opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        opts.Display = 'Off';
        opts.StartPoint = 0;
        [fitresult, ~] = fit(xData, yData, ft, opts);
        Values(i, :) = [Tj fitresult.a];
    end
    [xData, yData] = prepareCurveData(Values(:, 1), Values(:, 2));
    ft = 'linearinterp';
    [Reverse_Ron_vs_Tj, ~] = fit(xData, yData, ft, 'Normalize', 'on');
else
    error('Error in Reverse Params Extrction!');
end
model = {1, Reverse_Ron_vs_Tj};
end

function polyparams = PolyParams(fitresult)
names = fieldnames(fitresult); row = size(names, 1);
polyparams = zeros(1, row);
for i = 1:row
    polyparams(i) = fitresult.(names{i});
end
end
