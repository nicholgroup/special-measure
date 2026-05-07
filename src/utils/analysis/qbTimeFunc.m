function [out] = qbTimeFunc(npi,t,tpi)
% qbTimeFunc(npi,t,tpi) generates a time series associated with a CPMG experiment
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
%
% ALL TIMES SHOULD BE IN NANOSECONDS
%
% See also weightFn

nsegs = npi+1; %this definition only works for a spin echo experiment. Use function qbTimeFunc_v2 to handle CPMG experiments. 

te = t - npi*tpi; % total qubit evolution time
te_per = te/nsegs; % qubit evolution time per segment %strictly speaking I should not need round here but I need it 
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
scale_fac = lcm(tpi_fac,te_per_fac);
    
npoints = t*scale_fac;
te_per_pts = te_per*scale_fac;
tpi_pts = tpi*scale_fac;

% create time series y_t
y_evo = ones(1,te_per_pts);
y_pi = zeros(1,tpi_pts);

y_t = y_evo;
for i=1:npi
    y_t = [y_t y_pi y_evo*(-1)^i];
end
%figure(10); clf; plot(tspace,y);

% take FFT of signal
% zero pad signal
minpts = 2^17; %2^17 points corresponds to frequency resolution better than 10 kHz (assuming dt=1 ns)
%zp_pts = npoints*ceil(minpts/npoints);
y_tz = cat(2,y_t,zeros(size(y_t,1),minpts - length(y_t)));

dt = t*1e-9/npoints;
tspace = linspace(dt,t,npoints)*1e-9;
df = 1/(dt*length(y_tz));
y_f = fft(y_tz);
y_f = y_f(1:end/2-1);
f = (1:1:length(y_f))*df;
W_f = abs(y_f).^2;
%figure(10); clf; loglog(f,W)

out = struct;
out.D = D;
out.tpi = tpi;
out.te = te;
out.t = tspace;
out.y_t = y_t;
out.f = f;
out.W_f = W_f;
out.sf = scale_fac;
    
end

