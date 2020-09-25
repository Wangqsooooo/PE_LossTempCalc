function Rth_Params_Extraction(obj)
StartPoint_List = [0.5 0.5 0.05 0.1;
                   0.5 0.5 0.1 0.2;
                   0.5 0.5 0.2 0.4;
                   0.5 0.5 0.3 0.6];
[data, text] = xlsread(obj.Filename, 'Rth');
% Rthjc
position = strcmp('Rthjc', text);
obj.Rthjc = data(1, position);
% RDthjc
position = strcmp('RDthjc', text);
if any(position)
    obj.RDthjc = data(1, position);
else
    obj.RDthjc = 0;
end
% Zthch
position = strcmp('Zthch', text);
temp_data = data(:, position); temp_data(isnan(temp_data)) = [];
obj.Zthch = cell(1, length(temp_data)/2);
obj.Rthch = 0;
for i = 1:length(temp_data)/2
    obj.Zthch{i} = [temp_data(2*i-1), temp_data(2*i)];
    obj.Rthch = obj.Rthch + temp_data(2*i-1);
end
% Zthjc
position = strcmp('Device', text);
xData = data(:, position); xData(isnan(xData)) = [];
yData = data(:, find(position)+1); yData(isnan(yData)) = [];
[xData, yData] = prepareCurveData(xData, yData);
ft = fittype( 'R1*(1-exp(-x/a1))+R2*(1-exp(-x/a2))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [0 0 0 0];
count = 1;
while 1
    opts.StartPoint = StartPoint_List(count, :);
    count = count + 1;
    [fitresult, gof] = fit(xData, yData, ft, opts);
    if fitresult.R1+fitresult.R2 <= obj.Rthjc + 0.05 && fitresult.R1+fitresult.R2 >= obj.Rthjc - 0.05 && gof.rsquare >= 0.995
        obj.Zthjc = {[fitresult.R1, fitresult.a1], [fitresult.R2, fitresult.a2]};
        break;
    elseif count > size(StartPoint_List, 1)
        disp('No suitable value for ''Zthjc'', please enter this parameter manually.');
        break;
    end
end
% ZDthjc (特指IGBT反并联二极管的热阻网络)
position = strcmp('Diode', text);
if any(position)
    xData = data(:, position); xData(isnan(xData)) = [];
    yData = data(:, find(position)+1); yData(isnan(yData)) = [];
    [xData, yData] = prepareCurveData(xData, yData);
    count = 1;
    while 1
        opts.StartPoint = StartPoint_List(count, :);
        count = count + 1;
        [fitresult, ~] = fit(xData, yData, ft, opts);
        if fitresult.R1+fitresult.R2 <= obj.RDthjc + 0.05 && fitresult.R1+fitresult.R2 >= obj.RDthjc - 0.05 && gof.rsquare >= 0.995
            obj.ZDthjc = {[fitresult.R1, fitresult.a1], [fitresult.R2, fitresult.a2]};
            break;
        elseif count > size(StartPoint_List, 1)
            disp('No suitable value for ''ZDthjc'', please enter this parameter manually.');
            break;
        end
    end
else
    obj.ZDthjc = {0};
end
end
