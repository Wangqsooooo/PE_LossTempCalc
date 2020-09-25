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
carrier = zeros(2, length(t));
carrier(1, :) = (rem(t.*load.freq, 1)<1/2) .* (1-2.*rem(t.*load.freq, 1)) ...
    + (rem(t.*load.freq, 1)>=1/2) .* (-1+2.*rem(t.*load.freq, 1));
carrier(2, :) = carrier(1, :) - 1;
control = zeros(6, length(t));
control(1, :) = modulation >= 0;
control(2, :) = (modulation >= 0 & modulation >= carrier(1, :)) ...
                    | (modulation < 0 & modulation >= carrier(2, :));
control(3, :) = ~control(2, :);
control(4, :) = modulation < 0;
control(5, :) = modulation < 0;
control(6, :) = modulation >= 0;
if strcmp(options.DisplayMode, 'No')
    obj.Control(order, :) = control;
    obj.ControlSet(order, :) = 1;
end
end
