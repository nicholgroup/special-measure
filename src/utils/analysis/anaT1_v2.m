function [fidelityFit,tmeas,vthresh,t1,str] = anaT1_v2(ctrl,bins,scan,data,timing,percentLimit)
%anaT1_v2 plots measurement historgrams and finds the fidelities and measurement time.
%
%
%[fidelityFit tmeas vthresh t1] = anaT1_v2(ctrl,bins,scan,data,dropStart,dropEnd,clkMult) 
% is adapted from anaScaleRead5.
% bins: number of bins in the histogram. Set to 512 if not given.
% scan:
% data:
% timing: a struct with the following fields
%   rfStart: The time from the beginning of the pulse to when the rf
%   starts.   
%   dropStart: The amount of time after the rf fires to drop. This is to
%   account for the ring-up of the tank circuit.
%   dropEnd: amount of time to disregard from the end of the pulse.
%   lead: speed of the lead, this is for computing the fidelity.
%   t1drop: this is an additional time to drop from the beginning to
%   make the fit better. Could this be included in dropStart?
%   clkMult: The number of nanoseconds per point in the pulse. 

% ctrls:
%   full: fit all timesteps (slow).
%   pl: plot histogram for meas time fpl: produce histogram plots for 4 different times
%   nicefigs: makes nice figures (for papers)
% percentLimit is only used in nicefigures option, and plots the first
% histrogram above that percent readout fidelity (i.e. percentLimit=0.95
% plots the first histogram with >95% readout fidelity). Default is 90%
%
% WARNINGS:
% Data masking happens manually.
% This function assumes that the singlet has a lower voltage than the
% triplet

% Scan loads singlet and measures (oversampled) and
% then triplet and measures (oversampled).
% format of data is [S T S T....] (100 of each per row).
%Old form of code sets a threshold voltage (Vt) that maximizes # singlets found
%under Vt, and triplets over Vt
%New version uses fitting equation in Barthel paper, to find curve showing
%dist. voltages for singlets and triplets, fidelity found by how much of
%curve past Vt.

if ~exist('scan','var')
    load(smgetfile('*t1*.mat'));
end

dropStart=timing.rfStart+timing.dropTime;
dropEnd=timing.dropEnd;
clkMult=timing.clkMult;


%pulselength = plsinfo('zl', scan.data.pulsegroups(1).name).*clkMult;
%pulselength = abs(pulselength(1));
%EJC 2022/01/17 I don't think pulselength is correctly loaded anymore. I
%don't think plsinfo is properly loading in the pulselength used at that
%time in history 
% pulselength = plsinfo('zl', scan.data.pulsegroups(1).name); %EJC 2020/11/27 comment out above two lines and make this able to handle cells... not sure why data storage changed...
% if iscell(pulselength)
%     pulselength = cell2mat(pulselength);
% end
% pulselength = abs(pulselength(1)).*clkMult;

% EJC 2022/01/17 need to get pulselength properly
scantime = getscantime(scan,data);
pilog = plsinfo('log', scan.data.pulsegroups(1).name,[],scantime); %proper way to load plsinfo
pulselength = pilog.params(1)*1e3; %total pulse time in nanoseconds. This is bad because it assumes the first param is the pulselength, but 'zl' option is bad because it can be overwritten 

dt = 1/scan.configfn(1).args{3}(2); %integration time bin
data1 = data{1};
timesteps=1e-9*2*pulselength/dt; % # of time steps in an [S T]. (pulselength given in ns, dt in s).

datapoints=size(data1,1)*size(data1,2);
%data2 = reshape(data1',round(timesteps),round(datapoints/timesteps)); % from [S' S'..x num rows;T' T'..;S'...]we get array with each column=[S' T'] (so row# modulo 425 gives time step)
newsz1 = round(timesteps);
newsz2 = round(datapoints/timesteps);
data2 = reshape(data1',newsz1,newsz2);
samp_num=2*size(data2,2); %number of S/T runs

%mask for getting rid of manipulation time
if ~exist ('dropStart','var') || isempty(dropStart)
    dropStart=43e-6;%3e-6;%;2.6e-6;
end
mask = 1:ceil(dropStart/dt);

maskEnd=1:ceil(dropEnd/dt);

singData = data2(1:size(data2,1)/2,:);
tripData = data2(1+size(data2,1)/2:size(data2,1),:);
%hard coded to mask data. Plot unmasked data to make sense of numbers.
%change it if pulse dfn changes
%YPK 2019/05/27
% To do: make masking intelligent
singData(mask,:)= [];
singData(size(singData,1)-length(maskEnd):end,:)= [];

%singData(end-mask(end):end,:)= [];
tripData(mask,:)= [];
tripData(size(tripData,1)-length(maskEnd):end,:)= [];

%tripData(end-mask(end):end,:)= [];

% singData(1:75,:)= [];
% tripData(1:75,:)= [];
% singData(650:end,:)= [];
% tripData(650:end,:)= [];

T = dt*(1:size(singData,1)); %array of times of measurements
if isfield(timing,'t1drop')
        dropind = timing.t1drop/dt;
    else
        dropind = 1;
end
T1t = T(dropind:end);% EJC 2019/10/08  drop ring up of t1 to get more accurate fit


%calc T1
diffSig = mean(tripData,2)- mean(singData,2);  %difference between singlet and triplet average voltage as a function of time
diffSig = diffSig(dropind:end); %EJC 2019/10/08
fitfcn = @(p,x)p(1)+p(2).*exp(-1*x./p(3)); % p(1) is some offset between singlet/triplet, p(2) the spacing between peaks, p(3) t1.
%beta0 = [0, range(diffSig), 1/abs(range(diffSig))*dt];
%fit difference of singlet and triplet
beta0 = [0, diffSig(1), 1/abs(range(diffSig))*dt]; %QHF 2019/05/29
%params = fitwrap('plinit plfit',T1t, diffSig', beta0, fitfcn, [0 1 1]);
params = fitwrap('plinit plfit',T1t, diffSig', beta0, fitfcn, [1 1 1]); %EJC: 2020/11/13 comment out above line to allow fit of offset


% %fit Only Triplet data
% tripMean=mean(tripData,2);
% beta0 = [0, tripMean(1), 1/abs(range(tripMean))*dt];
% params = fitwrap('',T, tripMean', beta0, fitfcn, [0 1 1]);
t1=params(3);

%Plot T1 data
figure(80); clf; hold on;
set(gcf,'Name','T1 Histograms');
subplot(2,2,3); hold on;
plot(T1t*1e6, diffSig',T1t*1e6, fitfcn(params, dt*(1:length(diffSig))));
%plot(T, tripMean',T, fitfcn(params, dt*(1:length(tripMean))));
title(sprintf('T_{1} = %.2f \\mus', 1e6*params(3)));

%this makes V(t) the average V from 0 to t for a specific run
%Note: Histogram is made with data averaged from 0 to t
singAve = cumsum(singData,1)./repmat((1:size(singData,1))',1,size(singData,2));
tripAve = cumsum(tripData,1)./repmat((1:size(tripData,1))',1,size(tripData,2));
allData = [singAve tripAve];
cen = mean(allData(:));
rng = 6*std(allData(:));

if ~exist ('bins','var')
    bins=512;
end
Vt=linspace(cen-rng,cen+rng,bins); %512 voltage bins with a range of 6 standard deviations

if 1 % log data
    pfunc=@log;
else
    pfunc=@(x) x;
end

%singHist=(voltage bins,timesteps)
singHist = histc(singAve', Vt);
subplot(2,2,1); hold on;
imagesc(T, Vt,pfunc(singHist)); title('Singlet Histogram');
xlabel('T_{meas}(\mus)');

tripHist = histc(tripAve', Vt);
subplot(2,2,2); hold on;
imagesc(T, Vt,pfunc(tripHist)); title('Triplet Histogram');
xlabel('T_{meas}(\mus)');

%fid = (correctly identified/total); cumsum is good way of getting this. we
%divide by the total number for that time.
%The old way; all results marked w/ "unf"
% SfidUnf= cumsum(singHist,1)./repmat(sum(singHist,1),length(Vt),1);
% TfidUnf= cumsum(tripHist(end:-1:1,:),1)./repmat(sum(tripHist,1),length(Vt),1);
% TfidUnf=TfidUnf(end:-1:1,:);
% fidUnf=(TfidUnf+SfidUnf)/2;
% [maxfidUnf,VtUnf] = max(fidUnf); %VtUnf is optimal Vthreshold ****
% [fidelityUnf,TmeasUnf] = max(maxfidUnf);

%Now, find V_thresh and T_meas by fitting.
hist=singHist+tripHist;
if exist('ctrl','var')&&~isempty(strfind(ctrl,'full'))
    short=1;
    T2=T;
else
    short=1; %downsampling time
    T2=short*dt*(1:floor(length(T)/short));
end
timestep=floor(length(T)/short);
[SfidFit,TfidFit,STdiff] = FidelityFit(hist',Vt,t1,dt,singHist',tripHist',samp_num,timestep,short,timing);   %the fit function takes in raw data, the set of voltage bins, t1, averaging time,
fidFit=(SfidFit+TfidFit)/2;
[maxfidFit,VtFit] = max(fidFit); %VtFit is optimal Vthreshold

%left over from when masking was defined this way.
t_adj=@(x) x;%+dropStart-2e-6+0.15e-6;
Tnorm=t_adj(T); %this gives the measurement time in terms of dictionary terms.
Tnorm2=t_adj(T2);

%JMN 2019_09_22 account for mapping error.
%cc is the average probability over the integration time that the triplet
%has not made a transition to a 1-2 charge state.
cc=(timing.lead./Tnorm2).*(exp(-timing.dropTime/timing.lead)-exp(-(Tnorm2+timing.dropTime)./timing.lead));
maxfidFit=maxfidFit-cc;

[fidelityFit,TmeasFit] = max(maxfidFit);   %Tmeasfit gives the index of the time at which there is max fidelity. use this also to find the vT at that time. Note that since we don't fit all data points, cannot just apply to T.



if exist('ctrl','var')&&~isempty(strfind(ctrl,'fpl'))
    figure(81); clf;
    figure(82); clf;
    for i=1:4
        t=8+(i-1)^2*35;
        plotter(hist',Vt ,t1, dt,singHist',tripHist',samp_num,t,i,t_adj,timing);
    end
elseif exist('ctrl','var')&&~isempty(strfind(ctrl,'pl'))
    figure(83); clf;
    i=0; t=TmeasFit*short;
    plotter(hist',Vt ,t1, dt,singHist',tripHist',samp_num,t,i,t_adj,timing);
end

figure(79); clf;
subplot(1,2,1);
plot(t_adj(dt*short*(1:timestep)),VtFit/bins)
xlabel('Time')
ylabel('V_{threshold}')
title(sprintf('Change in Threshold Voltage Over Time'));

subplot(1,2,2); hold on
plot(1e6*Tnorm2,maxfidFit);
xlabel('T (\mus)');
title('Best Fidelity');


% figure(81); clf; hold on;
% set(gcf,'Name','T1 Histogram Fits');
%
% subplot(2,2,1); hold on;
% plot(fidUnf);
% title(sprintf('Fidelity = %.2f  T_{meas} = %.2f \\musec\n V_{threshold} = %.1f mV ', fidelityUnf, 1e6*t_adj(dt*TmeasUnf),1e3*Vt(VtUnf(TmeasUnf))));
% subplot(2,2,2);
% plot(fidFit(:,6:end))
% title(sprintf('Fidelity = %.2f  T_{meas} = %.2f \\musec\n V_{threshold} = %.1f mV ', fidelityFit, 1e6*t_adj(dt*TmeasFit),1e3*Vt(VtFit(TmeasFit))));
%
% figure(79); clf;
% subplot(2,2,4); hold on
% plot(1e6*Tnorm2,maxfidFit);
% xlabel('T (\mus)');
% title('Best Fidelity');


str=sprintf('Fidelity =%.3f (fit) Tmeas = %.2f usec (fit) Vthreshold =  %3f (fit) mV \n', fidelityFit, t_adj(dt*short*TmeasFit)*1e6, 1e3*Vt(VtFit(TmeasFit)));
str=[str sprintf('F_s = %.3f (fit), F_t = %.3f (fit) \n',SfidFit(VtFit(TmeasFit),TmeasFit),TfidFit(VtFit(TmeasFit),TmeasFit))];
str=[str sprintf('T1 = %g us \n',1e6*t1)];
str=[str sprintf('Difference in voltage for singlet triplet peaks is %2g mV\n',STdiff*1e3)];

fprintf(str);

% fprintf('Fidelity =%.3f (fit) Tmeas = %.2f usec (fit) Vthreshold =  %3f (fit) mV \n', fidelityFit, t_adj(dt*short*TmeasFit)*1e6, 1e3*Vt(VtFit(TmeasFit)));
% fprintf('F_s = %.3f (fit), F_t = %.3f (fit) \n',SfidFit(VtFit(TmeasFit),TmeasFit),TfidFit(VtFit(TmeasFit),TmeasFit));
% fprintf('T1 = %g us \n',1e6*t1);
tmeas=dt*short*TmeasFit;
vthresh=Vt(VtFit(TmeasFit));

% if exist('ctrl','var')&&~isempty(strfind(ctrl,'fid'))
%     figure(91); clf;
%     inds=sub2ind(size(fidFit),VtFit,1:length(VtFit));
%     plot(1e6*Tnorm2,1-SfidFit(inds),'b.-')
%         hold on;
%     plot(1e6*Tnorm2,1-TfidFit(inds),'r.-')
%     plot(1e6*Tnorm2,1-maxfidFit,'g.-')
%     xlabel('Time (us)')
%     ylabel('1-Fidelity')
%     title(sprintf('T1 %g us, Vsep %g mV',1e6*t1,1e3*STdiff))
%     %axis([0.3 15 0 0.1]);
% end

%EJC: 2019/9/26 added for presentation quality figs
if exist('ctrl','var')&&~isempty(strfind(ctrl,'nicefigs'))
    
    % PLOT FIDELITY (figure 901)
    visFit = SfidFit+TfidFit-1;
    maxvisFit = max(visFit);
    sz1 = 15;
    sz2 = 10;
    figure(901); clf;
    scatter(1e6*Tnorm2,maxfidFit,sz1,'o',...
        'MarkerFaceColor','b',...
        'MarkerEdgeColor','b');
    hold on;
    if 0    
         maxSfidFit = SfidFit(VtFit);
         maxTfidFit = TfidFit(VtFit);
        scatter(1e6*Tnorm2,maxSfidFit,sz1,'s',...
            'MarkerFaceColor','g',...
            'MarkerEdgeColor','g',...
            'DisplayName','F_{Singlet}');
        scatter(1e6*Tnorm2,maxTfidFit,sz2,'s',...
            'MarkerFaceColor','m',...
            'MarkerEdgeColor','m',...
            'DisplayName','F_{Triplet}');
        scatter(1e6*Tnorm2,maxvisFit,sz2,'s',...
            'MarkerFaceColor','r',...
            'MarkerEdgeColor','r',...
            'DisplayName','Visibility');
       legend('Location','northeast');
    end %singlet, triplet fidelities + visibility... not quite working
    xlabel('T (\mus)');
    ylabel('Fidelity');
    box on;

    % PLOT HISTOGRAM AT MAX FIDELITY (figure 902)
    
    t=TmeasFit*short;
    %plotter(hist',Vt ,t1, dt,singHist',tripHist',samp_num,t,0,t_adj,timing);
    [fitfn, initfn] = getfn(t*dt*1e-4,(t*dt+timing.dropTime)/t1);
    
    fitpar=fitwrap('',Vt,hist(:,t)',initfn,fitfn,[1 1 1 1 0 0 1]);
    Sfit=fitpar; Sfit(3)=1; Sfit(4)=0;
    singFit=(fitpar(3)+fitpar(4))*fitfn(Sfit,Vt)/samp_num;
    Tfit=fitpar; Tfit(3)=0; Tfit(4)=1;
    tripFit=(fitpar(3)+fitpar(4))*fitfn(Tfit,Vt)/samp_num;
    

    figure(902); clf; hold on;
    a = plot(Vt,samp_num*(fitpar(3)/(fitpar(3)+fitpar(4))*singFit+fitpar(4)/(fitpar(3)+fitpar(4))*tripFit),...
        'm','LineWidth',2,'DisplayName','Singlet + Triplet');
    b = fill(Vt,samp_num*fitpar(3)/(fitpar(3)+fitpar(4))*singFit,...
        'c','LineWidth',2,'DisplayName','Singlet Fit');
    c = fill(Vt,samp_num*fitpar(4)/(fitpar(3)+fitpar(4))*tripFit,...
        'y','LineWidth',2,'DisplayName','Triplet Fit');
    b.LineStyle = 'none'; c.LineStyle = 'none';
    %b.FaceAlpha = 0.35; c.FaceAlpha = 0.35;
    plot(Vt,hist(:,t)','k.','MarkerSize',5,'DisplayName','Data');
    
    xlim([min(Vt) max(Vt)]);
    legend('Location','best');
    xlabel('DAQ (V)');
    ylabel('Counts');
    title(sprintf('Distribution at t=%.2f us', t_adj(t*dt)*1e6));
    box on;
    
    % PLOT T1 (figure 903);
    if isfield(timing,'t1drop');
        dropind = timing.t1drop/dt;
    else
        dropind = 1;
    end
    %T1t = T(dropind:end);% EJC 2019/9/26  drop ring up of t1 to get more accurate fit
    
    fitfcn = @(p,x)p(1)+p(2).*exp(-1*x./p(3)); % p(1) is some offset between singlet/triplet, p(2) the spacing between peaks, p(3) t1.
    beta0 = params; %feed in guesses from previous fit in code (without t1.droptime)
    params = fitwrap('plinit plfit',T1t, diffSig', beta0, fitfcn, [0 1 1]);
    
    figure(903); clf;
    plot(T1t*1e6, diffSig','k.','MarkerSize',5,'DisplayName','Data');
    hold on;
    plot(T1t*1e6,fitfcn(params, timing.t1drop+dt*(0:length(diffSig)-1)),'b',...
        'LineWidth',2,'DisplayName','Fit');
    title(sprintf('T_{1} = %.2f \\mus', 1e6*params(3)));
    xlabel('T (\mus)');
    ylabel('DAQ (V)');
    xlim([0 max(T*1e6)]);
    box on;
    
    
    
    % PLOT HISTOGRAM AT MIN Tint WHERE F>percentLimit
    % EJC: 2020/11/27 this was hardcoded to be 98% until today
    if ~exist('percentLimit','var')
        percentLimit = 0.9;
    end
    tperind=min(find(maxfidFit>percentLimit));
    t=tperind*short;
    %plotter(hist',Vt ,t1, dt,singHist',tripHist',samp_num,t,0,t_adj,timing);
    [fitfn, initfn] = getfn(t*dt*1e-4,(t*dt+timing.dropTime)/t1);
    
    fitpar=fitwrap('plinit plfit',Vt,hist(:,t)',initfn,fitfn,[1 1 1 1 0 0 1]);
    Sfit=fitpar; Sfit(3)=1; Sfit(4)=0;
    singFit=(fitpar(3)+fitpar(4))*fitfn(Sfit,Vt)/samp_num;
    Tfit=fitpar; Tfit(3)=0; Tfit(4)=1;
    tripFit=(fitpar(3)+fitpar(4))*fitfn(Tfit,Vt)/samp_num;
    

    figure(904); clf; hold on;
    a = plot(Vt,samp_num*(fitpar(3)/(fitpar(3)+fitpar(4))*singFit+fitpar(4)/(fitpar(3)+fitpar(4))*tripFit),...
        'm','LineWidth',2,'DisplayName','Singlet + Triplet');
    b = fill(Vt,samp_num*fitpar(3)/(fitpar(3)+fitpar(4))*singFit,...
        'c','LineWidth',2,'DisplayName','Singlet Fit');
    c = fill(Vt,samp_num*fitpar(4)/(fitpar(3)+fitpar(4))*tripFit,...
        'y','LineWidth',2,'DisplayName','Triplet Fit');
    b.LineStyle = 'none'; c.LineStyle = 'none';
    %b.FaceAlpha = 0.35; c.FaceAlpha = 0.35;
    plot(Vt,hist(:,t)','k.','MarkerSize',5,'DisplayName','Data');
    
    xlim([min(Vt) max(Vt)]);
    legend('Location','best');
    xlabel('DAQ (V)');
    ylabel('Counts');
    title(sprintf('Distribution at t=%.2f us', t_adj(t*dt)*1e6));
    box on;
    
    
end


end





function [SfidFit,TfidFit,STdiff] = FidelityFit(hist,Vt ,t1, dt,singHist,tripHist, samp_num,timestep,short,timing)

for i=1:timestep
    t=short*i;
    
    %[fitfn, initfn] = getfn(t*dt*1e-4,t*dt/t1);
    
    %JMN 2019_09_22 to account for dropped time segments
    [fitfn, initfn] = getfn(t*dt*1e-4,(t*dt+timing.dropTime)/t1);
    
    if t>25 % at larger times, we can rely on the previous fit fcn, with incremented time.
        fitpar(i-1,5)=t*dt*1e-4; fitpar(i-1,6)=t*dt/t1; %we increment the decay
        fitpar(i,:)=fitwrap('',Vt,hist(t,:),fitpar(i-1,:),fitfn,[1 1 1 1 0 0 1]);
        %fp(1): average voltage, fp(2): peak spacing, fp(3): coeff singlet peak, fp(4): coeff triplet peak, fp(5): t_m/T1,left
        % fp(6): t_m/T1,right, fp(7): rms amp noise/peak spacing
    else
        fitpar(i,:)=fitwrap('',Vt,hist(t,:),initfn,fitfn,[1 1 1 1 0 0 1]);
    end
    fitpar2=fitpar(i,:);
    
    Sfit=fitpar2; Sfit(3)=1; Sfit(4)=0; % here, we set the triplet peak coeff. to 0, singlet coeff. to 1
    fitSing=(fitpar2(3)+fitpar2(4))*fitfn(Sfit,Vt)/samp_num; %normalized singlet peak
    Tfit=fitpar2; Tfit(3)=0; Tfit(4)=1;
    fitTrip=(fitpar2(3)+fitpar2(4))*fitfn(Tfit,Vt)/samp_num; %normalized triplet peak
    
    SfidFit(:,i)=cumsum(fitSing); %Sum number in bins under each voltage.
    TfidFit2=cumsum(fitTrip(end:-1:1));
    TfidFit(:,i)=TfidFit2(end:-1:1);
    
end
percentsing=fitpar2(1,3)./(fitpar2(1,3)+fitpar2(1,4)); %The percent of singlets loaded.
STdiff=1./fitpar(floor(timestep/2),2);
fprintf('Difference in voltage for singlet triplet peaks is %2g mV\n',STdiff*1e3);
%use just the singlet and just triplet histogram to fit the data to find
%how many were incorrectly prepared.
fps=fitwrap('',Vt,singHist(12,:),fitpar2,fitfn,[0 0 1 1 0 0 0]);
fpt=fitwrap('',Vt,tripHist(12,:),fitpar2,fitfn,[0 0 1 1 0 0 0]);
SloadT=fps(4)/(fps(3)+fps(4));
TloadS=fpt(3)/(fpt(3)+fpt(4));
%     fprintf('Singlet load error is %.02f \n',SloadT)
%     fprintf('Triplet load error is %.02f \n',TloadS)
%     fprintf('Percent of Singlets loaded is %.02f \n',percentsing)
end

function plotter(hist,Vt ,t1, dt,singHist,tripHist,samp_num,t,i,t_adj,timing)

%[fitfn, initfn] = getfn(t*dt*1e-4,t*dt/t1);

%JMN 2019_09_22
[fitfn, initfn] = getfn(t*dt*1e-4,(t*dt+timing.dropTime)/t1);


fitpar=fitwrap('',Vt,hist(t,:),initfn,fitfn,[1 1 1 1 0 0 1]);
Sfit=fitpar; Sfit(3)=1; Sfit(4)=0;
singFit=(fitpar(3)+fitpar(4))*fitfn(Sfit,Vt)/samp_num;
Tfit=fitpar; Tfit(3)=0; Tfit(4)=1;
tripFit=(fitpar(3)+fitpar(4))*fitfn(Tfit,Vt)/samp_num;

if i == 0
    figure(83); subplot(2,1,1); hold on;
else
    figure(81); subplot(2,2,i); hold on;
end
a=plot(Vt,samp_num*fitpar(3)/(fitpar(3)+fitpar(4))*singFit,'g','LineWidth',2);
b=plot(Vt,samp_num*fitpar(4)/(fitpar(3)+fitpar(4))*tripFit,'m','LineWidth',2);
c=plot(Vt,samp_num*(fitpar(3)/(fitpar(3)+fitpar(4))*singFit+fitpar(4)/(fitpar(3)+fitpar(4))*tripFit),'r','LineWidth',2);
plot(Vt,hist(t,:),'.','MarkerSize',5)
xlabel('Voltage')
ylabel('Probability')
title(sprintf('Distribution at t=%.2f us', t_adj(t*dt)*1e6))

if i == 0
    figure(83); subplot(2,1,2); hold on;
else
    figure(82); subplot(2,2,i); hold on;
end
fps=fitwrap('',Vt,singHist(t,:),fitpar,fitfn,[0 0 1 1 0 0 0]);
plot(Vt,fitfn(fps,Vt)/samp_num,'g','LineWidth',2)
plot(Vt,singHist(t,:)/samp_num,'+g','MarkerSize',5)

fpt=fitwrap('',Vt,tripHist(t,:),fitpar,fitfn,[0 0 1 1 0 0 0]);
plot(Vt,fitfn(fpt,Vt)/samp_num,'m','LineWidth',2)
plot(Vt,tripHist(t,:)/samp_num,'xm','MarkerSize',5)
xlabel('Voltage')
ylabel('Probability')
title(sprintf('Distribution at t=%.2f us', t*dt*1e6))

end

function f=makescalefunc(scale,off)
f=@(x) x*scale+off;
end

% t1 is the ratio of t1 to the relevant measurement time
function [fitfn, initfn] = getfn(st1, t1)
% See Barthel 2010 single shot read out paper for equation. This gives
% function for the gaussian + decay function. Gaussian has form
% exp[(-v-vt)^2/2sig^2]. Decaying part finds probability of average voltage
% v (based on time of decay), constructs gaussian centered at v, and
% integrates over v.
distfn = @(a, x) exp(-a(1)) * exp(-(x-1).^2./(2* a(2)^2))./(sqrt(2 * pi) * a(2)) + ...
    a(1)/2 * exp(a(1)/2 * (a(1) * a(2)^2 - 2 * x)) .* ...
    (erf((1 + a(1) * a(2)^2 - x)./(sqrt(2) * a(2))) + erf((-a(1) * a(2)^2 + x)./(sqrt(2) * a(2))));
% parameters: [a(1): t_meas/T1, a(2): rms amp noise/peak spacing x: voltage]

fitfn = @(a, x) a(3) * distfn(abs(a([5 7])), .5-(x-a(1)).*a(2)) + a(4) * distfn(abs(a([6 7])), .5+(x-a(1)).*a(2));
%parameters: [a(1): center between peaks, a(2): 1/spacing, a(3): coeff left peak, a(4): coeff right peak, a(5): t_m/T1,left
% a(6): t_m/T1,right, a(7): rms amp noise/peak spacing]
% sum(coefficients) = 1 corresponds to a PDF for unity peak spacing.
% If fitting raw histograms, # samples = sum(fp(:, 3:4), 2) ./(fp(:, 2) * diff(d.x(1:2)));

initfn.fn = @(x, y)[sum(x.*y)/sum(y), 5/range(x), max(y), max(y), st1, t1, .2];
initfn.args = {};
%fifn.vals = [nan(1, 4), -10, 0];
end