function [modulation, carrier, control] = SVM_Config(obj, freq, T, ma, phi, position, options)
arguments
    obj
    freq (1, 1) double
    T (1, 1) double
    ma (1, 1) double
    phi (1, 1) double
    position (1, 2) {mustBeNumeric, mustBeInteger} = [0 0]
    options.SampleTech (1, 1) string {mustBeMember(options.SampleTech, {'SingleEdge', 'Natural'})} = 'SingleEdge'
    options.CarrierPhaseShift (1, 1) double = 0
end

coefficient = 2/sqrt(3);
t = 0:obj.Ts:obj.Period;
carrier = (rem(t.*freq, 1)<1/2) .* (1-4.*rem(t.*freq, 1)) ...
    + (rem(t.*freq, 1)>=1/2) .* (-3+4.*rem(t.*freq, 1));
if options.CarrierPhaseShift ~= 0
    carrier = circshift(carrier, round(options.CarrierPhaseShift/2/pi/freq/obj.Ts));
end
switch options.SampleTech
    case 'SingleEdge'
        t_bias = round(t./obj.Ts);
        t_bias = floor(t_bias.*freq.*obj.Ts) ./ freq;
        phaseA = ma .* coefficient .* sin(2.*pi./T.*t_bias-phi);
        phaseB = ma .* coefficient .* sin(2.*pi./T.*t_bias-phi-2*pi/3);
        phaseC = ma .* coefficient .* sin(2.*pi./T.*t_bias-phi-4*pi/3);
    case 'Natural'
        phaseA = ma .* coefficient .* sin(2.*pi./T.*t-phi);
        phaseB = ma .* coefficient .* sin(2.*pi./T.*t-phi-2*pi/3);
        phaseC = ma .* coefficient .* sin(2.*pi./T.*t-phi-4*pi/3);
end
modulation = phaseA - (max([phaseA; phaseB; phaseC]) ...
    + min([phaseA; phaseB; phaseC])) ./ 2;
control = zeros(2, length(t));
control(1, :) = modulation >= carrier;
control(2, :) = modulation < carrier;
if ~any(position==0)
    obj.Control(position, :) = control;
    obj.ControlSet(position) = 1;
end
end
