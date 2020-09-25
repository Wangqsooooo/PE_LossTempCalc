classdef DeviceType
    enumeration
        IGBT
        MOSFET
        CoolMOS
    end
    
    methods
        function fittype = StandardFittype(obj)
            switch obj
                case DeviceType.IGBT
                    temp.type = 'exponential'; % 导通压降与流过的电流是指数关系
                    fittype.Forward = temp; fittype.Reverse = temp;
                    temp.type = 'linear'; fittype.Recovery = temp;
                    temp.type = 'Standard'; % 开关损耗采用的是统一的模型
                    % E_vs_V E_vs_Tj要么是多项式的形式, 即polyn, 其中n为多项式的最高次幂指数
                    % 要么是a*x^b形式, 对于E_vs_V这表示实际切换电压下产生的开关损耗是基准电压Vbase下的V(V/Vbase)^b倍
                    temp.E_vs_I = 'poly2'; temp.E_vs_V = 'a*x^b'; temp.E_vs_Tj = 'poly2'; temp.E_vs_Rg = 'poly2';
                    fittype.Switch_Eon = temp; fittype.Switch_Eoff = temp;
                case DeviceType.MOSFET
                    temp.type = 'linear'; % 导通压降与流过的电流是线性关系, 即MOSFET的V-I特性是以导通电阻Ron来描述的
                    temp.linear_fit_forward = 'poly3'; % Ron vs Tj的拟合方程, MOSFET需要一个二次的曲线进行拟合
                                                       % 可根据实际情况进行修改, 但是不要在这里修改
                    fittype.Forward = temp;
                    temp = rmfield(temp, 'linear_fit_forward'); fittype.Reverse = temp;
                    temp.type = 'None'; fittype.Recovery = temp;
                    temp.type = 'Standard'; % 开关损耗采用的是统一的模型
                    temp.E_vs_I = 'poly2'; temp.E_vs_V = 'a*x^b'; temp.E_vs_Tj = 'poly2'; temp.E_vs_Rg = 'poly2';
                    fittype.Switch_Eon = temp; fittype.Switch_Eoff = temp;
                case DeviceType.CoolMOS
                    % CoolMOS正向导通压降与流过的电流是线性关系
                    temp.type = 'linear'; temp.linear_fit_forward = 'poly2'; % CoolMOS只要一次曲线就可以拟合, 可根据实际进行修改
                    fittype.Forward = temp;
                    % 反向导通压降与流过的电流是指数关系
                    temp.type = 'exponential'; temp = rmfield(temp, 'linear_fit_forward');
                    fittype.Reverse = temp;
                    temp.type = 'None'; fittype.Recovery = temp;
                    temp.type = 'Standard'; % 开关损耗采用的是统一的模型
                    temp.E_vs_I = 'poly2'; temp.E_vs_V = 'a*x^b'; temp.E_vs_Tj = 'poly2'; temp.E_vs_Rg = 'poly2';
                    fittype.Switch_Eon = temp; fittype.Switch_Eoff = temp;
            end
        end
        function axes_list = Effective_AxesType(obj, state)
            switch obj
                case DeviceType.IGBT
                    if strcmp(state, 'Forward') || strcmp(state, 'Reverse')
                        axes_list = {'I_vs_V'};
                    else
                        axes_list = {'E_vs_I', 'E_vs_Tj', 'E_vs_V', 'E_vs_Rg'};
                    end
                case DeviceType.MOSFET
                    if strcmp(state, 'Forward')
                        axes_list = {'I_vs_V', 'Ron_vs_Tj', 'Ron_vs_I'};
                    elseif strcmp(state, 'Reverse')
                        axes_list = {'I_vs_V'};
                    else
                        axes_list = {'E_vs_I', 'E_vs_Tj', 'E_vs_V', 'E_vs_Rg'};
                    end
                case DeviceType.CoolMOS
                    if strcmp(state, 'Forward')
                        axes_list = {'I_vs_V', 'Ron_vs_Tj', 'Ron_vs_I'};
                    elseif strcmp(state, 'Reverse')
                        axes_list = {'I_vs_V'};
                    else
                        axes_list = {'E_vs_I', 'E_vs_Tj', 'E_vs_V', 'E_vs_Rg'};
                    end
            end
        end
    end
end
