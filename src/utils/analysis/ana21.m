%% Analyze 21 readout or pulsed zoom files.

ppt=1;

fname=uigetfile('sm*read*21*.mat');
d = load(fname);
scantime=getscantime(d.scan,d.data);
% t1 = att1('A',scantime,'after');
% histData = anaHistScale(d.scan,d.data,t1); 
vp1=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
vp2=plsinfo('xval',d.scan.data.pulsegroups(end).name,[],scantime);

d1 = squeeze(nanmean(d.data{1}(:,:,1:end/2)));
d2 = squeeze(nanmean(d.data{1}(:,:,(1+end/2):end)));
data = d1-d2;
figure(1); clf;

yvals=linspace(vp1(1,1),vp2(1,1),length(d.scan.data.pulsegroups));
xvals=vp1(2,:);

imagesc(xvals,yvals,data); 
xlabel('mv'); ylabel('mV'); title(fname,'Interpreter','none')
set(gca,'YDir','normal'); set(gca,'XDir','normal');
colorbar;

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%caxis([-3e-3 .5e-3]);


%% UD readout scan image
%%Analyze 21 readout or pulsed zoom files.

ppt=1;

fname=uigetfile('sm*read*UD*.mat');
d = load(fname);
scantime=getscantime(d.scan,d.data);
% t1 = att1('A',scantime,'after');
% histData = anaHistScale(d.scan,d.data,t1); 
vp1=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
vp2=plsinfo('xval',d.scan.data.pulsegroups(end).name,[],scantime);

data = squeeze(nanmean(d.data{1}));
figure(1); clf;
yvals=linspace(vp1(1,1),vp2(1,1),length(d.scan.data.pulsegroups));
xvals=vp1(2,:);

imagesc(xvals,yvals,data); 
xlabel('mv'); ylabel('mV'); title(fname,'Interpreter','none')
set(gca,'YDir','normal'); set(gca,'XDir','normal');
colorbar;

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% UD readout scan line (pos or time)
%%Analyze 21 readout or pulsed zoom files.

ppt=1;
fnames=get_files('*UD*.mat');
figure(1); clf; hold on;
data=[];
for i=1:length(fnames)
    fname=fnames{i};
    %fname=uigetfile('*UD*.mat');
    d = load(fname);
    scantime=getscantime(d.scan,d.data);
    % t1 = att1('A',scantime,'after');
    % histData = anaHistScale(d.scan,d.data,t1);
    xvals=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
    if size(xvals,1)~=1
        xvals=xvals(4,:)
    end

    
    data(i,:)=squeeze(nanmean(d.data{1}));
    
    plot(xvals,data(i,:));
    xlabel('mv'); ylabel('mV'); title(fname,'Interpreter','none')
    set(gca,'YDir','normal'); set(gca,'XDir','normal');
    ax=axis;
    %axis([ax(1) ax(2) -.066 -.056]);
end
if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% Difference of two UD files.

%% Analyze dBz file and plot the freq and contrast vs time.
ppt=1;
d=ana_avg('',struct('opts','noppt no plot'))
try 
    close 1; close 2;
end
data=squeeze(d.data{1});
scantime=getscantime(d.scan,d.data);
vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
xvals=vp(end,:);

fname=d.filename;
rows=3; cols=2;

figure(1); clf; 
ax(1)=subplot(rows,cols,1);
imagesc(data'); set(gca,'YDir','norm'); 
xlabel('repitition'); ylabel('time (ns)');

tt=xvals;
ff=[]; aa=[]; mm=[];
start=2;

if isfield(d.scan.data,'setpt');
    mdbz=1e-3*d.scan.data.setpt;
else
    mdbz=.440;
end
mdbz=.025;
dt=tt(2)-tt(1);
nalias=floor(mdbz/(1/(2*dt)));
for i=1:size(data,1)
    slice=(data(i,:));
    freq=fftData(slice,tt,nalias,0);
    ff(i)=freq;
    aa(i)=max(slice(start:end))-min(slice(start:end));
    mm(i)=mean(slice(start:end));
end

ax(2)=subplot(rows,cols,2);
plot(ff); xlabel('repitition'); ylabel('Frequency (GHz)'); 
title(sprintf('mean = %3.1f MHz std = %3.0f MHz',mean(ff)*1e3,std(ff)*1e3));

ax(3)=subplot(rows,cols,3);
plot(aa,'.-'); %xlabel('repitition'); 
ylabel('Contrast (pk-pk)'); ylim([0 1]);

% ax(4)=subplot(rows,cols,4);
% hist(d.data{1}(:),50,'.-');
% plot(mm,'.-'); %xlabel('repitition'); 
% ylabel('Mean'); ylim([0,1]);

%fit the data.
stop=size(data,2);
vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
xvals=vp(end,:);
%xvals=linspace(1,size(data,2),size(data,2));
yvals=squeeze(nanmean(data));
fp = fioscill(xvals, yvals, 2);
yvals=yvals(start:stop);
xvals=xvals(start:stop);

if 1
    freqGuess=.05;
else
    freqGuess=fp(4)/(2*pi);
end

fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*p(3)+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
beta=[mean(yvals) (max(yvals)-min(yvals))/2 freqGuess 0 50 2 -.1/100];
mask=[1 1 1 1 1 0 1];
beta=fitwrap('',xvals,yvals,beta,fitfn,mask);
mask=[1 1 1 1 1 0 1];
[beta,~,~,~,~,err]=fitwrap('',xvals,yvals,beta,fitfn,mask);
fit=fitfn(beta,xvals);
subplot(rows,cols,[5]); hold on;
plot(xvals,yvals,'b.-'); plot(xvals,fit,'k');
xlabel('Time'); ylabel('Mean'); 
title(sprintf('T2* = %4.2f ns, F = %.1f+/- %.1f MHz A=%1.2f',abs(beta(5)),abs(beta(3))*1e3,abs(err(1,3,1))*1e3,beta(2)));

fprintf('data mean is %.4f\n',nanmean(yvals));

figure(401);
axlims=axis;
ax1=gca;
figure(1);
ax2=subplot(rows,cols,[4 6]); hold on;
copyobj(allchild(ax1),ax2); axis(axlims);



%linkaxes(ax,'x');

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% Plot a chevron
d=ana_avg('',struct('ops',''));
ppt=1;
fname=d.filename;

%process the image
data=(d.data{1});
nrep=size(d.data{1},1);
dataAvg=squeeze(nanmean(data(1:end,:,:)));
yvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints)./1e6;
xvals=d.xv{1};
figure(223); clf; 
%subplot(2,1,1); 
imagesc(xvals,yvals,dataAvg); set(gca,'YDir','norm');
xlabel('Burst time (ns)'); ylabel('Frequency (MHz)'); colorbar;

% plot and fit a slice
if 0
sliceVal=937;
[val ind]=min(abs(yvals-sliceVal));
yvals=dataAvg(ind,:);
sliceStart=1;

%estimate the freq and phase
fp = fioscill(xvals, yvals, 2);

xvals=xvals(sliceStart:end);
yvals=yvals(sliceStart:end);

%estimate the decay time
per=1/fp(4);
dt=xvals(2)-xvals(1);
perPoints=round(per/dt);
firstPer=yvals(1:1+perPoints);
lastPer=yvals(end-perPoints:end);
decayTime=sqrt(xvals(end)/log(mean(abs(firstPer))/mean(abs(lastPer))));
if~isreal(decayTime)
    decayTime=50
end

%do the fit
fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3))+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime*2 2 -.1/1000];
mask=[1 1 1 1 1 0 1];
beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
% mask=[1 1 1 1 1 0];
% beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
fit=fitfn(beta,xvals);
figure(1); subplot(2,1,2); hold on; plot(xvals,yvals,'b.-'); plot(xvals,fit,'k');
title(sprintf('Slice at %3.0f MHz, T2* = %4.0f ns, F = %2.3f MHz',sliceVal,abs(beta(5)),abs(beta(3))*1e3));
subplot(2,1,2); plot(xvals,dataAvg(ind,:));
end
if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% ALLXY (see Matt Reed's thesis)

ppt=1;
d=ana_avg('',struct('side','A','opts','noppt no plot noscale'))
try 
    close 1; close 2;
end
data=squeeze(nanmean(d.data{1}));
figure(1); clf; plot(nanmean(data,2),'bo-');
fname=d.filename;


if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% ALL XY (see Matt Reed's thesis) one pulsegroup
ppt=1;
d=ana_avg()
try 
    close 1; close 2;
end
data=squeeze(nanmean(d.data{1}));
figure(1); clf; bar((data));
fname=d.filename;


if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% Analyze T2* vs rabi drive, sweep with channel
d=ana_avg('',struct('ops',''));
ppt=1;
fname=d.filename;

%process the image
data=(d.data{1});
nrep=size(d.data{1},1);
dataAvg=squeeze(nanmean(data));
yvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
xvals=d.xv{1};
figure(1); clf;
subplot(4,1,1); imagesc(xvals,yvals,dataAvg); set(gca,'YDir','norm');
xlabel('Burst time (ns)'); ylabel('Rabi amplitude'); colorbar;

% plot and fit a slice
T2=[]; T2err=[]; amp=[];
rabi=[];

figure(200); clf;
colors={'r' 'g' 'b' 'c' 'm' 'k'};
for i=1:size(dataAvg,1)
    yvals=dataAvg(i,:);
    sliceStart=1;
    
    %estimate the freq and phase
    fp = fioscill(xvals, yvals, 2);
    
    xvals=xvals(sliceStart:end);
    yvals=yvals(sliceStart:end);
    
    %estimate the decay time
    per=1/fp(4);
    dt=xvals(2)-xvals(1);
    perPoints=round(per/dt);
    firstPer=yvals(1:1+perPoints);
    lastPer=yvals(end-perPoints:end);
    decayTime=sqrt(xvals(end)/log(mean(abs(firstPer))/mean(abs(lastPer))));
    
    if ~isreal(decayTime)
        decayTime=10;
    end
     
    if decayTime<0
        decayTime=10;
    end
    
    %do the fit
    fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3))+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
    if i==1
    beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime*2 2 0];
    else
        beta(3)=fp(4)/(2*pi);
    end
    mask=[1 1 1 1 1 0 0];
    [beta,~,~,~,~,err]=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    % mask=[1 1 1 1 1 0];
    % beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    fit=fitfn(beta,xvals);
    
    figure(200);  hold on; plot(xvals,yvals+i,[colors{mod(i,6)+1} '.']); plot(xvals,fit+i,colors{mod(i,6)+1});
    
    rabi(i)=abs(beta(3))*1e3;
    T2(i)=abs(beta(5));
    T2err(i)=err(1,5,1);
    amp(i)=beta(2);
end

figure(1); 
subplot(4,1,2);
yvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
errorbar(yvals,T2,T2err,'-o'); xlabel('Rabi amplitude'); ylabel('T2*');
ax=axis; axis([ax(1) ax(2) 0 1500]);

subplot(4,1,3);
plot(yvals,rabi,'o-');
xlabel('Rabi amplitude'); ylabel('Rabi Freq');
ax=axis; axis([ax(1) ax(2) 0 40]);

subplot(4,1,4);
plot(yvals,amp,'o-');
xlabel('Rabi amplitude'); ylabel('Visiblity');
ax=axis; axis([ax(1) ax(2) 0 1]);

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1 200]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end




%% Mixer Cal: analyze T2* vs rabi drive, sweep with pulsegroup
d=ana_avg('',struct('ops',''));
ppt=1;
fname=d.filename;

%process the image
data=(d.data{1});
nrep=size(d.data{1},1);
stop=16; %dont average all the data if the gradient fell away.
dataAvg=squeeze(nanmean(data(1:stop,:,:)));
yvals=d.tv;
xvals=d.xv{1}; 
figure(1); clf;
subplot(4,1,1); imagesc(xvals,yvals,dataAvg); set(gca,'YDir','norm');
xlabel('Burst time (ns)'); ylabel('Rabi amplitude'); colorbar;

% plot and fit a slice
T2=[]; T2err=[]; amp=[];
rabi=[];

figure(200); clf;
colors={'r' 'g' 'b' 'c' 'm' 'k'};
for i=1:size(dataAvg,1)
    yvals=dataAvg(i,:);
    sliceStart=1;
    
    %estimate the freq and phase
    fp = fioscill(xvals, yvals, 2);
    
    xvals=xvals(sliceStart:end);
    yvals=yvals(sliceStart:end);
    
    %estimate the decay time
    per=1/fp(4);
    dt=xvals(2)-xvals(1);
    perPoints=round(per/dt);
    firstPer=yvals(1:1+perPoints);
    lastPer=yvals(end-perPoints:end);
    decayTime=sqrt(xvals(end)/log(mean(abs(firstPer))/mean(abs(lastPer))));
    
    if ~isreal(decayTime)
        decayTime=50;
    end
    
    if decayTime<0
        decayTime=50;
    end
    
    if decayTime>500
        decayTime=50;
    end
    
    %do the fit
    fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3))+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
    beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) 0 xvals(end)/2 2 0];

%     if i==1
%         beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime*2 2 0];
%     else
%         beta(3)=fp(4)/(2*pi);
%     end
    mask=[1 1 1 1 1 0 0];
    [beta,~,~,~,~,err]=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    % mask=[1 1 1 1 1 0];
    % beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    fit=fitfn(beta,xvals);
    
    figure(200);  hold on; plot(xvals,yvals+i,[colors{mod(i,6)+1} '.']); plot(xvals,fit+i,colors{mod(i,6)+1});
    
    rabi(i)=abs(beta(3))*1e3;
    T2(i)=abs(beta(5));
    T2err(i)=err(1,5,1);
    amp(i)=beta(2);
end

figure(1); 

subplot(4,1,2);
yvals=d.tv;
plot(yvals,T2,'-o'); xlabel('Rabi amplitude'); ylabel('T2*');
ax=axis; axis([ax(1) ax(2) 0 1000]);

subplot(4,1,3);
plot(yvals,rabi,'o-');
xlabel('Rabi amplitude'); ylabel('Rabi Freq');
%ax=axis; axis([ax(1) ax(2) 0 25]);

subplot(4,1,4);
plot(yvals,amp,'o-');
xlabel('Rabi amplitude'); ylabel('Visiblity');
%ax=axis; axis([ax(1) ax(2) 0 1]);

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end

%% Single rabi line.
fname=get_files('sm_*.mat');
d=load(fname{1}); fname=fname{1};
scantime=getscantime(d.scan,d.data);
vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
dd=diff(vp,2);
ind=find(dd<0)+2;
xvals=vp(ind:end);
nrep=d.scan.data.conf.nrep;
dt=repmat(xv,[nrep,1]);
yvals=nanmean(d.data{1});
figure(1); clf; plot(xvals,yvals)


%do the fit
fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3)+p(8).*x)+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime 2 0 0];
mask=[1 1 1 1 1 0 0 0];
beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
% mask=[1 1 1 1 1 0];
% beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
fit=fitfn(beta,xvals);
figure(1); clf; hold on; plot(xvals,yvals,'b.-'); plot(xvals,fit,'k');
title(sprintf('T2* = %4.0f ns, F = %2.3f MHz',abs(beta(5)),abs(beta(3))*1e3));

%% T1 scan.
% analyzes a scan with t1 groups.
% expects to have J, dbz, and dJDe defined in scan.data.


ppt=1;
fname=get_files('sm_*.mat');
rows=ceil(sqrt(length(fname)));
cols=rows;
freqs=[]; noise=[]; noiseUpper=[]; noiseLower=[];
    figure(2); clf; hold on;

for i=1:length(fname)
    
    d=load(fname{i}); 
    scantime=getscantime(d.scan,d.data);
    try
        dbzsetpt=d.scan.data.dbz;
        J=d.scan.data.J;
        dJde=d.scan.data.dJde*1e6/1e-3;
    catch
        dbzsetpt=NaN;
        J=NaN;
        dJde=NaN;
    end
    freq=sqrt(dbzsetpt^2+J^2);
    
    data=d.data{1};
    data=squeeze(nanmean(data));
    
    t1data=data;
    t1xvals=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
    t1xvals=t1xvals(2,:);
    figure(2); 
    
    fitfn=@(p,x) p(1)+p(2).*exp(-x/p(3));
    beta=[mean(t1data) (t1data(1)-t1data(end))  t1xvals(length(t1xvals/2))];
    mask=[1 1 1 ];
    [beta,~,~,~,~,err]=fitwrap('plfit plinit',t1xvals,t1data,beta,fitfn,mask);
    fit=fitfn(beta,t1xvals);
    T1=beta(3)*1e-6;
    Se=sqrt(2/(T1*(2*pi)*dJde^2*dbzsetpt^2/freq^2));
    %see John's notes.
    %2 in numerator b/c singled sided
    %2pi in demoninator to convert from (rad/s)^2/(rad/s) to Hz^2/Hz
    % dJDe^2 to convert to V^2/Hz
    %trigonometric factor b/c J is not perpendicular to the splitting.
    SeLower=sqrt(2/((T1+err(1,3,1)*1e-6)*(2*pi)*dJde^2*dbzsetpt^2/freq^2));
    SeUpper=sqrt(2/((T1-err(1,3,1)*1e-6)*(2*pi)*dJde^2*dbzsetpt^2/freq^2));
    SeErr=((Se-SeLower)+(SeUpper-Se))/2;
    
    figure(2);
    subplot(rows,cols,i); hold on;
    plot(t1xvals,t1data,'bo-');
    plot(t1xvals,fit,'k-');
    title(sprintf('T1=%1.1d +/- %1.1d, Seps=%3.3d +/- %3.3d \n F=%3.0f MHz, J=%3.0f MHz, dBz = %3.0f MHz',T1,err(1,3,1)*1e-6,Se,SeErr,freq,J,dbzsetpt));
    
    if ppt && length(fname)==1
        ppt=guidata(pptplot);
        set(ppt.e_file,'String',fname{i});
        set(ppt.e_figures,'String',['[2]']);
        set(ppt.e_title,'String',fname{i});
        set(ppt.e_body,'String','');
        set(ppt.exported,'Value',0);
    end
    
    freqs(i)=freq;
    noise(i)=Se;
    noiseUpper(i)=SeUpper;
    noiseLower(i)=SeLower;
    
end

figure(3); clf; h=errorbar(freqs,noise,noise-noiseLower,noiseUpper-noise,'bo');
xlabel('Frequency (MHz)'); ylabel('V/rt(Hz)');
%figure(3); clf; h=plot(freqs,noise,'bo');

% set(get(h,'Parent'), 'YScale', 'log');
% set(get(h,'Parent'), 'XScale', 'log');

%% T1 image
d=ana_avg('',struct('ops',''));
ppt=1;
fname=d.filename;

%process the image
data=(d.data{1});
nrep=size(d.data{1},1);
stop=16; %dont average all the data if the gradient fell away.
dataAvg=squeeze(nanmean(data(1:stop,:,:)));
yvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints)./1e6;
xvals=d.xv{1};
figure(1); clf; 
%subplot(2,1,1); 
imagesc(xvals,yvals,dataAvg); set(gca,'YDir','norm');
xlabel('Burst time (ns)'); ylabel('Frequency (MHz)'); colorbar;

t1vals=[]; t1err=[];
for i=1:size(dataAvg,1)
    t1data=dataAvg(i,:);
    tzxvals=xvals;
    fitfn=@(p,x) p(1)+p(2).*exp(-x/p(3));
    beta=[mean(t1data) (t1data(1)-t1data(end))  t1xvals(length(t1xvals)/2)];
    mask=[1 1 1 ];
    [beta,~,~,~,~,err]=fitwrap('plfit plinit',t1xvals,t1data,beta,fitfn,mask);
    fit=fitfn(beta,t1xvals);
    t1vals(i)=beta(3);
    t1err(i)=err(1,3,1);
    
end

figure(222); clf; plot(yvals,t1vals,'o-');
figure(223); clf; plot(yvals,nanmean(dataAvg(:,1:1),2))

%% Load files and plot echo T2 vs rabi drive

fnames=get_files('sm*.mat');
if ~iscell(fnames)
    fnames={fnames};
end
t2=[];
for i=1:length(fnames);
    out=anaTomoXYZ(fnames{i},struct('opts','nocal pauli'));
    r=sqrt(sum(out.data{1}'.^2));
    fitfn=@(p,x) p(1)+p(2).*exp(-(x./p(3)).^p(4));
    beta=[0 max(r) .5 2];
    beta=fitwrap('plinit plfit',out.xvals,r,beta,fitfn,[1 1 1 1]);
    t2(i)=beta(3);
    
end

figure(222); clf; plot(t2);

%% Scratch: echo, plot and fit contrast vs time

fnames=get_files('sm_*echo*.mat');

vis=[];
rabi=[];
t2=[];
scale=[];

for j=1:length(fnames)
    d=ana_avg(fnames{j});
    data=squeeze(nanmean(d.data{1}));
    c1=[];
    freq1=[];
    for i=1:size(data,1)
        c1(i)=nanstd(data(i,:));%max(data(i,:))-min(data(i,:));
        fp=fioscill(d.xv{1},data(i,:),1);
        freq1(i)=fp(4)/(2*pi);
    end
    
    %scale(j)=d.scan.data.scale;

    fitfn=@(p,x) p(1)+p(2).*exp(-(x./p(3)).^p(4));
    beta=[0 max(c1) 2 2];
    beta=fitwrap('plinit plfit',d.tv',c1,beta,fitfn,[1 1 1 1]);
    figure(222); clf; plot(d.tv,c1,'o');
    figure(223); clf; imagesc(data); set(gca,'YDir','normal'); title(sprintf('T2=%3.3f',beta(3)));
    
    t2(j)=beta(3);
    rabi(j)=freq1(2);
    vis(j)=beta(2);
end

%% Plot amp for fixed evo vs scale

d=ana_avg();
data=squeeze(nanmean(d.data{1}));

c1=[];
freq1=[];
for i=1:size(data,1)
    c1(i)=max(data(i,:))-min(data(i,:));
    fp=fioscill(d.xv{1},data(i,:),1);
    freq1(i)=fp(4)/(2*pi);
end

figure(222); clf; imagesc(data); set(gca,'YDir','normal');
figure(333); clf; plot(freq1)
figure(332); clf; plot(c1);

%% 4-phase mixer cal, qubit A

fprintf('Load A mixer scan file \n');

d=ana_avg();
dataAvg=squeeze(nanmean(d.data{1}));
xvals=d.xv{1};
rabi=[];
figure(200); clf;
colors={'r' 'g' 'b' 'c' 'm' 'k'};

for i=1:size(dataAvg,1)
    yvals=dataAvg(i,:);
    sliceStart=1;
    
    %estimate the freq and phase
    fp = fioscill(xvals, yvals, 2);
    
    xvals=xvals(sliceStart:end);
    yvals=yvals(sliceStart:end);
    
    %estimate the decay time
    per=1/fp(4);
    dt=xvals(2)-xvals(1);
    perPoints=round(per/dt);
    firstPer=yvals(1:1+perPoints);
    lastPer=yvals(end-perPoints:end);
    decayTime=sqrt(xvals(end)/log(mean(abs(firstPer))/mean(abs(lastPer))));
    
    if ~isreal(decayTime)
        decayTime=50;
    end
    
    if decayTime<0
        decayTime=50;
    end
    
    if decayTime>500
        decayTime=50;
    end
    
    %do the fit
    fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3))+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
    beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) 0 decayTime*2 2 0];

%     if i==1
%         beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime*2 2 0];
%     else
%         beta(3)=fp(4)/(2*pi);
%     end
    mask=[1 1 1 1 1 0 0];
    [beta,~,~,~,~,err]=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    % mask=[1 1 1 1 1 0];
    % beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    fit=fitfn(beta,xvals);
    
    figure(200);  hold on; plot(xvals,yvals+i*.5,[colors{mod(i,6)+1} '.']); plot(xvals,fit+i*.5,colors{mod(i,6)+1});
    
    rabi(i)=abs(beta(3))*1e3;
end
phase=[0 pi/2 pi 3*pi/2]; phase=[phase phase phase]
x=real(exp(1i.*phase).*rabi);
y=imag(exp(1i.*phase).*rabi);

ir=rabi(3)/rabi(1);
qr=rabi(4)/rabi(2);
iqr=rabi(1)/rabi(2);

fprintf('I ratio is %2.2f \n',rabi(3)/rabi(1));
fprintf('Q ratio is %2.2f \n',rabi(4)/rabi(2));
fprintf('IQ ratio is %2.2f \n',rabi(1)/rabi(2));
% fprintf('X sum is %2.2f \n',sum(x));
% fprintf('Y sum is %2.2f \n',sum(y));


% figure(223); clf; plot(x,y,'o');
% hold on; plot(mean(rabi).*cos(0:.01:2*pi)+sum(x),mean(rabi).*sin(0:.01:2*pi)+sum(y),'r')
% axis('equal');

% try to figure out the crosstalk. 
x1=rabi(1);
x2=-rabi(3);
xlen1=sqrt(x(1+4)^2+y(1+4)^2);
xlen2=sqrt(x(3+4)^2+y(3+4)^2);
y1=rabi(2);
y2=-rabi(4);
ylen1=sqrt(x(2+4)^2+y(2+4)^2);
ylen2=sqrt(x(4+4)^2+y(4+4)^2);
%%d.scan.data.amp=.5; d.scan.data.otherAmp=.5;

if d.scan.data.otherAmp~=0
    x0_1=(xlen1^2-xlen2^2-x1^2+x2^2)/(2*(x1-x2));
    y0_1=(ylen1^2-ylen2^2-y1^2+y2^2)/(2*(y1-y2));
    
    
    % try to figure out the crosstalk.
    x1=rabi(1);
    x2=-rabi(3);
    xlen1=sqrt(x(1+8)^2+y(1+8)^2);
    xlen2=sqrt(x(3+8)^2+y(3+8)^2);
    y1=rabi(2);
    y2=-rabi(4);
    ylen1=sqrt(x(2+8)^2+y(2+8)^2);
    ylen2=sqrt(x(4+8)^2+y(4+8)^2);
    
    x0_2=-(xlen1^2-xlen2^2-x1^2+x2^2)/(2*(x1-x2));
    y0_2=(ylen1^2-ylen2^2-y1^2+y2^2)/(2*(y1-y2));
    
    x0=(x0_1+y0_2)/2;
    y0=(x0_2+y0_1)/2;

%     fprintf('I crosstalk ratio is %2.3f \n',x0_1/rabi(1)./(d.scan.data.otherAmp/d.scan.data.amp));
%     fprintf('Q crosstalk ratio is %2.3f \n',y0_1/rabi(2)./(d.scan.data.otherAmp/d.scan.data.amp));
    
fprintf('I crosstalk ratio is %2.3f \n',x0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp));
fprintf('Q crosstalk ratio is %2.3f \n',y0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp));
    
    pmatrix=eye(4);
%     pmatrix(1,3)=x0_1/rabi(1)./(d.scan.data.otherAmp/d.scan.data.amp);
%     pmatrix(1,4)=-y0_1/rabi(2)./(d.scan.data.otherAmp/d.scan.data.amp);

    pmatrix(1,3)=x0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp);
    pmatrix(1,4)=-y0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp);
    pmatrix(2,3)=-pmatrix(1,4);
    pmatrix(2,4)=pmatrix(1,3);

end

%generate fake rabi vector to see if its right
phase=[0 pi/2 pi 3*pi/2]; phase1=[phase phase phase];
phase2=[0*ones(1,4) 0*ones(1,4) pi/2*ones(1,4)];
amp2=[0*ones(1,4) ones(1,8)];

rabiInput(1,:)=1.*cos(phase1);
rabiInput(2,:)=1.*sin(phase1);
rabiInput(3,:)=amp2.*cos(phase2);
rabiInput(4,:)=amp2.*sin(phase2);

for i=1:12
    rabiOutput(:,i)=pmatrix*rabiInput(:,i);
    rabiFreqOutput(i)=norm(rabiOutput(1:2,i)).*rabi(1);
end
rabi
rabiFreqOutput

%% 4-phase mixer cal, qubit B

fprintf('Load B mixer scan file \n');

d=ana_avg();
dataAvg=squeeze(nanmean(d.data{1}));
xvals=d.xv{1};
rabi=[];
figure(200); clf;
colors={'r' 'g' 'b' 'c' 'm' 'k'};

for i=1:size(dataAvg,1)
    yvals=dataAvg(i,:);
    sliceStart=1;
    
    %estimate the freq and phase
    fp = fioscill(xvals, yvals, 2);
    
    xvals=xvals(sliceStart:end);
    yvals=yvals(sliceStart:end);
    
    %estimate the decay time
    per=1/fp(4);
    dt=xvals(2)-xvals(1);
    perPoints=round(per/dt);
    firstPer=yvals(1:1+perPoints);
    lastPer=yvals(end-perPoints:end);
    decayTime=sqrt(xvals(end)/log(mean(abs(firstPer))/mean(abs(lastPer))));
    
    if ~isreal(decayTime)
        decayTime=50;
    end
    
    if decayTime<0
        decayTime=50;
    end
    
    if decayTime>500
        decayTime=50;
    end
    
    %do the fit
    fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3))+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
    beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) 0 decayTime*2 2 0];

%     if i==1
%         beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime*2 2 0];
%     else
%         beta(3)=fp(4)/(2*pi);
%     end
    mask=[1 1 1 1 1 0 0];
    [beta,~,~,~,~,err]=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    % mask=[1 1 1 1 1 0];
    % beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
    fit=fitfn(beta,xvals);
    
    figure(200);  hold on; plot(xvals,yvals+i*.5,[colors{mod(i,6)+1} '.']); plot(xvals,fit+i*.5,colors{mod(i,6)+1});
    
    rabi(i)=abs(beta(3))*1e3;
end
phase=[0 pi/2 pi 3*pi/2]; phase=[phase phase phase]
x=real(exp(1i.*phase).*rabi);
y=imag(exp(1i.*phase).*rabi);

ir=rabi(3)/rabi(1);
qr=rabi(4)/rabi(2);
iqr=rabi(1)/rabi(2);

fprintf('I ratio is %2.2f \n',rabi(3)/rabi(1));
fprintf('Q ratio is %2.2f \n',rabi(4)/rabi(2));
fprintf('IQ ratio is %2.2f \n',rabi(1)/rabi(2));
% fprintf('X sum is %2.2f \n',sum(x));
% fprintf('Y sum is %2.2f \n',sum(y));


% figure(223); clf; plot(x,y,'o');
% hold on; plot(mean(rabi).*cos(0:.01:2*pi)+sum(x),mean(rabi).*sin(0:.01:2*pi)+sum(y),'r')
% axis('equal');

% try to figure out the crosstalk. 
x1=rabi(1);
x2=-rabi(3);
xlen1=sqrt(x(1+4)^2+y(1+4)^2);
xlen2=sqrt(x(3+4)^2+y(3+4)^2);
y1=rabi(2);
y2=-rabi(4);
ylen1=sqrt(x(2+4)^2+y(2+4)^2);
ylen2=sqrt(x(4+4)^2+y(4+4)^2);
if d.scan.data.otherAmp~=0
    x0_1=(xlen1^2-xlen2^2-x1^2+x2^2)/(2*(x1-x2));
    y0_1=(ylen1^2-ylen2^2-y1^2+y2^2)/(2*(y1-y2));
    
    
    % try to figure out the crosstalk.
    x1=rabi(1);
    x2=-rabi(3);
    xlen1=sqrt(x(1+8)^2+y(1+8)^2);
    xlen2=sqrt(x(3+8)^2+y(3+8)^2);
    y1=rabi(2);
    y2=-rabi(4);
    ylen1=sqrt(x(2+8)^2+y(2+8)^2);
    ylen2=sqrt(x(4+8)^2+y(4+8)^2);
    
    x0_2=-(xlen1^2-xlen2^2-x1^2+x2^2)/(2*(x1-x2));
    y0_2=(ylen1^2-ylen2^2-y1^2+y2^2)/(2*(y1-y2));
    
        
    x0=(x0_1+y0_2)/2;
    y0=(x0_2+y0_1)/2;

    
    
%     fprintf('I crosstalk ratio is %2.3f \n',x0_1/rabi(1)./(d.scan.data.otherAmp/d.scan.data.amp));
%     fprintf('Q crosstalk ratio is %2.3f \n',y0_1/rabi(2)./(d.scan.data.otherAmp/d.scan.data.amp));
    
    fprintf('I crosstalk ratio is %2.3f \n',x0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp));
    fprintf('Q crosstalk ratio is %2.3f \n',y0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp));
%     pmatrix(3,1)=x0_1/rabi(1)./(d.scan.data.otherAmp/d.scan.data.amp);
%     pmatrix(3,2)=-y0_1/rabi(2)./(d.scan.data.otherAmp/d.scan.data.amp);
    pmatrix(3,1)=x0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp);
    pmatrix(3,2)=-y0/mean([rabi(1:4)])./(d.scan.data.otherAmp/d.scan.data.amp);

    pmatrix(4,2)=pmatrix(3,1);
    pmatrix(4,1)=-pmatrix(3,2);

end

%%
load 'pulseMatrix2015_12_14';
pinv1=pinv;
pinv=inv(pmatrix)*pinv1;

%% Save the pulse matrix 2015_12_14
save('pulseMatrix2015_12_14','pinv');

%% 
load pulseMatrix2016_03_14
pinv1=pinv;
pinv=inv(pmatrix)*pinv1;

%% Save the pulse matrix 2016_03_14
pinv=inv(pmatrix);
save('pulseMatrix2016_03_21','pinv');

%% Save the pulse matrix 2016_03_31
%pinv=inv(pmatrix);
pinv=2*eye(4)-pmatrix;
save('pulseMatrix2016_03_31','pinv');

%% Save the pulse matrix 2016_04_01
pinv=inv(pmatrix);
save('pulseMatrix2016_04_01','pinv');

%% 
load pulseMatrix2016_04_01
pinv1=pinv;
pinv=inv(pmatrix)*pinv1;
save('pulseMatrix2016_04_01','pinv');


 

%%
pulseMatrix=[1 0 .756 -.396;0 1 .306 .756; .081 .186 1 0; -.186 .081 0 1];

%% Single qubit tomo and fit to find decay.
ppt=1;
out=anaTomoXYZ('',struct('opts','nocal pauli'));
data=out.data{1};
r=(sum(data.^2,2)).^.5;

fitfn=@(p,x) p(1)+p(2).*exp(-(x./p(3)).^p(4));
beta=[0 1 30 2];
beta=fitwrap('plfit',(1:1:length(r)),r',beta,fitfn,[1 1 1 1]);
title(sprintf('T2=%2.2f',beta(3)));

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',out.name);
    set(ppt.e_figures,'String',['[500]']);
    set(ppt.e_title,'String',out.name);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end
%% scratch: T1
% What should T1 be given dBz, J, djde?

dBz=900;  
J=100; 
dJde=J/.25; 
dBz=dBz*1e6;
J=J*1e-6; 
dJde=dJde*1e6/1e-3;
freq=sqrt(dBz^2+J^2);
beta=0.7;
Se=2e-9*(1e6/freq)^beta;

T1=2/(Se^2*(2*pi)*dJde^2*dBz^2/freq^2)

%% Old stuff below
%% Plot a chevron, software FB.
fname=get_files('sm_*.mat');
d=load(fname{1});
scantime=getscantime(d.scan,d.data);
vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
dd=diff(vp,2);
ind=find(dd<0)+2;
xv=vp(ind:end);

d=ana_avg(fname{1},struct('xval',mat2cell((1:1:128)*24),'ops',''));
ppt=1;
fname=d.filename;

%process the image
data=(d.data{1});
nrep=size(d.data{1},1);
stop=16; %dont average all the data if the gradient fell away.
dataAvg=squeeze(nanmean(data(1:stop,:,:)));
yvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints)./1e6;
xvals=xv;
figure(1); clf; 
subplot(2,1,1); imagesc(xvals,yvals,dataAvg); set(gca,'YDir','norm');
xlabel('Burst time (ns)'); ylabel('Frequency (MHz)'); colorbar;

% plot and fit a slice
sliceVal=461;
[val ind]=min(abs(yvals-sliceVal));
yvals=dataAvg(ind,:);
sliceStart=1;

%estimate the freq and phase
fp = fioscill(xvals, yvals, 2);

xvals=xvals(sliceStart:end);
yvals=yvals(sliceStart:end);

%estimate the decay time
per=2*pi/fp(4);
dt=xvals(2)-xvals(1);
perPoints=round(per/dt);
firstPer=yvals(1:1+perPoints);
lastPer=yvals(end-perPoints:end);
decayTime=-xvals(end)/log(std(lastPer)/std(firstPer));

%do the fit
fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*(p(3)+p(8).*x)+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) decayTime 2 -.01/1000 0];
mask=[1 1 1 1 1 0 1 0];
beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
% mask=[1 1 1 1 1 0];
% beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
fit=fitfn(beta,xvals);
figure(1); subplot(2,1,2); hold on; plot(xvals,yvals,'b.-'); plot(xvals,fit,'k');
title(sprintf('Slice at %3.0f MHz, T2* = %4.0f ns, F = %2.3f MHz',sliceVal,abs(beta(5)),abs(beta(3))*1e3));
subplot(2,1,2); plot(xvals,dataAvg(ind,:));

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end
%% Analyze dBz file and plot the freq and contrast vs time: software FB
% WARNING: NEED TO PUT IN XVALS MANUALLY
ppt=1;
d=ana_avg('',struct('xval',mat2cell((1:1:128)*4),'opts','noppt no plot'))
close 1; close 2;
data=squeeze(d.data{1});
scantime=getscantime(d.scan,d.data);

fname=d.filename;
rows=3; cols=2;

figure(1); clf; 
ax(1)=subplot(rows,cols,1);
imagesc(data'); set(gca,'YDir','norm'); 
xlabel('repitition'); ylabel('time (ns)');

tt=linspace(1,size(data,2),size(data,2));
ff=[]; aa=[]; mm=[];
start=5;

for i=1:size(data,1)
    slice=(data(i,:));
    [freqs spec]=psd(tt,slice-mean(slice));
    [val  ind]=max(spec);
    ff(i)=freqs(ind);
    aa(i)=max(slice(start:end))-min(slice(start:end));
    mm(i)=mean(slice(start:end));
end

ax(2)=subplot(rows,cols,2);
plot(ff); xlabel('repitition'); ylabel('Frequency (GHz)'); 
title(sprintf('std = %3.0f MHz',std(ff)*1e3));

ax(3)=subplot(rows,cols,3);
plot(aa,'.-'); xlabel('repitition'); ylabel('Contrast (pk-pk)'); ylim([0 1]);

ax(4)=subplot(rows,cols,4);
plot(mm,'.-'); xlabel('repitition'); ylabel('Mean'); ylim([0,1]);

%fit the data.
stop=size(data,2);
vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
startInd=find(diff(vp)<0);
xvals=vp(startInd+1:end);
%xvals=linspace(1,size(data,2),size(data,2));
yvals=squeeze(nanmean(data));
fp = fioscill(xvals, yvals, 2);
yvals=yvals(start:stop);
xvals=xvals(start:stop);

fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*p(3)+p(4)).*exp(-(x./p(5)).^p(6))+p(7).*x;
beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) 30 2 -.1/100];
mask=[1 1 1 1 1 0 1];
beta=fitwrap('',xvals,yvals,beta,fitfn,mask);
mask=[1 1 1 1 1 1 1];
beta=fitwrap('',xvals,yvals,beta,fitfn,mask);
fit=fitfn(beta,xvals);
subplot(rows,cols,[5:6]); hold on;
plot(xvals,yvals,'b.-'); plot(xvals,fit,'k');
xlabel('Time'); ylabel('Mean'); 
title(sprintf('T2* = %4.0f ns, F = %4.0f MHz',abs(beta(5)),abs(beta(3))*1e3));




linkaxes(ax,'x');

if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end
%% old 1-2 readout scan
%look at 3140, for example.

curdir=pwd;
cd 'Z:\qDots\data\data_2012_08_17';

d = load(uigetfile('*Pulsed*'));
d1 = squeeze(nanmean(d.data{1}(:,:,1:end/2)));
d2 = squeeze(nanmean(d.data{1}(:,:,(1+end/2):end)));
data = d1-d2;
figure(1); clf;
imagesc(data);
set(gca,'YDir','normal')
cd(curdir);
%% Plot data set with both kinds of readout to be sure. 
d = load(uigetfile('sm*.mat'));
data=d.data{1};
figure(1); clf; 
subplot(2,1,1);
imagesc(squeeze(data(:,1,:))); h=colorbar; set(h,'YDir','reverse');
subplot(2,1,2);
imagesc(squeeze(data(:,2,:))); h=colorbar;  set(h,'YDir','reverse');
%% Analyze dbz and T2*
d=ana_avg('',struct('ops','noppt noplot nodbz'));
close 1; close 2;
data=squeeze(d.data{1});
fname=d.filename;

start=2;
stop=size(data,2);

scantime=getscantime(d.scan,d.data);

vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
xvals=vp;

yvals=squeeze(nanmean(data));

%estimate some parameters
fp = fioscill(xvals, yvals, 2);

yvals=yvals(start:stop);
xvals=xvals(start:stop);

fitfn=@(p,x) p(1)+p(2)*cos(2*pi*x.*p(3)+p(4)).*exp(-(x./p(5)).^p(6));
beta=[mean(yvals) (max(yvals)-min(yvals))/2 fp(4)/(2*pi) fp(3) 30 2];
mask=[1 1 1 1 1 1];
beta=fitwrap('plinit',xvals,yvals,beta,fitfn,mask);
% mask=[1 1 1 1 1 1];
% beta=fitwrap('plinit plfit',xvals,yvals,beta,fitfn,mask);
fit=fitfn(beta,xvals);
figure(1); clf; hold on; plot(xvals,yvals,'b.-'); plot(xvals,fit,'k');
title(sprintf('T2* = %4.0f ns, F = %.3d GHz',abs(beta(5)),abs(beta(3))));
%% Plot a set of T2s, software FB.
fname=get_files('sm_*.mat');
d=load(fname{1}); fname=fname{1};
scantime=getscantime(d.scan,d.data);
vp=plsinfo('xval',d.scan.data.pulsegroups(1).name,[],scantime);
dd=diff(vp,2);
ind=find(dd<0)+2;
xv=vp(ind:end);
nrep=d.scan.data.conf.nrep;
dt=repmat(xv,[nrep,1])
ts=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
[f pars sdata]=ana_echo(fname{1},struct('opts','ramsey epsrms nocenter nodbz rmoutlier','side','A','dt',xv,'ts',ts));

ppt=1;
d=sdata;
%process the image
data=sdata.data{1};
nrep=size(d.data{1},1);
stop=16; %dont average all the data if the gradient fell away.
dataAvg=squeeze(nanmean(data(1:stop,:,:)));
yvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints)./1e6;
xvals=xv;
figure(1); clf; 
subplot(2,1,1); imagesc(xvals,yvals,dataAvg); set(gca,'YDir','norm');
xlabel('Burst time (ns)'); ylabel('Frequency (MHz)'); colorbar;

subplot(2,1,2);
plot(ts,1./pars.params(:,6)); xlabel('RF power (dBm)'); ylabel('T_2^* (ns)');
ylim([0 1500]);


if ppt
    ppt=guidata(pptplot);
    set(ppt.e_file,'String',fname);
    set(ppt.e_figures,'String',['[1]']);
    set(ppt.e_title,'String',fname);
    set(ppt.e_body,'String','');
    set(ppt.exported,'Value',0);
end