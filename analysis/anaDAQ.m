function [ out,out2 ] = anaDAQ( file, config )
%function [ out ] = anaDAQ( file, config )
%   Takes a scanDAQ scan and outputs histogramed data
%   config is struct with optional fields:
%       intT (us) - default starts at min intT based on rate
%       nbins
%       plot 
%       histplot 
%       histt (time for histogram slice in s)
%       sp subplot for histogram sp=[m,n,x,fig#] where m, n, x, are passed
%           to subplot(m,n,x)
% NEEDS TO BE FIXED SO IT CAN TAKE FILES WITH DATA SIZE ([N,M] WHERE N>1)
%
%
%
%

%warning off;

if ~exist('file','var') || isempty(file)
    file=smgetfile;
end

%set defaults for config
if ~exist('config','var')
    config = struct;
end

if ~isfield(config,'nbins')
    config.nbins = 100;
end

if ~isfield(config,'plot')
    config.plot = 0;
end

if ~isfield(config,'histplot')
    config.histplot = 0;
end

if ~isfield(config,'histt')
    config.histt = 2e-6;
end

if ~isfield(config,'sp')
    config.sp = [];
end

out2 = struct;



nbins = config.nbins;
plt = config.plot;
histplt = config.histplot;

display('loading file...');
d = load(file);
data = d.data{1};
s1 = size(data,1);
s2 = size(data,2);
sampRate = d.scan.data.sampRate;
npoints = d.scan.data.npoints;
rate = d.scan.data.rate;

if ~isfield(config,'intT')
    config.intT = 1/rate:1/rate:10/rate; % integration time in us
end
intT = config.intT*1e-6; %analyze in microsec

display('analyzing...');
if (intT(2)-intT(1)) < 1/rate
    if intT(1) < 1/rate
        intT = 1/rate:1/rate:10/rate;
        display(['intT step too small... changed intT steps to ' num2str(1/rate)]);
        display(['initial intT too small... changed intT range to ' num2str(1/rate) '-' num2str(10/rate)]);
    else
        intT = intT(1):1/rate:intT(end);
        display(['intT step too small... changed intT steps to ' num2str(1/rate)]);
    end
end


for i=1:length(intT)
    n = intT(i);
    pts = round(intT(i)*rate);
    m  = s2 - mod(s2, pts);
    y  = reshape(data(1:m), pts, []);     % Reshape x to a [n, m/n] matrix
    data_avg = transpose(sum(y, 1) / pts);  % Calculate the mean over the 1st dim
    if i==1
        xmin = min(data_avg);
        xmax = max(data_avg);
        xvec = linspace(xmin,xmax,nbins);
    end
    out2(i).datInt = data_avg;
    out2(i).intT = intT(i);
    
    h(i,:)=hist(data_avg,xvec);
    
end

for i=1:length(intT)
    hnorm(i,:) = h(i,:)./max(h(i,:));
end

out = struct;
out.h = h;
out.hnorm = hnorm;
out.x = xvec;




% extract fidelity
f1 = [];
f2 = [];
vis = [];
snr = [];
for i=1:length(intT)
    hline = hnorm(i,:);
    figure(560); clf; scatter(xvec,hline);
    range = xmax-xmin;
    c = xvec(round(end/2));
    
    %fit to double gaussian
    fitfn=@(p,x) p(1).*exp(-((x-p(2)).^2)./(2*p(3).^2)) +  p(4).*exp(-((x-p(5)).^2)./(2*p(6).^2));
    %p=[0.75 c-0.05*range 0.2*range 0.75 c+0.05*range 0.2*range];
    %p=[0.75 c-0.1*range 0.15*range 0.75 c+0.1*range 0.15*range];
    if i==1 %EJC commented out above line and added this 8/15/2022
        p=[0.75 c-0.1*range 0.15*range 0.75 c+0.1*range 0.15*range];
    else
        p = beta;
    end
    beta=fitwrap('plinit plfit',xvec,hline,p,fitfn);
    
    peak1 = fitfn([beta(1) beta(2) beta(3) 0 0 0],xvec);
    peak2 = fitfn([0 0 0 beta(4) beta(5) beta(6)],xvec);
    
    i1 = cumsum(peak1);
    i2 = cumsum(peak2,'reverse');
    itot = (i1+i2)/2;
    [m ind] = max(itot);
    
    c1 = beta(2); %center location of peak 1
    c2 = beta(5); %center location of peak 2
    sig1 = beta(3); %std of peak 1
    sig2 = beta(6); %std of peak 2
    
    divline = xvec(ind);
    line([divline divline],[0 1]);
    
    f1(i) = sum(peak1(1:ind))/i1(end);
    f2(i) = sum(peak2(ind:end))/i2(1);
    vis(i) = (f1(i)+f2(i))-1;
    
    snr(i) = abs((beta(2)-beta(5)))/((beta(3)+beta(6))/2);
end


out.f1 = f1;
out.f2 = f2;
out.f = (f1+f2)./2;
out.vis = vis;
out.snr = snr;



if histplt
    time = config.histt; 
    ind2us = find(intT==time);
    
    
    hline = hnorm(ind2us,:);
    %figure(562); clf; scatter(xvec,hline);
    range = xmax-xmin;
    c = xvec(round(end/2));
    
    %fit to double gaussian
    fitfn=@(p,x) p(1).*exp(-((x-p(2)).^2)./(2*p(3).^2)) +  p(4).*exp(-((x-p(5)).^2)./(2*p(6).^2));
    %p=[0.75 c-0.05*range 0.2*range 0.75 c+0.05*range 0.2*range];
    p=[0.75 c-0.1*range 0.15*range 0.75 c+0.1*range 0.15*range];
    beta=fitwrap('plinit plfit',xvec,hline,p,fitfn);
    
    peak1 = fitfn([beta(1) beta(2) beta(3) 0 0 0],xvec);
    peak2 = fitfn([0 0 0 beta(4) beta(5) beta(6)],xvec);
    
    i1 = cumsum(peak1);
    i2 = cumsum(peak2,'reverse');
    itot = (i1+i2)/2;
    [m ind] = max(itot);
    
    c1 = beta(2); %center location of peak 1
    c2 = beta(5); %center location of peak 2
    sig1 = beta(3); %std of peak 1
    sig2 = beta(6); %std of peak 2
    
    divline = xvec(ind);
    
    f1t = sum(peak1(1:ind))/i1(end);
    f2t = sum(peak2(ind:end))/i2(1);
    vist = (f1t+f2t)-1;
    ft = (f1t+f2t)/2;
    
    f560=figure(560); clf;
    
    if ~isempty(config.sp)
        sp = config.sp;
        f560 = figure(sp(4));
        subplot(sp(1),sp(2),sp(3));
    end
    hold on;
    
    
    fill(xvec,peak1,'c'); %'b'
    fill(xvec,peak2,'m'); %'r'
    alpha(0.25);
    
    ax560=f560.CurrentAxes;
    xlim = ax560.XLim;
  
    
    bar(xvec,hline,1,'FaceColor','none','EdgeColor','k','LineWidth',0.5);
    line([divline divline],[0 1.05],'Color',[0.5 0.5 0.5],'LineWidth',2,'LineStyle','--');
    
    c = divline;
    w = max([sig1 sig2])*11;
    ax560=f560.CurrentAxes;
    ax560.XLim=[c-w c+w];
    ax560.YLim=[0 1.05];
    %ax560.XTick=[];
    ax560.YLabel.String='Count (Normalized)';
    ax560.XLabel.String='DAQ (V)';
    fid = ft*100;
    titlestr = sprintf('%d \\mus Integration Time / %.5f%% Fidelity',time*1e6,fid);
    if isempty(config.sp)
        ax560.Title.String=titlestr;
    end
    %niceFigure(1);
    out.divline = divline;
    
end


    
    
    
    
    
    
    
    display('plotting...');
    if plt
        %plot histograms
        f559 = figure(559); clf;
        imagesc(hnorm);
        ax559 = f559.CurrentAxes;
        nyticks = length(ax559.YTick);
        ylabels = {};
        for i=1:length(ax559.YTick)
            ylabels{i} = num2str(intT(ax559.YTick(i))*1e6);
        end
        %         ylabels={};
        %         if length(intT)<=10
        %             for i=1:length(intT)
        %                 f559.CurrentAxes.YTick = linspace(1,length(intT),length(intT));
        %                 ylabels{i} = num2str(intT(i)*1e6);
        %             end
        %         else
        %             ylabelspan = linspace(min(intT),max(intT),10);
        %             for i=1:10
        %                 f559.CurrentAxes.YTick = ylabelspan;
        %                 ylabels{i} = num2str(ylabelspan(i));
        %             end
        %         end
        %
        %
        %        f559.CurrentAxes.YTickLabel = ylabels;
        ax559.YTickLabel = ylabels;
        ylabel('Integration Time (\mus)');
        xlabel('DAQ (arb units)');
        colorbar;
        set(ax559,'YDir','normal');
        
        %plot fidelities
        f561 = figure(561); clf; hold on;
        scatter(intT*1e6,(f1+f2)./2,'b*');
        %     scatter(intT*1e6,f1,'b*','DisplayName','Fidelity L');
        %     scatter(intT*1e6,f2,'r*','DisplayName','Fidelity R');
        %     scatter(intT*1e6,vis,'go','DisplayName','Visibility');
        %     legend('Location','southeast');
        xlabel('Integration Time (\mus)');
        ylabel('Fidelity/Visibility');
        

        
        f562 = figure(562); clf;
        semilogy(intT*1e6,snr,'rd','MarkerFaceColor','r');
        xlabel('Integration Time (\mus)');
        ylabel('SNR');
        
        %prepare for export
        opts=struct();
        opts.file='';
        opts.title=file;
        opts.figures=[559 561 562];
        %pptprep(opts); %EJC commented out 8/15/2022
    end
    
    display('done');
    
    
    warning on;
    
end
    
    
    
