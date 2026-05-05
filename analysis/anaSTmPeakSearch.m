function out = anaSTmPeakSearch(file)
%anaSTmPeakSearch finds the S-T- peak.
%
%anaSTmPeakSearch(file) loads a file and analyzes the data to find the S-T-
%point.

% load/scale/smooth data
figure(400); clf;
d = ana_avg(file);
PT = squeeze(nanmean(d.data{1})); %triplet prob
eps = d.xv{1};
sf = 15;
smPT = smooth(eps,PT,sf);

% find peaks
[pks,locs,w,p] = findpeaks(smPT);
pkinds = (pks>0.05);
stpks = pks(pkinds); % peak triplet prob
steps = eps(locs(pkinds)); % epsilon value of peaks
deps = abs(eps(2)-eps(1));  % epsilon step size
stw = w(pkinds)*deps; % width of peaks along epsilon

% build LZ measurement
target_eps = max(steps); %location of target st peak

eps_start = target_eps - stw(end)*5; %ideal start eps for LZ sweep
eps_end = target_eps + stw(end)*5;

% find minimum allowed epsilon so that don't run into peaks at lower
% epsilon
if length(steps)>1
    min_eps = steps(end-1) + (3*stw(end-1));
else
    min_eps = min(eps);
end

LZepsrng = 1.5;%10*stw(end); %LZ sweep epsilon range
LZstart = max([eps_start,min_eps]); %initial epsilon position in LZ sweep
LZend = LZstart + LZepsrng; % final epsilon position in LZ sweep
%LZeps = [LZstart LZend]; %intial/final epsilon positions for LZ sweep
LZeps = [target_eps-0.75 target_eps + 0.75]; %06/08/2021 EJC force to always just be fixed around center of peak
% if range(LZeps) < 0.5*LZepsrng
%     LZeps(2) = target_eps + LZepsrng/2;
% end

if ((min(LZeps) < min(eps)) | (max(LZeps) > max(eps)+LZepsrng))
    error('calculated epsilon range is outside of allowed values')
end

figure(109); clf;
plot(eps,PT,'k.-'); hold on;
plot(eps,smPT,'r','LineWidth',2);
plot(steps,stpks,'bs','MarkerSize',15);
plot(steps(end),stpks(end),'md','MarkerSize',10,'MarkerFaceColor','g');
line([min(eps) max(eps)],[0.05,0.05],'Color',[0 0 0],'LineStyle','--');
line([LZeps(1) LZeps(1)],[min(PT) max(PT)],'Color','m','LineWidth',2);
line([LZeps(2) LZeps(2)],[min(PT) max(PT)],'Color','m','LineWidth',2);

out = struct;
out.LZeps = LZeps;
out.stmeps = target_eps;

end

