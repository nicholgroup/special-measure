function [out,J_model,epsRange,TRange] = Jmap(files)
%Jmap(files) takes a number of exchange oscillation scans and creates a map of J in epsilon and T space
% function [out,J_model,epsRange,TRange] = Jmap(files)
%   files is optional argument of files to analyze.
%   out is a scruct that records eps, T, and extracted J for each file.
%   J_model is the fitted model of J as a funcion of eps and T, with eps as
%   x variable and T as y variable. J_model is an "sfit" object, whose
%   derivatives (both x and y directions) at arbitrary points can be found
%   using [fx,fy] = differentiate(J_model,X,Y).
%   epsRange and TRange are the range of eps and T values, which should be
%   the domain that Jmodel is suitable for.
%
% Units: ns, GHz, mV
%
% the following assumptions are made:
% 1. eps = scan.data.pulsegroups(i).pg.params(2)
% 2. T = scan.data.pulsegrous(i).pg.params(4)

tic

out = struct;

if ~exist('files','var')
    files = clipFiles;
end

if ~iscell(files)
    files = {files};
end

fullJ_fft = [];
fullJ_mod = [];
fullEps = [];
fullT = [];
for ifile = 1:length(files)
    fprintf(sprintf('Generating J map: Iteration %d/%d (%0.1f%%%% complete) \n',ifile,length(files),100*ifile/length(files)));
    warning off;
    s = load(files{ifile});
    warning on;
    evo = s.scan.data.pulsegroups(1).gd.varpar'; %evolution time in nanoseconds
    dt = evo(2)-evo(1); %time step in nanoseconds
    data = s.data;
    %[data,~,~,~,~,~,~] = anaHistScaleV4(s.scan,data,NaN,'G','','noplot');
    data = squeeze(nanmean(data{1})); % scaled data
    
    % pull out J and eps
    J_fft = []; %use fft to extract J
    J_mod = []; %use model fitting to extract J
    eps = [];
    T = [];
    [ffty,freq] = ezfft(data-mean(data,2),dt,2,1e4);
    for iJ = 1:size(ffty,1)
        % FFT extracted J
        [~,Jind] = max(ffty(iJ,1:end/2));
        J_fft(iJ) = freq(Jind);
        
        % fitting extracted J
        yvals = data(iJ,:);
        fitfn = @(p,x) p(1).*exp(-(x./p(2)).^2).*cos(2*pi*p(3)*x+p(4))+p(5);
        beta0 = [range(yvals)/2 5/freq(Jind) freq(Jind) pi mean(yvals)];
        beta1 = fitwrap('',evo(5:end),yvals(5:end),beta0,fitfn,[1 1 1 1 1]);
        J_mod(iJ) = beta1(3);
        
        % plot fit
        %         figure(1111); clf; plot(evo,yvals,'rx');
        %         hold on; plot(evo,fitfn(beta1,evo));
        %         xlabel('Time (ns)'); ylabel('P');
        
        % eps and T values
        eps(iJ) = s.scan.data.pulsegroups(iJ).gd.params(2);
        T(iJ) = s.scan.data.pulsegroups(iJ).gd.params(4);
    end
    
    % store data
    fullJ_fft = [fullJ_fft, J_fft];
    fullJ_mod = [fullJ_mod, J_mod];
    fullEps = [fullEps, eps];
    fullT = [fullT, T];
    
    out(ifile).eps = eps;
    out(ifile).T = T;
    out(ifile).J_fft = J_fft;
    out(ifile).J_mod = J_mod;
end

% find min and max values of eps and T
epsRange = [min(fullEps) max(fullEps)];
TRange = [min(fullT) max(fullT)];

% fit J to eps and T
J_model = fit([fullEps',fullT'], fullJ_mod', 'poly44');
% fitfn = @(a1,a2,a3,a4,b1,b2,b3,b4,c,d,ep,T) sqrt( ( exp( a1*ep+a2*ep.^2+a3*ep.^3+a4*ep.^4 + b1*T+b2*T.^2+b3*T.^3+b4*T.^4 + c ) ).^2 + d.^2);
% fitfn = @(a1,b1,c,d,ep,T) sqrt( ( exp( a1*ep + b1*T + c ) ).^2 + d.^2);
% fitmodel = fittype(fitfn,'independent',{'ep','T'});
% beta0 = [-1 0.01 -23 0.002];
% J_model = fit([fullEps',fullT'], fullJ_mod', fitmodel, 'StartPoint', beta0);

% derivatives
npt = 2^10;
epsSpace = linspace(epsRange(1),epsRange(2),npt); % eps
TSpace = linspace(TRange(1),TRange(2),npt); % T
[epsGrid, TGrid] = meshgrid(epsSpace,TSpace);
[dJdeps, dJdT] = differentiate(J_model,epsGrid,TGrid);

xstr = 'Eps (mV)';
ystr = 'T (mV)';

% plot results
figure(200); clf;
subplot(2,3,1);
plot(J_model, [fullEps',fullT'], fullJ_mod');
ax1 = gca;
shading interp
xlabel(xstr);
ylabel(ystr);
zlabel('J (GHz)');
title('Data and surface fit');

subplot(2,3,4);
cplot(epsSpace,TSpace,J_model(epsSpace,TSpace').*1e3);
for iFile = 1:length(files)
    hold on; plot(out(iFile).eps,out(iFile).T,'k');
end
ax4 = gca;
xlabel(xstr);
ylabel(ystr);
cbtr = colorbar;
cbtr.Label.String = 'J (MHz)';
title('Calibration data traces');

subplot(2,3,2);
cplot(epsSpace,TSpace,abs(dJdeps)*1e3);
ax2 = gca;
xlabel(xstr);
ylabel(ystr);
cbe = colorbar;
cbe.Label.String = '|dJ/d\epsilon| (MHz/mV)';
title('|dJ/d\epsilon|');

subplot(2,3,5);
cplot(epsSpace,TSpace,abs(dJdT)*1e3);
ax3 = gca;
xlabel(xstr);
ylabel(ystr);
cbt = colorbar;
cbt.Label.String = '|dJ/dT| (MHz/mV)';
title('|dJ/dT|');

subplot(2,3,3);
r = abs(dJdeps)./(abs(dJdT));
v = [1; 0.5; 0.3]*logspace(-5,5,11);
[maxr1,maxInd_temp1] = max(r(:));
[rowind1,colind1] = ind2sub(size(r),maxInd_temp1);
cremove = round(0.025*length(epsSpace)); %remove this many points from the edges of the matrix when plotting the contours
cplot(epsSpace,TSpace,r); hold on;
[C,h] = contour(epsSpace(1+cremove:end-cremove),TSpace(1+cremove:end-cremove),r(1+cremove:end-cremove,1+cremove:end-cremove),v(:),'LineColor','m','ShowText','on');
clabel(C,h,'Color','m');
scatter(epsSpace(colind1),TSpace(rowind1),100,'b*');
ax5 = gca;
xlabel(xstr);
ylabel(ystr);
cbr = colorbar; %caxis([0 min(100,max(abs(dJdeps)./(abs(dJdT)),[],'all'))]);
cbr.Label.String = 'ratio |dJ/d\epsilon| / |dJ/dT|';
title('ratio |dJ/d\epsilon| / |dJ/dT|');

subplot(2,3,6);
[maxr2,maxInd_temp2] = max(1./r(:));
[rowind2,colind2] = ind2sub(size(r),maxInd_temp2);
cplot(epsSpace,TSpace,1./r); hold on;
[C,h] = contour(epsSpace(1+cremove:end-cremove),TSpace(1+cremove:end-cremove),1./r(1+cremove:end-cremove,1+cremove:end-cremove),v(:),'LineColor','m','ShowText','on');
clabel(C,h,'Color','m');
scatter(epsSpace(colind2),TSpace(rowind2),100,'b*');
ax6 = gca;
xlabel(xstr);
ylabel(ystr);
cbr = colorbar; %caxis([0 min(100,max((abs(dJdT)./abs(dJdeps)),[],'all'))])
cbr.Label.String = 'ratio |dJ/dT| / |dJ/d\epsilon|';
title('ratio |dJ/dT| / |dJ/d\epsilon|');

colormap(ax1,'parula');
colormap(ax2,'bone');
colormap(ax3,'bone');
colormap(ax4,'parula');
colormap(ax5,'bone');
colormap(ax6,'bone');

pause(0.5);

figure(201); clf;
addspacing_eps = 0;
addspacing_T = 0;
fitNMSE = [];
for ifile = 1:length(files)
    eps = out(ifile).eps;
    T = out(ifile).T;
    J = out(ifile).J_mod.*1e3;
    x1 = J;
    x2 = J_model(eps,T).*1e3;
    try
        %normalized mean square error
        fitNMSE(ifile) = (mse(x1,x2)/norm(x1)).^2;
        out(ifile).fitNMSE = fitNMSE(ifile);
    end
    x1 = x1-min(x1);
    x2 = x2-min(x2);
    if var(T)<0.001
        subplot(1,2,1); hold on;
        plot(eps,x1+addspacing_eps,'x');
        plot(eps,x2+addspacing_eps,'k');
        addspacing_eps = addspacing_eps+max(x1)+1;
    else
        subplot(1,2,2); hold on;
        plot(T,x1+addspacing_T,'x');
        plot(T,x2+addspacing_T,'k');
        addspacing_T = addspacing_T+max(x1)+1;
    end
end
subplot(1,2,1); xlabel('Eps (mV)'); ylabel('J (MHz)'); title('Eps sweep data');
subplot(1,2,2); xlabel('T (mV)'); ylabel('J (MHz)'); title('T sweep data');
figure(201); sgtitle('Calibration data line fit');

pause(0.5);

t = toc;
fprintf(sprintf('Completed in %.1fs. \n',t));

bodytext1 = sprintf('Maximum |dJ/deps|/|dJ/dT| = %0.2f at [eps=%0.2f,T=%0.2f]',maxr1,epsSpace(colind1),TSpace(rowind1));
bodytext2 = sprintf('Maximum |dJ/dT|/|dJ/deps| = %0.2f at [eps=%0.2f,T=%0.2f]',maxr2,epsSpace(colind2),TSpace(rowind2));
bodytext3 = sprintf('Average NMSE: %0.1e\nRange NMSE: %0.1e',mean(fitNMSE),range(fitNMSE));
bodytext4 = [strjoin({'Data files:',strjoin(files,'\n')},'\n')];
bodytext = sprintf('Results:\n%s\n%s\n\n%s\n\n%s',bodytext1,bodytext2,bodytext3,bodytext4);

try
    opts = struct();
    opts.file = files{1};
    opts.body = bodytext;
    opts.title = 'J map';
    opts.figures = [200 201];
    pptprep(opts);
catch
end

end

