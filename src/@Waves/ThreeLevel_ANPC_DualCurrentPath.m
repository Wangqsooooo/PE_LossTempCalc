function [modulation, carrier, control] = ThreeLevel_ANPC_DualCurrentPath(obj, load, phaseshift, order, transient, options)
arguments
    obj, load, phaseshift (1, 1) double
    order (1, :) {mustBeNonnegative, mustBeInteger} = [1 2 3 4 5 6]
    transient (1, 1) double = 3e-6
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
duty_a = modulation; duty_t = transient * load.freq;
u1 = (duty_a >= 0) & ((rem(t.*load.freq, 1) >= 1/2.*(1-duty_a)) & (rem(t.*load.freq, 1) <= 1/2.*(1+duty_a)));
u2 = (duty_a < 0) & ((rem(t.*load.freq, 1) <= -1/2.*duty_a) | (rem(t.*load.freq, 1) >= 1/2.*(2+duty_a)));
u3 = (duty_a >= 0) & ((rem(t.*load.freq, 1) <= 1/2.*(1-duty_a)-duty_t) | (rem(t.*load.freq, 1) >= 1/2.*(1+duty_a)+duty_t));
u4 = (duty_a < 0) & ((rem(t.*load.freq, 1) >= -1/2.*duty_a+duty_t) & (rem(t.*load.freq, 1) <= 1/2.*(2+duty_a)-duty_t));
control = zeros(6, length(t));
control(1, :) = (duty_a >= 0) & ((rem(t.*load.freq, 1) > 1/2.*(1-duty_a)-duty_t) & (rem(t.*load.freq, 1) < 1/2.*(1+duty_a)+duty_t));
control(2, :) = u1 | (u3 + u4) | ((duty_a < 0) & (~u2));
control(3, :) = u2 | (u3 + u4) | ((duty_a >= 0) & (~u1));
control(4, :) = (duty_a < 0) & ((rem(t.*load.freq, 1) < -1/2.*duty_a+duty_t) | (rem(t.*load.freq, 1) > 1/2.*(2+duty_a)-duty_t));
control(5, :) = u3 | (duty_a < 0);
control(6, :) = u4 | (duty_a >= 0);
if strcmp(options.DisplayMode, 'No')
    obj.Control(order, :) = control;
    obj.ControlSet(order) = 1;
end
end
