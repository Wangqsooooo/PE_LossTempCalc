function h = DeviceModel_Verify(obj, imgname, state, axes, varargin)
% ��ѡ��state�� 'Forward', 'Reverse', 'Switch_Eon', 'Switch_Eoff'
% ��ѡ��axes�� 'I_vs_V', 'Ron_vs_Tj', 'Ron_vs_I', 'E_vs_I', 'E_vs_Tj', 'E_vs_V', 'E_vs_Rg'
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
% 'Normalized' ֻ��state='Forward'��axes='Ron_vs_Tj'ʱ��������
% ���Normalized='on', ���Ի�׼�����µĵ�ͨ������Ϊ��λ����1, �����˹�һ������
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
axis_real = inputdlg({'Xmin','XMax','YMin','YMax'}, '���������᷶Χ', [1 50; 1 50; 1 50; 1 50]);
axis_real = [str2double(axis_real{1}) str2double(axis_real{2}) str2double(axis_real{3}) str2double(axis_real{4})];

% �߼��ϲ��Ǻܸ���, ���ǲ����е��
% ��һ��if�ж���'Forward', 'Reverse', 'Eon', 'Eoff'���ֵ���һ��
% �ڶ���if�ж��ǹ��������, ��'I_vs_V' 'E_vs_I'��, ��������ʱ�Ѿ��жϹ���, ������ֲ���Ӧ�����
% ����˵state='Forward', axes='E_vs_I'��������������ж�ʱ���Ѿ��ų���
% �������ǹ��ڶ�����Ϣ��, ��'T' 'V'��
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
                % varargin�ĸ�ʽ��һ��key����һ��value, ��{'key1', value1, 'key2', value2}
                % �����list_withoutxxx �ҳ��˲���xxx�ĵ�λ����Ϣ, ֮��Ҫ�����keyɾ��, ˳����Ҫɾ�����key�����valueֵ
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
                % varargin�ĸ�ʽ��һ��key����һ��value, ��{'key1', value1, 'key2', value2}
                % �����list_withoutxxx �ҳ��˲���xxx�ĵ�λ����Ϣ, ֮��Ҫ�����keyɾ��, ˳����Ҫɾ�����key�����valueֵ
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
                % varargin�ĸ�ʽ��һ��key����һ��value, ��{'key1', value1, 'key2', value2}
                % �����list_withoutxxx �ҳ��˲���xxx�ĵ�λ����Ϣ, ֮��Ҫ�����keyɾ��, ˳����Ҫɾ�����key�����valueֵ
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
% ����
axis_fig = Get_Axis(img);
xData2 = floor(axis_fig(1) + (xData - axis_real(1)) ./ (axis_real(2) - axis_real(1)) .* (axis_fig(2) - axis_fig(1)));
yData2 = floor(axis_fig(3) - (yData - axis_real(3)) ./ (axis_real(4) - axis_real(3)) .* (axis_fig(3) - axis_fig(4)));
images = Plot(img, xData2, yData2);
imshow(images, 'InitialMagnification', size_percentage);
% impixelinfo;
end

% ��ͼƬ�е������������������ߵĵ�
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

% ��ȡ������Ϣ(һ�����׵ı궨ͼƬ��������λ�õĺ���)
% �ܹ���Ҫ���4��
% ��һ�ε��: ����x=0(Ҳ����y��)�����һ��, ��Ҫ��֤�������y��֮�䲻�������������
% �ڶ��ε��: ����y=0(Ҳ����x��)�����һ��
% �����ε��: ����x=x_max�����һ��
% ���Ĵε��: ����y=y_max�����һ��
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
