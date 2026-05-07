function fp = fioscill(x, y, ctrl, guessf)
% fioscill guesses fit parameters for oscillatory data.
%
% function fp = fioscill(x, y, ctrl,guessf)
% ctrl = 1: offset, cos, sin, freq, shift = 0, decay prefac = 1/mean(abs(x));
% ctrl = 2: offset, amplitdue, phase, freq, shift, decay prefac = 1/mean(abs(x));
% ctrl = 3: different way of getting the phase shift
% guessf: a fixed frequency value to pass to the output argument. Pass []
% to use the calculated frequency value.

% (c) 2010 Hendrik Bluhm.  Please see LICENSE and COPYRIGHT information in plssetup.m.


dx = mean(diff(x)); 
%window=0.5*(1+cos(2*pi*(0:length(x)-1)/(length(x)-1)));
window=1;
ft = fft((y-mean(y)).*window) .* exp(1i * x(1) * (0:length(x)-1) * 2*pi /(dx*length(x)))/length(x);
% hack to get phase shift, factors determined experimentally
ft = ft(1:round(end/2));
[m, mi] = max(abs(ft(2:end)));
xi=max(1,mi-2):min(length(ft)-1,mi+2);
mia=sum(abs(ft(xi+1)).*xi)/sum(abs(ft(xi+1)));
fp(4) = 2* pi* (mia)/((length(x)+1) * dx);
if exist('guessf','var')
    if ~isempty(guessf)%EJC 2021/03/11: added so can manually supply estimate frequency which works for aliased frequencies
        fp(4) = 2*pi*guessf;
    end
end

f=ft(mi+1);
fp(1) = mean(y);
fp(5) = 0;
fp(6) = .5/mean(abs(x));

switch ctrl
    case 1
        fp(3) = -3*real(f);
        fp(2) = -3*imag(f);
    case 2
        fp(3) = angle(f);
        fp(2) = -3*abs(f);
    case 3 %EJC 2020/02/26: hack pi shift for imperfect echo measurements
        fp(3) = angle(f) + pi;
        fp(2) = -3*abs(f);
end
