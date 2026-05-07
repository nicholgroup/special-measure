function [out] = anaSTM(file,config)
%[out]=anaSTM(file,config) analyzes a S-T- data file
%
% file should be a single file name (string)
% config is an optional struct that can have fields:
% config.c = [cx cy]
% config.f = [fx fy]
% config.zp = zeropad value for anaFreq
% config.phaseshift = phase guess for cos(2*pi*f*x + phase)
% config.decayconst = decay constant guess for exp(-(x/T2*)^(decayconst))
% (2=gaussian)

if ~exist('file','var') || isempty(file)
    file = uigetfile;
end

if ~exist('config','var') || isempty(config)
    config = struct;
end

%define config defaults
config = def(config,'c',[0.38 0.38]); % might need to do a better job of handling cx and cy... could be saved with scans
config = def(config,'f',[-1 1]);
config = def(config,'zp',2^12);
config = def(config,'T1',390e-6);
config = def(config,'phaseshift',0.1); %if this is zero it tends to not fit well because it starts in a local minimum
config = def(config,'decayconst',1.9);

afconfig = struct;
afconfig.zp = config.zp;
afconfig.c = config.c;
afconfig.f = config.f;

fitfn = @(p,x) p(1) + p(2).*cos(2*pi*p(3).*x + p(4)).*exp(-(x./p(5)).^p(6));
guess = zeros(1,6);

%load data
d = load(file);
scantime = getscantime(d.scan,d.data);
gd = plsinfo('xval', d.scan.data.pulsegroups(1).name,[],scantime);
if isfield(d.scan.consts,'B')
    Bext = d.scan.consts.B;
elseif isfield(d.scan.consts,'Bz')
    Bext = d.scan.consts.Bz;
else
    error('Unknown field');
end
estar = d.scan.consts.eps;
evo_time = gd(end,:);
timestep = evo_time(2) - evo_time(1);
af = anaFreq(file,afconfig);

%scale data
[rtd, ~, ~, ~, ~, ~, ~] = anaHistScaleV4(d.scan,d.data,config.T1,'L','','noplot');
osc = squeeze(nanmean(rtd{1}));
%osc = rtd{1}(1,:);

%determine T2* guess
rngz = [];
step = round((1e-6/af.oscfreqs)./(timestep*1e-9));
for zz = 1:floor(length(osc)/step)
    rngz(zz) = range(osc(1+(zz-1)*step:zz*step));
end
T2starguess = (max(find(rngz>1/exp(1)))+1)*timestep*step;
%T2starguess = (max(find(rngz>1/exp(1)))+1)*timestep*step*2;

%determine good guesses
guess(1) = mean(osc);
guess(2) = range(osc)/2;
guess(3) = af.oscfreqs*1e6;
guess(4) = config.phaseshift;
guess(5) = T2starguess*1e-9;
guess(6) = config.decayconst;

%fit
[fp,~,~,~,mse,err,se] = fitwrap('plinit plfit',evo_time*1e-9,osc,guess,fitfn,[1 1 1 1 1 1]);


%store outputs
out.time = evo_time*1e-9;
out.P_S = osc;
out.B = Bext;
out.eps = estar;
out.fitfn = fitfn;
out.fitparams = fp;
out.se = se;

return

%apply a default
function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;
