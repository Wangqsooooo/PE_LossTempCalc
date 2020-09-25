function [modulation, carrier, control] = SPWM_Config(obj, freq, T, ma, phi, MinMax, position, options)
arguments
    obj
    freq (1, 1) double
    T (1, 1) double
    ma (1, 1) double
    phi (1, 1) double
    MinMax (1, 2) double = [-1, 1]
    position (1, :) {mustBeNumeric, mustBeInteger} = 0
    options.UpperOrDown (1, 1) string {mustBeMember(options.UpperOrDown, {'Upper', 'Down', 'Both'})} = 'Both'
    options.SampleTech (1, 1) string {mustBeMember(options.SampleTech, {'SingleEdge', 'Natural'})} = 'SingleEdge'
    options.CarrierPhaseShift (1, 1) double = 0
end

t = 0:obj.Ts:obj.Period;
carrier = (rem(t.*freq, 1)<1/2) .* (MinMax(2)-2.*(MinMax(2)-MinMax(1)).*rem(t.*freq, 1)) ...
    + (rem(t.*freq, 1)>=1/2) .* (2*MinMax(1)-MinMax(2)+2.*(MinMax(2)-MinMax(1)).*rem(t.*freq, 1));
if options.CarrierPhaseShift ~= 0
    carrier = circshift(carrier, round(options.CarrierPhaseShift/2/pi/freq/obj.Ts));
end
switch options.SampleTech
    case 'SingleEdge'
        t_bias = round(t./obj.Ts);
        t_bias = floor(t_bias.*freq.*obj.Ts) ./ freq;
        modulation = ma .* sin(2.*pi./T.*t_bias-phi);
    case 'Natural'
        modulation = ma .* sin(2.*pi./T.*t-phi);
end
control = zeros(2, length(t));
control(1, :) = modulation >= carrier;
control(2, :) = modulation < carrier;
if position ~= 0
    if length(position) == 1 && strcmp(options.UpperOrDown, 'Upper')
        obj.Control(position(1), :) = control(1, :);
    elseif length(position) == 1 && strcmp(options.UpperOrDown, 'Down')
        obj.Control(position(1), :) = control(2, :);
    elseif length(position) == 2 && strcmp(options.UpperOrDown, 'Both')
        obj.Control(position, :) = control;
    end
    obj.ControlSet(position) = 1;
end
end
