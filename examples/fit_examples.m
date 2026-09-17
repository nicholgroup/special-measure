% fit_examples  Worked examples of the Special Measure fitting wrappers.
%
% Section 1 fits a single dataset with FITWRAP (a wrapper around nlinfit).
% Section 2 fits many datasets simultaneously with MFITWRAP, sharing some
% parameters across all datasets and letting others vary per dataset.
%
% The data in section 2 is simulated, not measured: a sequential-tunneling
% quantum dot coupled to a cold and a hot reservoir, swept in dot chemical
% potential (x) at several source-drain biases (one dataset per bias). The
% forward model lives in the local functions at the bottom of this file.
%
% Requires src/utils/analysis/ on the MATLAB path:
%   addpath(fullfile(pwd,'src','utils','analysis'));

%% 1. Fitwrap example: single dataset, quadratic model
%
% fitwrap(ctrl, x, y, beta0, model, mask) where model is @(p,x).

fn = @(p,x) p(1) + p(2).*x + p(3).*x.^2;
p  = [10, 20, 4];                                    % true parameters

xvals = (1:1:100);
yvals = fn(p,xvals) + randn(size(xvals))*mean(fn(p,xvals))/5;
figure(1); clf; plot(xvals,yvals);

beta0 = [1 1 1];                                     % initial guess
mask  = ones(size(beta0));                           % 1 = fit, 0 = hold fixed
beta  = fitwrap('plinit plfit', xvals, yvals, beta0, fn, mask);

%% 2. Mfitwrap example: simultaneous fit of many bias line cuts
%
% mfitwrap(data, model, p0, opts, mask) takes struct arrays:
%   data(i).x, data(i).y   -- the i'th dataset
%   data(i).vy             -- optional y variances (assumed 1 here)
%   model(i).fn            -- @(p,x), the model for dataset i
%   model(i).pt            -- optional parameter trafo, @(p) -> p for this set
%
% Every model(i).fn sees the *same* parameter vector p, so a parameter is
% shared simply by having several datasets index the same element of p.

% ---- physical constants and simulation settings ----
e = 1.6e-19;

muc  = 0;                        % chemical potential of the cold reservoir
Tc   = 0.1;                      % cold reservoir temperature (K)
Th   = 0.2;                      % hot reservoir temperature (K)
Gam  = 2*pi*10e6;                % tunnel rate (rad/s)
delta = 0;                       % excited-state splitting

muvals  = linspace(-2e-5,2e-5,8).*e;      % source-drain bias values (one dataset each)
epsvals = linspace(-0.2e-3,0.2e-3,64).*e; % dot chemical potential sweep

alpha  = 0.09;                   % gate lever arm (eps = alpha*e*Vg)
offset = 0.8;                    % gate voltage offset (V)
dI     = 10e-15;                 % white current noise (A)

dt   = 0.5;                      % time per point (s)
fc   = 0.1;                      % measurement low-pass corner (Hz)
tc   = 1/(2*pi*fc);

% ---- simulate the dataset ----
% data  : low-pass filtered current + white noise, in pA (what we "measure")
% dataq : heat current out of the hot reservoir, in J/s
data  = zeros(length(muvals),length(epsvals));
dataq = zeros(size(data));

for imu = 1:length(muvals)
    muh = muvals(imu);

    [tmp,tmpQ] = landauerLineCut(epsvals,muc,Tc,muh,Th,Gam,delta);
    dataq(imu,:) = tmpQ;

    tmp = lpfilter(tmp,dt,tc);                       % measurement low-pass
    data(imu,:) = tmp(:) + randn(length(epsvals),1).*dI;
end

data = data*1e12;                                    % A -> pA

% Axes in measured units: gate voltage and source-drain bias
xvals = epsvals./e./alpha + offset;
yvals = muvals./e;

% ---- extract heat current and thermodynamic efficiency ----
figure(556); clf;
subplot(1,3,1);
imagesc(xvals,yvals,data);
xlabel('Dot chemical potential'); ylabel('Source drain bias');
title('Data'); set(gca,'YDir','normal'); colorbar;

subplot(1,3,2);
imagesc(xvals,yvals,dataq);
xlabel('Dot chemical potential'); ylabel('\mu_h-\mu_c');
title('Heat'); set(gca,'YDir','normal'); colorbar;

mh   = repmat(muvals',[1,length(epsvals)]);
Jh   = data*1e-12;                                   % back to A
Jq   = dataq;
P    = Jh.*(muc-mh)./e;                              % extracted power
etaC = 1 - Tc/Th;                                    % Carnot efficiency
eta  = P./Jq;
eta(Jh<0)  = NaN;                                    % need current out of the hot reservoir
eta(muc<mh) = NaN;                                   % need muc > muh to harvest energy

subplot(1,3,3);
imagesc(xvals,yvals,eta./etaC);
xlabel('Dot chemical potential'); ylabel('Source drain bias');
title('Efficiency'); set(gca,'YDir','normal'); colorbar;

% ---- fit every bias line cut at once ----
% Shared across all datasets: Tc, Th, tunnel rate.
% Per dataset: gate voltage offset. The bias of dataset i is itself modelled
% as a start value plus i times a step, so two parameters cover all biases.
%
% p = [Tc, Th, Gamma(GHz), Vsd start(uV), Vsd step(uV), Vg offset per set...]

nsets = size(data,1);

mdata = struct();
model = struct();
for iset = 1:nsets
    mdata(iset).x = xvals;
    mdata(iset).y = data(iset,:);
    % alpha and e are captured from the workspace when the handle is created.
    model(iset).fn = @(p,x) landauerLineCut((x-p(6+iset-1)).*alpha.*e, 0, p(1), ...
        (p(4)+p(5)*iset)*e*1e-6, p(2), p(3)*1e9, 0).*1e12;   % current in pA
end

dmu     = (muvals(2)-muvals(1))./e.*1e6;             % true bias step (uV)
mustart = muvals(1)./e.*1e6;                         % true starting bias (uV)

beta0 = [0.1 0.19 0.1 mustart dmu repmat(0.8,[1,nsets])];
mask  = ones(size(beta0));
mask(5) = 0;                                         % hold the bias step at its known value

beta = mfitwrap(mdata,model,beta0,'plinit plfit',mask);

% For bounded fitting use mfitwrapcon instead:
%   beta = mfitwrapcon(mdata,model,beta0,lb,ub,'plinit plfit',mask);

% ---- reconstruct the fit and compare to the data ----
fdata = zeros(size(data));
for iset = 1:nsets
    fdata(iset,:) = model(iset).fn(beta,mdata(iset).x);
end

figure(444); clf;
subplot(1,4,1);
imagesc(xvals,yvals,data);
xlabel('Dot chemical potential'); ylabel('Source drain bias');
title('data'); set(gca,'YDir','normal'); colorbar;

subplot(1,4,2);
imagesc(xvals,yvals,fdata);
xlabel('Dot chemical potential'); ylabel('Source drain bias');
title('Fit'); set(gca,'YDir','normal'); colorbar;

subplot(1,4,3);
imagesc(xvals,yvals,data-fdata);
xlabel('Dot chemical potential'); ylabel('Source drain bias');
title('Difference'); set(gca,'YDir','normal'); colorbar;

subplot(1,4,4);
imagesc(xvals,yvals,abs(data)./abs(fdata));
xlabel('Dot chemical potential'); ylabel('Source drain bias');
title('Ratio'); set(gca,'YDir','normal'); caxis([0 2]); colorbar;

%% ########## Local functions ##########

function [Jp,Jq,Jc] = meq(Wc,Wh,Qp,Qq)
% Solve the steady state of the master equation and return currents.
%   Wc, Wh -- rate matrices for the cold and hot reservoirs (off-diagonal)
%   Qp, Qq -- weight matrices for particle and heat current
% Positive current flows *out of* the hot reservoir.

W = Wc + Wh;

% Fill in the diagonal so each column sums to zero (probability conserving).
WW = W;
WW(1:size(W,1)+1:end) = -sum(W,1);

pss = null(WW);
if isempty(pss)
    pss = null(WW./mean(WW(:)));                     % try normalizing
    if isempty(pss)
        pss = null(round(WW,5));                     % try rounding
    end
end
if isempty(pss)
    error('meq:noSteadyState','Rate matrix has no null space; cannot find steady state.');
end
pss = pss./sum(pss);                                 % steady state probabilities

% FIXME: taking element (1) picks one vector if the null space is degenerate.
Jp = sum((Qp.*Wh)*pss); Jp = Jp(1);
Jc = sum((Qp.*Wc)*pss); Jc = Jc(1);
Jq = sum((Qq.*Wh)*pss); Jq = Jq(1);
end

function [Wc,Wh,Qp,Qq] = twoLevelU(eps,muc,Tc,muh,Th,Gam,delta)
% Two levels starting from single occupancy, chemical potentials aligned
% with the charging energy U.
% States: 1 = G, 2 = E, 3 = G+E.
kB = 1.38e-23;
fd = @(E,mu,T) 1./(exp((E-mu)./(kB.*T))+1);          % Fermi-Dirac distribution

fc = @(E) fd(E,muc,Tc);
Wc = zeros(3,3);
Wc(1,3) = 1-fc(eps);                                 % G+E to G
Wc(2,3) = 1-fc(eps+delta);                           % G+E to E
Wc(3,1) = fc(eps);                                   % G to G+E
Wc(3,2) = fc(eps+delta);                             % E to G+E
Wc = Wc.*Gam;

fh = @(E) fd(E,muh,Th);
Wh = zeros(3,3);
Wh(1,3) = 1-fh(eps);                                 % G+E to G
Wh(2,3) = 1-fh(eps+delta);                           % G+E to E
Wh(3,1) = fh(eps);                                   % G to G+E
Wh(3,2) = fh(eps+delta);                             % E to G+E
Wh = Wh.*Gam;

% Particle current weights: positive is out of the reservoir.
Qp = [0 0 -1; ...
      0 0 -1; ...
      1 1  0];

% Heat current weights: energy current minus the chemical potential current.
Qq = Qp.*(eps-muh);
end

function [I,Q] = landauerLineCut(eps,muc,Tc,muh,Th,Gam,delta)
% Sweep the dot chemical potential and return particle and heat current,
% then broaden by the Lorentzian lifetime lineshape.
e = 1.6e-19;
h = 6.6e-34;
hbar = h/(2*pi);

I = zeros(1,length(eps));
Q = zeros(1,length(eps));
for ieps = 1:length(eps)
    [Wc,Wh,Qp,Qq] = twoLevelU(eps(ieps),muc,Tc,muh,Th,Gam,delta);
    [jp,jq] = meq(Wc,Wh,Qp,Qq);
    I(ieps) = jp*e;
    Q(ieps) = jq;
end

% Lorentzian of full width hbar*Gam. See Benenti et al., Eq. 96 for why the
% width is set by hbar rather than h.
deps = eps(2)-eps(1);
neps = length(eps);
ee = (-neps/2:1:neps/2).*deps;
kernel = 1./((hbar*mean(Gam))^2 + ee.^2);
kernel = kernel./sum(kernel);
I = conv(I,kernel,'same');
Q = conv(Q,kernel,'same');
end

function [I] = lpfilter(Iin,dt,tc)
% Convolve with a one-sided exponential of time constant tc, i.e. the
% response of a single-pole low-pass filter sampled every dt.
t = (0:1:length(Iin)-1).*dt;
kernel = exp(-(t./tc));
kernel = [kernel(end/2+1:end) kernel(1:end/2)];      % rotate so the peak sits mid-window
kernel = kernel./sum(kernel);
I = conv(Iin,kernel(:),'same');
end
