function [data2, intdat,T,Tint] = anaSST(ctrl,bins,scan,data,drop_time,oversamp,end_drop_time,intT)
%anaSST measures and plots spin readout fidelity for selective spin tunneling
%
%Computes T1 and overall, singlet, and triplet fidelities. Scan loads
%singlet and measures (oversampled) andthen triplet and measures
%(oversampled).  format of data is [S T S T....] (100 of each per row).
%
%Old form of code sets a threshold voltage (Vt) that maximizes # singlets
%found under Vt, and triplets over Vt New version uses fitting equation in
%Barthel paper, to find curve showing dist. voltages for singlets and
%triplets, fidelity found by how much of curve past Vt.
%
% bins is set to 512 if not given. 
% drop_time set to 2.4 us if not given. This is for 2.1 us before marker sent, then 300 ns while tank circuit rings up.  
% ctrl: 
%    full: fit all timesteps (slow). 
%    pl: plot histogram for meas time 
%    fpl: produce histogram plots for 4 different times 
%
%****BE CAREFUL*** with data masking. You might want to check data if pulse defn
%is changed.
if ~exist('scan','var')
    load(uigetfile('.mat'));
end

pulselength = plsinfo('zl', scan.data.pulsegroups(1).name);
pulselength = abs(pulselength(1));

dt = 1/scan.configfn(1).args{3}(2); %integration time bin
data1 = data{1};
ntimesteps=1e-9*pulselength/dt; % # time steps in an 1 pulse sequence. (pulselength given in ns, dt in s). 

datapoints=size(data1,1)*size(data1,2); 
data2 = (reshape(data1',round(ntimesteps),round(datapoints/ntimesteps)))'; % now each row is 1 pulse
samp_num=scan.data.conf.npulse*scan.data.conf.nrep; %number of R runs 

%mask for getting rid of manipulation time
if ~exist ('drop_time','var') || isempty(drop_time)
    drop_time=43e-6;%3e-6;%;2.6e-6;
end
mask = 1:ceil(drop_time/dt); 
data2(:,mask)= [];

if ~exist ('end_drop_time','var') || isempty(drop_time)
    drop_time=3.1e-6;
end
endmask = (size(data2,2)-ceil(end_drop_time/dt):size(data2,2));
data2(:,endmask)=[];

rate = 1/dt;
pts = round(intT*rate);% Number of elements to create the mean over
s1 = size(data2, 1); % # number of time series
s2 = size(data2, 2); % length of each time series
m  = s2 - mod(s2, pts); 

intdat = [];
for i=1:s1
    y  = transpose(reshape(data2(i,1:m), pts, []));     % Reshape x to a [n, m/n] matrix
    intdat = [intdat; transpose(sum(y, 2) / pts)]; % Calculate the mean over the 1st dim
end




avgd = mean(data2,2); %now samp_num x 1 array of avg val of pts
T = dt*(1:size(data2,2)); %array of times of measurements 
Tint = intT*(1:size(intdat,2)); %array of times for integrated data

figure(1); clf; hist(avgd,300);

figure(2); clf; 
plssiz = size(data2,2);
if size(data2,1)>10
    imagesc(Tint.*1e6,linspace(1,10,10),intdat(1:10,:));
else
    imagesc(Tint.*1e6,linspace(1,size(intdat,1),size(intdat,1)),intdat);
end
title('First 10 pulses (integrated data)');
colorbar;
if length(avgd)>1
    caxis([mean(avgd)-5*std(avgd) mean(avgd)+5*std(avgd)]);
end
xlabel('time (\mus)');
ylabel('pulse #')
a=gca;
a.YDir='normal';





%calc T1
%diffSig = mean(downData,2)- mean(upData,2);  %difference between singlet and triplet average voltage as a function of time
%fitfcn = @(p,x)p(1)+p(2).*exp(-1*x./p(3)); % p(1) is some offset between singlet/triplet, p(2) the spacing between peaks, p(3) t1. 
%beta0 = [0, range(diffSig), 1/abs(range(diffSig))*dt];
%fit difference of singlet and triplet
%beta0 = [0, diffSig(1), 1/abs(range(diffSig))*dt]; %QHF 2019/05/29
%params = fitwrap('',T, diffSig', beta0, fitfcn, [0 1 1]);

% %fit Only Triplet data
% tripMean=mean(tripData,2);
% beta0 = [0, tripMean(1), 1/abs(range(tripMean))*dt]; 
% params = fitwrap('',T, tripMean', beta0, fitfcn, [0 1 1]);
%t1=params(3);

%Plot T1 data
%figure(80); clf; hold on;
%set(gcf,'Name','T1 Histograms');
%subplot(4,2,7); hold on;
%plot(T*1e6, diffSig',T*1e6, fitfcn(params, dt*(1:length(diffSig))));
%plot(T, tripMean',T, fitfcn(params, dt*(1:length(tripMean))));
%title(sprintf('T_{1} = %.2f \\mus', 1e6*params(3)));

%this makes V(t) the average V from 0 to t for a specific run
%Note: Histogram is made with data averaged from 0 to t
% upAve = cumsum(upData,1)./repmat((1:size(upData,1))',1,size(upData,2)); 
% downAve = cumsum(downData,1)./repmat((1:size(downData,1))',1,size(downData,2)); 
% allData = [upAve downAve];
% cen = mean(allData(:));
% rng = 6*std(allData(:));
% 
% if ~exist ('bins','var')
% bins=512;
% end
% Vt=linspace(cen-rng,cen+rng,bins); %512 voltage bins with a range of 6 standard deviations 
% 
% if 1 % log data
%   pfunc=@log;
% else
%   pfunc=@(x) x;
% end
% 
% %singHist=(voltage bins,timesteps) 
% singHist = histc(upAve', Vt);
% subplot(2,2,1); hold on;
% imagesc(T, Vt,pfunc(singHist)); title('Singlet Histogram');
% xlabel('T_{meas}(\mus)');
% 
% tripHist = histc(downAve', Vt);
% subplot(2,2,2); hold on;
% imagesc(T, Vt,pfunc(tripHist)); title('Triplet Histogram');
% xlabel('T_{meas}(\mus)'); 
% 
% %fid = (correctly identified/total); cumsum is good way of getting this. we
% %divide by the total number for that time. 
% %The old way; all results marked w/ "unf"
% SfidUnf= cumsum(singHist,1)./repmat(sum(singHist,1),length(Vt),1);  
% TfidUnf= cumsum(tripHist(end:-1:1,:),1)./repmat(sum(tripHist,1),length(Vt),1);
% TfidUnf=TfidUnf(end:-1:1,:);
% fidUnf=(TfidUnf+SfidUnf)/2;
% [maxfidUnf,VtUnf] = max(fidUnf); %VtUnf is optimal Vthreshold ****
% [fidelityUnf,TmeasUnf] = max(maxfidUnf);
% 
% %Now, find V_thresh and T_meas by fitting. 
% hist=singHist+tripHist;
% if exist('ctrl','var')&&~isempty(strfind(ctrl,'full'))
%     short=1;   
%     T2=T;
% else 
%     short=4;
%     T2=short*dt*(1:floor(length(T)/short));
% end
% timestep=floor(length(T)/short);
% [SfidFit,TfidFit,STdiff] = FidelityFit(hist',Vt,t1,dt,singHist',tripHist',samp_num,timestep,short);   %the fit function takes in raw data, the set of voltage bins, t1, averaging time, 
% fidFit=(SfidFit+TfidFit)/2;
% [maxfidFit,VtFit] = max(fidFit); %VtFit is optimal Vthreshold
% [fidelityFit,TmeasFit] = max(maxfidFit);   %Tmeasfit gives the index of the time at which there is max fidelity. use this also to find the vT at that time. Note that since we don't fit all data points, cannot just apply to T.
% t_adj=@(x) x+drop_time-2e-6+0.15e-6; 
% Tnorm=t_adj(T); %this gives the measurement time in terms of dictionary terms. 
% Tnorm2=t_adj(T2); 
% 
% 
%   
% if exist('ctrl','var')&&~isempty(strfind(ctrl,'fpl'))
%     figure(81); clf;
%     figure(82); clf;
%     for i=1:4
%         t=8+(i-1)^2*35;
%         plotter(hist',Vt ,t1, dt,singHist',tripHist',samp_num,t,i,t_adj);
%     end
% elseif exist('ctrl','var')&&~isempty(strfind(ctrl,'pl'))
%     figure(83); clf;
%     i=0; t=TmeasFit*short;
%     plotter(hist',Vt ,t1, dt,singHist',tripHist',samp_num,t,i,t_adj);
% end
% 
% figure(79); subplot(4,2,5); 
% plot(t_adj(dt*short*(1:timestep)),VtFit/bins)
% xlabel('Time')
% ylabel('V_{threshold}')
% title(sprintf('Change in Threshold Voltage Over Time'))
% 
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
% figure(79)
% subplot(2,2,4); hold on
% plot(1e6*Tnorm,maxfidUnf,1e6*Tnorm2,maxfidFit);
% xlabel('T (\mus)');
% title('Best Fidelity');
%  
% fprintf('Fidelity = %.3f (unfit) vs. %.3f (fit) \n Tmeas = %.2f usec (unfit) vs. %.2f usec (fit) \n Vthreshold = %3f (unfit) vs. %3f (fit) \n', fidelityUnf, fidelityFit, t_adj(dt*TmeasUnf)*1e6, t_adj(dt*short*TmeasFit)*1e6, 1e3*Vt(VtUnf(TmeasUnf)), 1e3*Vt(VtFit(TmeasFit)));
% fprintf('F_s = %.3f (unfit) vs. %.3f (fit), F_t = %.3f (unfit) vs %.3f (fit) \n',SfidUnf(VtUnf(TmeasUnf),TmeasUnf),SfidFit(VtFit(TmeasFit),TmeasFit),TfidUnf(VtUnf(TmeasUnf),TmeasUnf),TfidFit(VtFit(TmeasFit),TmeasFit));
% fprintf('T1 = %g us \n',1e6*t1);
% tmeas=dt*short*TmeasFit;
% vthresh=Vt(VtFit(TmeasFit));
% 
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
% 
% 
% end
% 
% function [SfidFit,TfidFit,STdiff] = FidelityFit(hist,Vt ,t1, dt,singHist,tripHist, samp_num,timestep,short)
% 
% for i=1:timestep
%     t=short*i;
%     [fitfn, initfn] = getfn(t*dt*1e-4,t*dt/t1);
%     
%     if t>25 % at larger times, we can rely on the previous fit fcn, with incremented time. 
%         fitpar(i-1,5)=t*dt*1e-4; fitpar(i-1,6)=t*dt/t1; %we increment the decay
%         fitpar(i,:)=fitwrap('',Vt,hist(t,:),fitpar(i-1,:),fitfn,[1 1 1 1 0 0 1]); 
%         %fp(1): average voltage, fp(2): peak spacing, fp(3): coeff singlet peak, fp(4): coeff triplet peak, fp(5): t_m/T1,left
%     % fp(6): t_m/T1,right, fp(7): rms amp noise/peak spacing
%     else
%         fitpar(i,:)=fitwrap('',Vt,hist(t,:),initfn,fitfn,[1 1 1 1 0 0 1]);
%     end
%     fitpar2=fitpar(i,:);
% 
%     Sfit=fitpar2; Sfit(3)=1; Sfit(4)=0; % here, we set the triplet peak coeff. to 0, singlet coeff. to 1
%     fitSing=(fitpar2(3)+fitpar2(4))*fitfn(Sfit,Vt)/samp_num; %Then recalculate the curves
%     Tfit=fitpar2; Tfit(3)=0; Tfit(4)=1;
%     fitTrip=(fitpar2(3)+fitpar2(4))*fitfn(Tfit,Vt)/samp_num;
%     
%     SfidFit(:,i)=cumsum(fitSing); %Sum number in bins under each voltage.
%     TfidFit2=cumsum(fitTrip(end:-1:1));
%     TfidFit(:,i)=TfidFit2(end:-1:1);
%         
% end
%    percentsing=fitpar2(1,3)./(fitpar2(1,3)+fitpar2(1,4)); %The percent of singlets loaded. 
%    STdiff=1./fitpar(floor(timestep/2),2);
%    fprintf('Difference in voltage for singlet triplet peaks is %2g mV\n',STdiff*1e3);
%   %use just the singlet and just triplet histogram to fit the data to find
%   %how many were incorrectly prepared. 
%     fps=fitwrap('',Vt,singHist(12,:),fitpar2,fitfn,[0 0 1 1 0 0 0]);
%     fpt=fitwrap('',Vt,tripHist(12,:),fitpar2,fitfn,[0 0 1 1 0 0 0]);
%     SloadT=fps(4)/(fps(3)+fps(4));
%     TloadS=fpt(3)/(fpt(3)+fpt(4));
%     fprintf('Singlet load error is %.02f \n',SloadT)
%     fprintf('Triplet load error is %.02f \n',TloadS)
%     fprintf('Percent of Singlets loaded is %.02f \n',percentsing)
% end
% 
% function plotter(hist,Vt ,t1, dt,singHist,tripHist,samp_num,t,i,t_adj)
%     [fitfn, initfn] = getfn(t*dt*1e-4,t*dt/t1);
%     fitpar=fitwrap('',Vt,hist(t,:),initfn,fitfn,[1 1 1 1 0 0 1]);
%     Sfit=fitpar; Sfit(3)=1; Sfit(4)=0;
%     singFit=(fitpar(3)+fitpar(4))*fitfn(Sfit,Vt)/samp_num;
%     Tfit=fitpar; Tfit(3)=0; Tfit(4)=1;
%     tripFit=(fitpar(3)+fitpar(4))*fitfn(Tfit,Vt)/samp_num;
%     
%     if i == 0
%       figure(83); subplot(2,1,1); hold on;
%     else
%       figure(81); subplot(2,2,i); hold on;
%     end
%     a=plot(Vt,samp_num*fitpar(3)/(fitpar(3)+fitpar(4))*singFit,'g','LineWidth',2);
%     b=plot(Vt,samp_num*fitpar(4)/(fitpar(3)+fitpar(4))*tripFit,'m','LineWidth',2);
%     c=plot(Vt,samp_num*(fitpar(3)/(fitpar(3)+fitpar(4))*singFit+fitpar(4)/(fitpar(3)+fitpar(4))*tripFit),'r','LineWidth',2);
%     plot(Vt,hist(t,:),'.','MarkerSize',5)
%     xlabel('Voltage')
%     ylabel('Probability')
%     title(sprintf('Distribution at t=%.2f us', t_adj(t*dt)*1e6))
%     
%     if i == 0        
%         figure(83); subplot(2,1,2); hold on;        
%     else
%       figure(82); subplot(2,2,i); hold on;
%     end
%     fps=fitwrap('',Vt,singHist(t,:),fitpar,fitfn,[0 0 1 1 0 0 0]);
%     plot(Vt,fitfn(fps,Vt)/samp_num,'g','LineWidth',2)
%     plot(Vt,singHist(t,:)/samp_num,'+g','MarkerSize',5)
%       
%     fpt=fitwrap('',Vt,tripHist(t,:),fitpar,fitfn,[0 0 1 1 0 0 0]);
%     plot(Vt,fitfn(fpt,Vt)/samp_num,'m','LineWidth',2)
%     plot(Vt,tripHist(t,:)/samp_num,'xm','MarkerSize',5)
%     xlabel('Voltage')
%     ylabel('Probability')
%     title(sprintf('Distribution at t=%.2f us', t*dt*1e6))
% 
% end
% 
% function f=makescalefunc(scale,off)
% f=@(x) x*scale+off;
% end
% 
% % t1 is the ratio of t1 to the relevant measurement time
% function [fitfn, initfn] = getfn(st1, t1)
% % See Barthel 2010 single shot read out paper for equation. This gives
% % function for the gaussian + decay function. Gaussian has form
% % exp[(-v-vt)^2/2sig^2]. Decaying part finds probability of average voltage
% % v (based on time of decay), constructs gaussian centered at v, and
% % integrates over v. 
% distfn = @(a, x) exp(-a(1)) * exp(-(x-1).^2./(2* a(2)^2))./(sqrt(2 * pi) * a(2)) + ...
%     a(1)/2 * exp(a(1)/2 * (a(1) * a(2)^2 - 2 * x)) .* ...
%     (erf((1 + a(1) * a(2)^2 - x)./(sqrt(2) * a(2))) + erf((-a(1) * a(2)^2 + x)./(sqrt(2) * a(2))));
% % parameters: [a(1): t_meas/T1, a(2): rms amp noise/peak spacing x: voltage]
% 
% fitfn = @(a, x) a(3) * distfn(abs(a([5 7])), .5-(x-a(1)).*a(2)) + a(4) * distfn(abs(a([6 7])), .5+(x-a(1)).*a(2));
% %parameters: [a(1): center between peaks, a(2): 1/spacing, a(3): coeff left peak, a(4): coeff right peak, a(5): t_m/T1,left
% % a(6): t_m/T1,right, a(7): rms amp noise/peak spacing]
% % sum(coefficients) = 1 corresponds to a PDF for unity peak spacing.
% % If fitting raw histograms, # samples = sum(fp(:, 3:4), 2) ./(fp(:, 2) * diff(d.x(1:2)));
% 
% initfn.fn = @(x, y)[sum(x.*y)/sum(y), 5/range(x), max(y), max(y), st1, t1, .2];
% initfn.args = {};
% %fifn.vals = [nan(1, 4), -10, 0];
end