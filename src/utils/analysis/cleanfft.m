function [out] = cleanfft(data,dt,config)
%out = cleanfft(data,dt,config) takes data and time step dt and calculates the one sided
%fft
% optional argument config: struct
%   config.plot = binary input to plot fft
%   config.zp = # of zeros to append to data to zero pad fft

if ~exist('config','var') || isempty(config)
    config = struct;
end

%define defaults
config = def(config,'zp',0);
config = def(config,'plot',0);

if config.zp>0
    data = cat(2,data,zeros(size(data,1),config.zp));
end

sampF = 1/dt;
f = 0:(sampF/length(data)):sampF/2;

S = zeros(size(data,1),length(f));
fdat_temp = zeros(size(data,1),length(data));
for i=1:size(data,1)
    row = data(i,:);
    fdat_temp(i,:) = abs(fft(row));
    S(i,:) = fdat_temp(i,2:length(f)+1);
end

if config.plot
    figure(200); clf; plot(f,S); xlabel('freq'); ylabel('fft(data)');
end
    
out.f = f;
out.S = S;


return

function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;

