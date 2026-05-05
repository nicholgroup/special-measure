function [out] = anaSpinFunnel(file,config)
%anaSpinFunnel(file,config) analyzes a high resolution spin funnel scan and tries to identify the singlet-triplet crossing
%
% file and config are optional arguments specifying the file to use, and
% the configuration of the analysis. File can be a string or cell array.
% Config is a struct with the following optional fields:
% pltchk: binary to generate plots of peak identification and partial spin
% funnel fitting
% x: xvals 
% sf: smoothing factor to use when finding singlet-triplet peaks
% finalSTmBGuess: guess of the B value of the stm peak for the final column
% of data
% LocateOnSmooth: locate the stm position using smoothed trace (1) or
% unsmoothed trace (0)
% ScaleData: binary option to scale data
% maxFitOrder: maximum order of the polynomial to try to fit final spin
% funnel data to. Data will be fit using polynomials of order 1 through
% maxFitOrder and will choose the fit order with the smallest error
% outlierMethod: method to remove outliers. can take strings 'mse' or '95%'
% startLocateInd: starts locating ST position at this index of the x-axis
% data (only looks to the left of this ind)
% fitUp: assumes the spin funnel curvature is such that as you move
% leftword across the plot it encourages the possible values to not be
% higher than the previously discovered value by only looking for peaks
% below current value a little bit

if ~exist('file','var')
    [~,~,file] = smgetfile('sm*.mat');
end
if ~iscell(file)
    file = {file};
end

% define default analysis configuration
if ~exist('config','var')
    config = struct;
end
config = def(config,'pltchk',0); % plot checks for debugging
config = def(config,'x',[]); % xvals
config = def(config,'sf',[]); % smoothing factor along B direction for finding stm location
config = def(config,'finalSTmBGuess',[]); %guess value of the stmB val for the final xval (in T)
config = def(config,'LocateOnSmooth',1); %locate STm position using smoothed trace. If 0, locates based on the unsmoothed data
config = def(config,'ScaleData',1); %binary option to scale data
config = def(config,'maxFitOrder',50); % order of polynomial to try fitting final dataset with
config = def(config,'outlierMethod','mse'); % method to identify outliers
config = def(config,'startLocateInd',[]); % start x index for fitting
config = def(config,'fitUp',0); %encourage next located peak to be at or above (in B) current located peak

d = load(file{1});
if config.ScaleData
    [sd,~,pk,~,~,~,~] = anaHistScaleV4(d.scan,d.data,NaN,'L','','noplot');
    data = sd{1};
else
    data = d.data{1}; %use unscaled data
    % normalize each row of data (needed to handle switches)
    data = data - min(data,[],2);
end
try
    log = d.scan.data.pulsegroups.log;
    vp = log.varpar;
    xlab = 'x (mV)';
catch 
    vp = (1:size(d.data{1},2));
    xlab = 'npulse';
end
if isempty(config.x) %this is a bit of a hack to try to make compatible with previous data storage
    if size(vp,2)==size(data,2)
        x = vp;
    else
        x = vp(:,2)';
    end
else
    x = config.x;
end
y = linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
if y(1)>y(end)
    y = fliplr(y);
    data = flipud(data);
end
ylab = [d.scan.loops(1).setchan ' (T)'];

initSig = median(data(:,1)); % initial signal - assume corresponds to state that has not interacted with ST-
if abs(initSig - min(data(:))) > abs(initSig - max(data(:)))
    init = 'high';
else
    init = 'low';
end

f9 = figure(9); clf; cplot(x,y,data);
f9.Name = 'Data';
xlabel(xlab);
ylabel(ylab);
colorbar;

% try to locate STm crossing starting at right edge of data
if isempty(config.sf)
    sf = round(min([length(y)/20 range(y)/0.5e-4]));
else
    sf = config.sf;
end
searchWidth = max([5 round(3*sf/2)]); %number of data points to search around after first stm points found
stmB = zeros(1,length(x))*nan;
if config.pltchk
    f10 = figure(10); clf;
    f10.Name = 'Plot Check';
end

if isempty(config.startLocateInd)
    startLocateInd = size(data,2);
else
    startLocateInd = config.startLocateInd;
end
for i=1:startLocateInd%size(data,2)
    index = startLocateInd - i + 1;
    trace = data(:,index);
    smtrace = smooth(y,trace,sf);
    if i==1
        if ~isempty(config.finalSTmBGuess)
            [~,guessInd] = min(abs(config.finalSTmBGuess - y));
            startInd = guessInd - searchWidth;
            endInd = guessInd + searchWidth;
        else
            startInd = 1;
            endInd = length(trace);
        end
    else
        if config.fitUp
            startInd = stmi - round(searchWidth/2);
            endInd = stmi + 2*searchWidth;
        else
            startInd = stmi - searchWidth;
            endInd = stmi + searchWidth;
        end
    end
    if startInd < 1
        startInd = 1;
    end
    if endInd > length(trace)
        endInd = length(trace);
    end
    
    if strcmp(init,'high')
        if config.LocateOnSmooth
            [~,stmi] = min(smtrace(startInd:endInd));
        else
            [~,stmi] = min(trace(startInd:endInd));
        end
    else
        if config.LocateOnSmooth
            [~,stmi] = max(smtrace(startInd:endInd));
        else
            [~,stmi] = max(trace(startInd:endInd));
        end
    end
    stmi = stmi + startInd - 1;
    stmB(index) = y(stmi);
    
    % once we are in final bit of data, start fitting past few points and
    % estimating where next point will be so can stop fitting when
    % estimated position will be off data set
    if ((i>startLocateInd*0.25) & (i~=startLocateInd))
        endIndFit = min([50,startLocateInd*0.25]);        
        fity = stmB(~isnan(stmB));
        fitx = x(~isnan(stmB));
        p = polyfit(fitx(1:endIndFit),fity(1:endIndFit),4);
        fit = polyval(p,fitx(1:endIndFit));
        %dfit = gradient(fit,fitx(1:endIndFit));
        %meanSlope = mean(dfit(1:3)); 
        if config.pltchk
           figure(10); 
           subplot(1,2,2); cla;
           plot(fitx(1:endIndFit),fity(1:endIndFit),'bo'); hold on;
           plot(fitx(1:endIndFit),fit,'r');
           title(['Fit of recent points']);
        end
        nextSTmB = polyval(p,x(index-1));
        [~,stmi_next] = min(abs(y-nextSTmB));
        stmi = stmi_next;
        if config.fitUp
            if stmi_next > stmi
                stmi = stmi_next;
            end
        end
        if nextSTmB > max(y)
            break
        end
    end
    
    if config.pltchk
        figure(10);
        subplot(1,2,1); cla;
        plot(y,trace,'b'); hold on;
        plot(y,smtrace,'g','LineWidth',2);
        line([stmB(index) stmB(index)],[min(trace) max(trace)],'Color','m','LineWidth',2);
        line([y(startInd) y(startInd)],[min(trace) max(trace)],'Color','k','LineWidth',1);
        line([y(endInd) y(endInd)],[min(trace) max(trace)],'Color','k','LineWidth',1);
        xlabel(ylab);
        ylabel('signal');
        title(['Data column ' num2str(index)]);
    end
    
end

figure(9); hold on;
plot(x,stmB,'x','Color',[1 1 1]);
title(file{1},'interpreter','none');

% fit full dataset
fitx = x(~isnan(stmB));
fity = stmB(~isnan(stmB));
errs = [];
for i=1:config.maxFitOrder
    [p,S] = polyfit(fitx,fity,i);
    [fit,delta] = polyval(p,fitx,S); %delta is standard error estimate
    errs(i) = mean(delta);
end
[~,bestFitOrder] = min(errs);
[p,S] = polyfit(fitx,fity,bestFitOrder);
[fit,delta] = polyval(p,fitx,S); %delta is standard error estimate

% remove outlier poits
stmB_noOutlier = fity;
outlierInds = [];
switch config.outlierMethod
    case '95%' %outliers = points outside 95% confidence interval of polyfit
        for i=1:length(fit)
            est = fity(i);
            min95 = fit(i) - 2*delta(i);
            max95 = fit(i) + 2*delta(i);
            if ((est<min95) | (est>max95))
                outlierInds = [outlierInds i];
            end
        end
        
    case 'mse' %outliers = points with > 10*mse of polyfit
        se = (fit-fity).^2; %squared error
        mse = mean(se); %mean squared error
        for i=1:length(se)
            if se(i) > 10*mse
                outlierInds = [outlierInds i];
            end
        end        
end
stmB_noOutlier(outlierInds) = nan;


f12 = figure(12); clf; 
f12.Name = 'Extracted S-T points and fit';
plot(fitx,fity,'b.','DisplayName','ST points'); hold on;
plot(fitx,fit,'m','DisplayName','Fit');
plot(fitx(outlierInds),fity(outlierInds),'rx','DisplayName','Outliers');
plot(fitx,fit+2*delta,'k--',fitx,fit-2*delta,'k--');
xlabel(xlab);
ylabel(ylab);
legend('ST points',sprintf('polyfit (order %d)',bestFitOrder),'Outliers','95% Prediction Interval','Location','best');
title(file{1},'interpreter','none');

out.data = data;
out.B = stmB;
out.x = x;
out.y = y;
out.fitx = fitx;
out.fity = fity;
out.fit = fit;
out.B_noOutlier = stmB_noOutlier;
out.config = config;

end

function s = def(s,f,v)
    if ((~isfield(s,f)) | isnan(s.(f)))
        s = setfield(s,f,v);
    end
end