function [out] = qbTimeFunc_v2(npi,t,tpi,plt)
% qbTimeFunc_v2(npi,t,tpi) generates a time series associated with a CPMG experiment 
% with npi pi pulses that describes the qubit's frequency as a
% function of time (similar to Cywinski 2008 PRB) such that the time series
% goes between 1 and -1 to represent positive/negative phase accumulation.
% This function allows for a nonzero pi time (tpi), during which the time
% series will be zero. It also outputs the abs^2 of the fft of the time
% series.
%
% npi: number of pi pulses
% t: total experiment time, including the qubit evolution and pi times.
% tpi: pi pulse time
% plt: is optional variable. set plt=1 to generate plots of y(t) and W(f).
% otherwise set 0 or don't include.
%
% ALL TIMES SHOULD BE IN NANOSECONDS
% See also weighFn


if ~exist('plt','var')
    plt=0;
end

nsegs = 2*npi; %here, a segment is defined as:
% [evolve half period, pi pulse, evolve half period]. This is different
% from qbTimeFunc, which specifically handles spin echo experiments (n=1)

te = t - npi*tpi; % total qubit evolution time
if abs(te)<1e-5 %breaks out of function if evolution time is less than 1ns*1e-5 (so basically when evolution time is zero)
    te = 0;
    %display('assume evolution time is zero');
    return %break out of function if evolution time is zero
end
te_per = round(te/nsegs); % qubit evolution time per segment %strictly speaking I should not need round here but I need it 
D = te/t; % duty cycle (fraction of total time that qubit is actually evolving)
R = tpi/t; % fraction of time the pi pulse takes relative to total evolution time (only meaningful for n=1) 

% determine number of points for time series
if ~(mod(te_per,1)==0)
    te_per_fac = 1/mod(te_per,1);
else
    te_per_fac = 1;
end
if ~(mod(tpi,1)==0)
    tpi_fac = 1/mod(te_per,1);
else
    tpi_fac = 1;
end
te_per_fac = te_per_fac;
scale_fac = lcm(tpi_fac,te_per_fac);
    
%npoints = round(t*scale_fac);
te_per_pts = te_per*scale_fac;
tpi_pts = tpi*scale_fac;
npoints = (te_per_pts*nsegs) + (tpi_pts)*npi;


% create time series y_t
y_evo = ones(1,te_per_pts);
y_pi = zeros(1,tpi_pts);

y_t = [];
for i=1:npi
    y_t = [y_t y_evo*(-1)^(i-1) y_pi y_evo*(-1)^(i)];
end
%figure(11); clf; plot(y_t); 

% take FFT of signal
% zero pad signal
minpts = 1e6;%2^20; %1e6 points corresponds to frequency resolution 1 kHz (assuming dt=1 ns)
%zp_pts = npoints*ceil(minpts/npoints);
y_tz = cat(2,y_t,zeros(size(y_t,1),minpts - length(y_t)));

t_seconds = t*1e-9; %time in seconds 
dt = t_seconds/npoints;
tspace = linspace(dt,t_seconds,npoints);
df = 1/(dt*length(y_tz));
y_f = fft(y_tz);
y_f = y_f(1:end/2-1);
f = (0:1:length(y_f)-1)*df;
W_f = dt^2*abs(y_f).^2; %double-sided. need dt^2 here to end up with proper units (matlab FFT does not have dt term)
S_y = 2/(df*length(y_tz)^2)*abs(y_f).^2; %single-sided
%check
if (1 - 1e-10 < sum(S_y)*df/mean(y_tz.^2) < 1 + 1e-10) %ratio should equal 1 if correct
    display('confirmed int(S_y*df)=sigma_y^2');
else
    display('uh oh: int(S_y*df) not equal to sigma_y^2');
    sum(S_y)*df/mean(y_tz.^2)
end
[~,ii] = max(W_f);
fsamp = npi/(t*1e-9);
[~,fsampind] = min(abs(f-fsamp/2));
imax = min(length(f),max(ii,fsampind))*10;

if plt
    figure(41); clf; 
    subplot(1,2,1);
    plot(tspace*1e9,y_t,'k');
    ax = gca;
    ax.YTick = [-1 0 1];
    xlabel('t (ns)');
    ylabel('y(t)');
    ylim([-1.05 1.05]);
    xlim([min(tspace)*1e9 max(tspace)*1e9]);
    subplot(1,2,2);
    loglog(f(1:imax),W_f(1:imax),'k'); hold on; 
    plot(f(ii),W_f(ii),'ro'); 
    xlabel('f (Hz)');
    ylabel('|y(f)|^2');
    xlim([f(1) f(imax)]);
end
    




out = struct;
out.D = D;
out.tpi = tpi;
out.te = te;
out.t = tspace;
out.y_t = y_t;
out.f = f;
out.df = df;
out.W_f = W_f; %double-sided
out.f_maxW = f(ii);
out.f_samp = fsamp;
out.sf = scale_fac;

    
end

