function [ out ] = anaInterDotTran( file, config )
%anaInterDotTran fits a charge transition to the DiCarlo formula
%out=anaInterDotTran( file, config )
% Note: this function assumes a specific ordering or the pulse parameters.
%   file is file name (string)
%   config is struct with optional fields
%       c = [cx cy] for calculating epsilon with an applied barrier gate
%       pulse.
%       f = [fx fy] define direction of eps
%       alpha: detuning lever arm (nominally the sum of the individual
%       lever arms).
%       eTemp: electron temperature.
% See PRL 92, 226801, (2004).



if ~exist('file','var') || isempty(file)
    file = uigetfile('sm_pulsed_zoom_A*.mat');
end

if ~exist('config','var') || isempty(config)
    config = struct;
end

%define default config options
config = def(config,'c',[0.38 0.38]);
config = def(config,'f',[1 -1]);
config = def(config,'alpha',0.21);
config = def(config,'eTemp',0.01);

cx = config.c(1);
cy = config.c(2);
fx = config.f(1);
fy = config.f(2);

d=load(file);
try
    scantime=getscantime(d.scan,d.data);
    try %EJC 2022/07/15... hack... this is getting UGLY... sad
        gd = d.scan.data.pulsegroups.gd;
    catch
        gd = plsinfo('gd',d.scan.data.pulsegroups(1).name,[],scantime);
    end
    t = gd.varpar(:,3)'; %barrier gate pulse
    eps = (gd.varpar(:,1)' + t*cx)./fx; %actual epsilon values
catch
    try
        eps = d.scan.data.eps; % added 7/15/2022 Need to clean up this in the future
        t = d.scan.data.t;
    catch
        eps = d.scan.consts.eps;
        t = d.scan.consts.t;
    end
end

data = squeeze(nanmean(d.data{1})); 

%analyze
out = struct();
out.t_meV = [];
out.eTemp_K = [];
out.offset_mV =[];

for i=1:size(data,1) 
    alpha = config.alpha;
    gammaT = 20.837;%20.807; % GHz/K % HY: 08/01/2024, should be 20.837
    meV2GHz = 241.8; %GHz/meV
    
    xv = eps*alpha*meV2GHz;
    yv = data(i,:);
    
    [~,Ind1] = max(yv);
    [~,Ind2] = min(yv);
    
    beta0(1) = (max(yv)+min(yv))/2;
    beta0(2) = range(yv)/2; 
    beta0(3) = 10; %tunneling
    beta0(4) = config.eTemp; %electron temperature
    beta0(5) = (yv(1)-min(yv))/(xv(1)-xv(Ind2)); %linear correction to the sensor conductance. JMN: fixed slope estimate
    beta0(6) = (xv(Ind1)+ xv(Ind2))/2; % offset in eps
    mask = [1 1 1 0 1 1];
    
    fn =@(p,x) p(1) + p(2).*(x-p(6))./sqrt((x-p(6)).^2 + 4.*p(3).^2).*tanh(sqrt((x-p(6)).^2 + 4.*p(3).^2)./(2.*gammaT.*p(4))) + p(5).*(x-p(6));
    [beta,~,~,~,~,~,se] = fitwrap('plinit plfit',xv,yv,beta0,fn,mask);
    
    out.t_meV = [out.t_meV abs(beta(3))/meV2GHz];
    out.eTemp_K = [out.eTemp_K beta(4)]; % K
    out.offset_mV = [out.offset_mV beta(6)/(alpha*meV2GHz)];
    
end

out.eps= eps;
out.t = t;


return

function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;