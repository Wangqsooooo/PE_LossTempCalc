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
                    temp.type = 'exponential'; % ��ͨѹ���������ĵ�����ָ����ϵ
                    fittype.Forward = temp; fittype.Reverse = temp;
                    temp.type = 'linear'; fittype.Recovery = temp;
                    temp.type = 'Standard'; % ������Ĳ��õ���ͳһ��ģ��
                    % E_vs_V E_vs_TjҪô�Ƕ���ʽ����ʽ, ��polyn, ����nΪ����ʽ����ߴ���ָ��
                    % Ҫô��a*x^b��ʽ, ����E_vs_V���ʾʵ���л���ѹ�²����Ŀ�������ǻ�׼��ѹVbase�µ�V(V/Vbase)^b��
                    temp.E_vs_I = 'poly2'; temp.E_vs_V = 'a*x^b'; temp.E_vs_Tj = 'poly2'; temp.E_vs_Rg = 'poly2';
                    fittype.Switch_Eon = temp; fittype.Switch_Eoff = temp;
                case DeviceType.MOSFET
                    temp.type = 'linear'; % ��ͨѹ���������ĵ��������Թ�ϵ, ��MOSFET��V-I�������Ե�ͨ����Ron��������
                    temp.linear_fit_forward = 'poly3'; % Ron vs Tj����Ϸ���, MOSFET��Ҫһ�����ε����߽������
                                                       % �ɸ���ʵ����������޸�, ���ǲ�Ҫ�������޸�
                    fittype.Forward = temp;
                    temp = rmfield(temp, 'linear_fit_forward'); fittype.Reverse = temp;
                    temp.type = 'None'; fittype.Recovery = temp;
                    temp.type = 'Standard'; % ������Ĳ��õ���ͳһ��ģ��
                    temp.E_vs_I = 'poly2'; temp.E_vs_V = 'a*x^b'; temp.E_vs_Tj = 'poly2'; temp.E_vs_Rg = 'poly2';
                    fittype.Switch_Eon = temp; fittype.Switch_Eoff = temp;
                case DeviceType.CoolMOS
                    % CoolMOS����ͨѹ���������ĵ��������Թ�ϵ
                    temp.type = 'linear'; temp.linear_fit_forward = 'poly2'; % CoolMOSֻҪһ�����߾Ϳ������, �ɸ���ʵ�ʽ����޸�
                    fittype.Forward = temp;
                    % ����ͨѹ���������ĵ�����ָ����ϵ
                    temp.type = 'exponential'; temp = rmfield(temp, 'linear_fit_forward');
                    fittype.Reverse = temp;
                    temp.type = 'None'; fittype.Recovery = temp;
                    temp.type = 'Standard'; % ������Ĳ��õ���ͳһ��ģ��
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
