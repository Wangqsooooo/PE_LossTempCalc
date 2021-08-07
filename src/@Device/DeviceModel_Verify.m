function h = DeviceModel_Verify(obj, imgname, state, axes, varargin)
% 可选的state有 'Forward', 'Reverse', 'Switch_Eon', 'Switch_Eoff'
% 可选的axes有 'I_vs_V', 'Ron_vs_Tj', 'Ron_vs_I', 'E_vs_I', 'E_vs_Tj', 'E_vs_V', 'E_vs_Rg'
expectedState = {'Forward', 'Reverse', 'Switch_Eon', 'Switch_Eoff'};

p = inputParser;
addRequired(p, 'obj');
addRequired(p, 'img');
addRequired(p, 'state', @(x)any(validatestring(x, expectedState)));
addRequired(p, 'axes', @(x)any(validatestring(x, obj.Type.Effective_AxesType(state))));
addParameter(p, 'V', 400, @(x)validateattributes(x, {'numeric'}, {'scalar'}));
addParameter(p, 'I', 60, @(x)validateattributes(x, {'numeric'}, {'scalar'}));
addParameter(p, 'Tj', 25, @(x)validateattributes(x, {'numeric'}, {'scalar'}));
addParameter(p, 'Rg', 5, @(x)validateattributes(x, {'numeric'}, {'scalar'}));
% 'Normalized' 只在state='Forward'且axes='Ron_vs_Tj'时发挥作用
% 如果Normalized='on', 则以基准结温下的导通电阻作为单位电阻1, 即作了归一化处理
addParameter(p, 'Normalized', 'off', @(x)any(validatestring(x, {'on', 'off'})));
parse(p, obj, imgname, state, axes, varargin{:});

screen_size = get(0, 'ScreenSize');
img = imread(imgname);
[row_img, col_img, ~] = size(img);
size_percentage = 100;
if row_img>screen_size(3) || col_img>screen_size(4)
    size_percentage = min([screen_size(3)/row_img screen_size(4)/col_img])*100-5;
end
h = imshow(img, 'InitialMagnification', size_percentage);
axis_real = inputdlg({'Xmin','XMax','YMin','YMax'}, '输入坐标轴范围', [1 50; 1 50; 1 50; 1 50]);
axis_real = [str2double(axis_real{1}) str2double(axis_real{2}) str2double(axis_real{3}) str2double(axis_real{4})];

% 逻辑上不是很复杂, 但是层数有点多
% 第一层if判断是'Forward', 'Reverse', 'Eon', 'Eoff'四种的哪一种
% 第二层if判断是关于坐标的, 如'I_vs_V' 'E_vs_I'等, 由于输入时已经判断过了, 不会出现不对应的情况
% 比如说state='Forward', axes='E_vs_I'这类情况在输入判断时就已经排除了
% 第三层是关于额外信息的, 如'T' 'V'等
if strcmp(state, 'Forward')
    if strcmp(axes, 'I_vs_V')
        if any(strcmp('Tj', varargin(1:2:end)))
            yData = axis_real(3):(axis_real(4)-axis_real(3))/100:axis_real(4);
            xData = obj.VoltageCalc('Forward', yData, p.Results.Tj);
        else
            error('Please offer value of ''Tj''!');
        end
    elseif strcmp(axes, 'Ron_vs_Tj')
        if any(strcmp('I', varargin(1:2:end)))
            xData = axis_real(1):(axis_real(2)-axis_real(1))/100:axis_real(2);
            yData = polyval(obj.Conduction.Forward{2}, xData./obj.Conduction.Tjbase) ...
                .* (~strcmp(p.Results.Normalized, 'on') * obj.Conduction.Forward{3}(p.Results.I) ...
                + strcmp(p.Results.Normalized, 'on'));
        else
            error('Please offer value of ''I''!');
        end
    else % 'Ron_vs_I'
        if any(strcmp('Tj', varargin(1:2:end)))
            xData = axis_real(1):(axis_real(2)-axis_real(1))/100:axis_real(2);
            yData = polyval(obj.Conduction.Forward{2}, p.Results.Tj/obj.Conduction.Tjbase) ...
                .* obj.Conduction.Forward{3}(xData);
        else
            error('Please offer value of ''Tj''!');
        end
    end
elseif strcmp(state, 'Reverse')
    if strcmp(axes, 'I_vs_V')
        if any(strcmp('Tj', varargin(1:2:end)))
            yData = axis_real(3):(axis_real(4)-axis_real(3))/100:axis_real(4);
            xData = obj.VoltageCalc('Reverse', abs(yData), p.Results.Tj);
            if axis_real(1) < 0 && axis_real(3) < 0
                xData = -xData;
            end
        else
            error('Please offer value of ''Tj''!');
        end
    end
elseif obj.Switching.(state){1} ~= 0
    xData = axis_real(1):(axis_real(2)-axis_real(1))/100:axis_real(2);
    if strcmp(axes, 'E_vs_I')
        yData = obj.Switching_Loss(state, xData, varargin{:});
    elseif strcmp(axes, 'E_vs_Tj')
        if ~isequal(obj.Switching.(state){3}, 0) && ~isequal(obj.Switching.(state){3}, 1)
            if any(strcmp('I', varargin(1:2:end)))
                list_withoutI = ~strcmp(varargin(1:2:end), 'I'); 
                list_withoutNormalized = ~strcmp(varargin(1:2:end), 'Normalized');
                % varargin的格式是一个key加上一个value, 如{'key1', value1, 'key2', value2}
                % 上面的list_withoutxxx 找出了不含xxx的的位置信息, 之后要把这个key删除, 顺带需要删除这个key后面的value值
                list = [list_withoutI&list_withoutNormalized; list_withoutI&list_withoutNormalized];
                list = list(:);
                varargin = varargin(list);
                varargin = [varargin {'Tj', xData}];
                yData = obj.Switching_Loss(state, p.Results.I, varargin{:});
            else
                error('Please offer value of ''I''!');
            end
        else
            disp('This device model don''t have ''E_vs_Tj'' information.');
        end
    elseif strcmp(axes, 'E_vs_V')
        if ~isequal(obj.Switching.(state){4}, 0) && ~isequal(obj.Switching.(state){4}, 1)
            if any(strcmp('I', varargin(1:2:end)))
                list_withoutI = ~strcmp(varargin(1:2:end), 'I'); 
                list_withoutNormalized = ~strcmp(varargin(1:2:end), 'Normalized');
                % varargin的格式是一个key加上一个value, 如{'key1', value1, 'key2', value2}
                % 上面的list_withoutxxx 找出了不含xxx的的位置信息, 之后要把这个key删除, 顺带需要删除这个key后面的value值
                list = [list_withoutI&list_withoutNormalized; list_withoutI&list_withoutNormalized];
                list = list(:);
                varargin = varargin(list);
                varargin = [varargin {'V', xData}];
                yData = obj.Switching_Loss(state, p.Results.I, varargin{:});
            else
                error('Please offer value of ''I''!');
            end
        else
            disp('This device model don''t have ''E_vs_V'' information.');
        end
    else % E_vs_Rg
        if ~isequal(obj.Switching.(state){5}, 0) && ~isequal(obj.Switching.(state){5}, 1)
            if any(strcmp('I', varargin(1:2:end)))
                list_withoutI = ~strcmp(varargin(1:2:end), 'I'); 
                list_withoutNormalized = ~strcmp(varargin(1:2:end), 'Normalized');
                % varargin的格式是一个key加上一个value, 如{'key1', value1, 'key2', value2}
                % 上面的list_withoutxxx 找出了不含xxx的的位置信息, 之后要把这个key删除, 顺带需要删除这个key后面的value值
                list = [list_withoutI&list_withoutNormalized; list_withoutI&list_withoutNormalized];
                list = list(:);
                varargin = varargin(list);
                varargin = [varargin {'Rg', xData}];
                yData = obj.Switching_Loss(state, p.Results.I, varargin{:});
            else
                error('Please offer value of ''I''!');
            end
        else
            disp('This device model don''t have ''E_vs_Rg'' information.');
        end
    end
else
    warning('There is no %s information', state); return;
end
% 绘制
axis_fig = Get_Axis(img);
xData2 = floor(axis_fig(1) + (xData - axis_real(1)) ./ (axis_real(2) - axis_real(1)) .* (axis_fig(2) - axis_fig(1)));
yData2 = floor(axis_fig(3) - (yData - axis_real(3)) ./ (axis_real(4) - axis_real(3)) .* (axis_fig(3) - axis_fig(4)));
images = Plot(img, xData2, yData2);
imshow(images, 'InitialMagnification', size_percentage);
% impixelinfo;
end

% 在图片中的坐标轴中描出拟合曲线的点
function result = Plot(img, x, y)
l = length(x);
for i=1:l
    for j=x(i)-2:x(i)+2
        for k=y(i)-2:y(i)+2
            img(k, j, :) = [255 0 0];
        end
    end
end
result = img;
end

% 获取坐标信息(一个简易的标定图片中坐标轴位置的函数)
% 总共需要点击4次
% 第一次点击: 靠近x=0(也就是y轴)处点击一次, 需要保证点击处到y轴之间不会出现其他黑线
% 第二次点击: 靠近y=0(也就是x轴)处点击一次
% 第三次点击: 靠近x=x_max处点击一次
% 第四次点击: 靠近y=y_max处点击一次
function result = Get_Axis(img)
[x, y] = ginput(1); x = floor(x); y = floor(y);
for i=x:-1:1
    if img(y, i, 1) < 125
        head = i;
        break;
    end
end
for i=head:-1:1
    if i == 1 || (img(y, i-1, 1)>125 && img(y, i, 1)<125)
        tail = i;
        break;
    end
end
x_min = floor((head + tail) / 2);
[x, y] = ginput(1); x = floor(x); y = floor(y);
for i=y:size(img, 1)
    if img(i, x, 1) < 125
        head = i;
        break;
    end
end
for i=head:size(img, 1)
    if i == size(img, 1) || (img(i+1, x, 1)>125 && img(i, x, 1)<125)
        tail = i;
        break;
    end
end
y_min = floor((head + tail) / 2);
[x, y] = ginput(1); x = floor(x); y = floor(y);
for i=x:size(img, 2)
    if img(y, i, 1) < 125
        head = i;
        break;
    end
end
for i=head:size(img, 2)
    if i == size(img, 2) || (img(y, i+1, 1)>125 && img(y, i, 1)<125)
        tail = i;
        break;
    end
end
x_max = floor((head + tail) / 2);
[x, y] = ginput(1); x = floor(x); y = floor(y);
for i=y:-1:1
    if img(i, x, 1) < 125
        head = i;
        break;
    end
end
for i=head:-1:1
    if i == 1 || (img(i+1, x, 1)>125 && img(i, x, 1)<125)
        tail = i;
        break;
    end
end
y_max = floor((head + tail) / 2);
result = [x_min x_max y_min y_max];
end
