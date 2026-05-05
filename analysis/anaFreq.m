function [ out ] = anaFreq( file, config )
%anafreq(file,config) plots fft of scan
%   file is file name (string)
%   config is struct with optional fields
%       scantype = 'ramsey','echo','Tramsey' (can add more scan types)
%       figInd = figure number
%       c = [cx cy] for calculating epsilon
%       f = [fx fy] define direction of eps
%       zp = # of zeros to append to data to zero pad fft (default is 2^12)

if ~exist('file','var') || isempty(file)
    file = uigetfile;
end

if ~exist('config','var') || isempty(config)
    config = struct;
end

%define default config options
config = def(config,'scantype','ramsey');
config = def(config,'figInd',50);
config = def(config,'c',[0.38 0.38]); % might need to do a better job of handling cx and cy... could be saved with scans
config = def(config,'f',[1 -1]);
config = def(config,'zp',2^12);

cx = config.c(1);
cy = config.c(2);
fx = config.f(1);
fy = config.f(2);

d = load(file);
scan=d.scan;
data=d.data;
scantime=getscantime(scan,data);

try
    p1=plsinfo('params', scan.data.pulsegroups(1).name, [],scantime);
    gd=plsinfo('xval', scan.data.pulsegroups(1).name, [],scantime);
    p2=plsinfo('params', scan.data.pulsegroups(end).name, [],scantime);
    xvals=gd(end,:);
catch %'catch' added on 8/22/2023 xxc
    p1 = scan.data.pulsegroups(1).params;
    gd = scan.data.pulsegroups(1).gd;
    p2 = scan.data.pulsegroups(end).params;
    xvals=gd.varpar(:,end);
end
ngroups=length(scan.data.pulsegroups);

out = struct;
out.file=file;
switch config.scantype
    case 'ramsey'
        %xvals=gd.varpar';
        try
            eps = d.scan.data.evoeps; 
            xvals = d.scan.data.evotime; %updated 2022/06/13
            
        catch
            if ngroups>1 % added on 04/04/2024 by YFY for 1D ramsey scan
                eps=linspace((p1(2)+p1(4).*cx)./fx ,(p2(2)+p2(4).*cx)./fx ,ngroups);
            elseif ngroups==1
                eps = p1(2);
            end
        end
        
        if size(d.data{1},1)>1
            dat = squeeze(nanmean(d.data{1}));
        else
            dat = squeeze(d.data{1});
        end
        dat = dat - mean(dat,2);
        if config.zp>0
            dat = cat(2,dat,zeros(size(dat,1),config.zp));
        end
        
        dt = xvals(2)-xvals(1);
        sampF = 1/dt;
        %freqs = 0:(sampF/length(dat)):sampF/2;
        freqs = (1:1:length(dat)/2).*(1/(length(dat)*dt)); %2021/7/22
        
        fdat = zeros(size(dat,1),length(freqs));
        fdat_temp = zeros(size(dat,1),length(dat));
        for i=1:size(dat,1)
            row = dat(i,:);
            fdat_temp(i,:) = abs(fft(row));
            fdat(i,:) = fdat_temp(i,2:length(freqs)+1);
        end
        
        figure(config.figInd); clf; imagesc(freqs.*1e3,eps,fdat);
        set(gca,'YDir','Normal');
        ylabel('\epsilon (mV)');
        xlabel('Frequency (MHz)');
        
        maxF = zeros(1,size(dat,1));
        for i=1:size(dat,1)
            [~,indf] = max(fdat(i,:));
            maxF(i) = freqs(indf).*1e3;
        end
        
        out.dat = dat;
        out.pltfreqs = freqs;
        out.fft = fdat;
        try
            out.Tvals = p1(4); %out.tval = p1(4); %modified 12/13/2021 to be consistent with Tramsey, xxc
        end
        out.eps = eps;
        out.oscfreqs = maxF;
        out.oscT = 1./maxF;
        
    case 'Tramsey'
        %xvals = gd.varpar';
        try % added 10/10/2021 xxc
            Tvals = d.scan.data.evot;
            eps = d.scan.data.evoeps;
            xvals = d.scan.data.evotime;
        catch
            Tvals = linspace(p1(4),p2(4),ngroups);
            eps = (p1(2)+p1(4).*cx);
        end
        
        dat = squeeze(nanmean(d.data{1}));
        dat = dat - mean(dat,2);
        if config.zp>0
            dat = cat(2,dat,zeros(size(dat,1),config.zp));
        end
        
        dt = xvals(2)-xvals(1);
        sampF = 1/dt;
        freqs = 0:(sampF/length(dat)):sampF/2;
        
        fdat = zeros(size(dat,1),length(freqs));
        fdat_temp = zeros(size(dat,1),length(dat));
        for i=1:size(dat,1)
            row = dat(i,:);
            fdat_temp(i,:) = abs(fft(row));
            fdat(i,:) = fdat_temp(i,2:length(freqs)+1);
        end
        
        figure(config.figInd); clf; imagesc(freqs.*1e3,Tvals,fdat);
        set(gca,'YDir','Normal');
        ylabel('T (mV)');
        xlabel('Frequency (MHz)');
        
        maxF = zeros(1,size(dat,1));
        for i=1:size(dat,1)
            [~,indf] = max(fdat(i,:));
            maxF(i) = freqs(indf).*1e3;
        end
        
        out.dat = dat;
        out.pltfreqs = freqs;
        out.fft = fdat;
        out.Tvals = Tvals;
        out.eps = eps;
        out.oscfreqs = maxF;
        out.oscT = 1./maxF;
        
        
    case 'echo'
        evoEps = ((p1(2)+p1(4).*cx)./fx + (p2(2)+p2(4).*cx)./fx)/2;
        %xvals=gd.varpar';
        evoT=2*linspace(p1(5) ,p2(5)  ,ngroups);
        
        dat = squeeze(nanmean(d.data{1}));
        dat = dat - mean(dat,2);
        if config.zp>0
            dat = cat(2,dat,zeros(size(dat,1),config.zp));
        end
        
        dt = xvals(2)-xvals(1);
        sampF = 1/dt;
        %freqs = 0:(sampF/length(freqs)):sampF/2; %EJC 2021/03/10 commented out and added line below
        freqs = 0:(sampF/length(dat)):sampF/2;
        
        fdat = zeros(size(dat,1),length(freqs));
        %fdat_temp = zeros(size(dat,1),length(freqs)); %EJC 2021/03/10 commented out and added line below
        fdat_temp = zeros(size(dat,1),length(dat));
        for i=1:size(dat,1)
            row = dat(i,:);
            fdat_temp(i,:) = abs(fft(row));
            fdat(i,:) = fdat_temp(i,2:length(freqs)+1);
        end
        
        figure(config.figInd); clf; imagesc(freqs.*1e3,evoT,fdat);
        set(gca,'YDir','Normal');
        ylabel('Evolution time t (ns)');
        xlabel('Frequency (MHz)');
        title(['\epsilon = ' num2str(evoEps) ' mV']);
        
        maxF = zeros(1,size(dat,1));
        for i=1:size(dat,1)
            [~,indf] = max(fdat(i,:));
            maxF(i) = freqs(indf).*1e3;
        end
        
        out.dat = dat;
        out.pltfreqs = freqs;
        out.fft = fdat';
        out.evoT = evoT;
        out.oscfreqs = maxF;
        out.oscT = 1./maxF;
        
    case 'generic'
        param = config.sweepParam;
        
        if length(size(d.data{1}))>2
            if size(d.data{1},1)>1
                dat = squeeze(nanmean(d.data{1}));
            else
                dat = squeeze(d.data{1});
            end
        else
            dat = d.data{1};
        end
        dat = dat - mean(dat,2);
        if config.zp>0
            dat = cat(2,dat,zeros(size(dat,1),config.zp));
        end
        
        dt = xvals(2)-xvals(1);
        sampF = 1/dt;
        %freqs = 0:(sampF/length(dat)):sampF/2;
        freqs = (1:1:length(dat)/2).*(1/(length(dat)*dt)); %2021/7/22
        
        fdat = zeros(size(dat,1),length(freqs));
        fdat_temp = zeros(size(dat,1),length(dat));
        for i=1:size(dat,1)
            row = dat(i,:);
            fdat_temp(i,:) = abs(fft(row));
            fdat(i,:) = fdat_temp(i,2:length(freqs)+1);
        end
        
        figure(config.figInd); clf; imagesc(freqs.*1e3,param,fdat);
        set(gca,'YDir','Normal');
        ylabel('parameter (a.u.)');
        xlabel('Frequency (MHz)');
        
        maxF = zeros(1,size(dat,1));
        for i=1:size(dat,1)
            [~,indf] = max(fdat(i,:));
            maxF(i) = freqs(indf).*1e3;
        end
        
        out.dat = dat;
        out.pltfreqs = freqs;
        out.fft = fdat;
        try
            out.tval = p1(4);
        end
        out.param = param;
        out.oscfreqs = maxF;
        out.oscT = 1./maxF;
        
end


opts=struct();
opts.file=file;
opts.title=['anaFreq Data ' file];
opts.figures=config.figInd;
opts.body='';
pptprep(opts);

return

function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;