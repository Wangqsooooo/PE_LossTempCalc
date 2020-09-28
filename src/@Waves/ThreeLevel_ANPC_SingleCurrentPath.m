function [modulation, carrier, control] = ThreeLevel_ANPC_SingleCurrentPath(obj, load, phaseshift, order, options)
arguments
    obj, load, phaseshift (1, 1) double
    order (1, :) {mustBeNonnegative, mustBeInteger} = [1 2 3 4 5 6]
    options.DisplayMode (1, 1) string {mustBeMember(options.DisplayMode, {'Yes', 'No'})} = 'No'
end

t = 0:obj.Ts:obj.Period;
t_bias = round(t./obj.Ts);
t_bias = floor(t_bias.*load.freq.*obj.Ts) ./ load.freq;
modulation = load.ma .* sin(2.*pi./load.T.*t_bias-phaseshift);
shift_modulation = zeros(size(modulation));
shift_modulation(1:end-1) = circshift(modulation(1:end-1), round(1/load.freq/obj.Ts));
shift_modulation(end) = modulation(end-round(1/load.freq/obj.Ts));
carrier = zeros(2, length(t));
carrier(1, :) = (rem(t.*load.freq, 1)<1/2) .* (1-2.*rem(t.*load.freq, 1)) ...
    + (rem(t.*load.freq, 1)>=1/2) .* (-1+2.*rem(t.*load.freq, 1));
carrier(2, :) = carrier(1, :) - 1;
control = zeros(6, length(t));
% 小数点后10位精度
control(1, :) = (modulation >= 1e-10) ...
    | (modulation<1e-10 & modulation>-1e-10 & shift_modulation<-1e-10);
control(4, :) = ~control(1, :);
control(5, :) = control(4, :);
control(6, :) = control(1, :);
control(2, :) = (control(1, :) & modulation >= carrier(1, :)) ...
                    | (control(4, :) & modulation >= carrier(2, :));
control(3, :) = ~control(2, :);
if strcmp(options.DisplayMode, 'No')
    obj.Control(order, :) = control;
    obj.ControlSet(order, :) = 1;
end
end
