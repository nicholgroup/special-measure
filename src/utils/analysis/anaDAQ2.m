function [ out ] = anaDAQ2( file, config )
%function [ out ] = anaDAQ( file, config )
%   Takes a scanDAQ scan and outputs histogramed data
%   config is struct with optional fields:
%       intT
%       nbins
%       plot
% NEEDS TO BE FIXED SO IT CAN TAKE FILES WITH DATA SIZE ([N,M] WHERE N>1)

if ~exist('file','var') || isempty(file)
    file=smgetfile;
end

%set defaults for config
if ~exist('config','var')
    config = struct;
end

if ~isfield(config,'intT')
    config.intT = 5; % integration time in us
end

if ~isfield(config,'nbins')
    config.nbins = 100;
end

if ~isfield(config,'plot')
    config.plot = 0;
end


intT = config.intT*1e-6; %analyze in microsec
nbins = config.nbins;
plt = config.plot;

display('loading file...');
d = load(file);
dat = d.data{1};
s1 = size(dat,1);
s2 = size(dat,2);
sampRate = d.scan.data.sampRate;
npoints = d.scan.data.npoints;
rate = d.scan.data.rate;

out = struct;

xmin = min(dat(:));
xmax = max(dat(:));
xvec = linspace(xmin,xmax,nbins);

for j=1:s1
    data = dat(j,:);
    
    %histogram each time series
    for i=1:length(intT)
        n = intT(i);
        pts = round(intT(i)*rate);
        m  = s2 - mod(s2, pts);
        y  = reshape(data(1:m), pts, []);     % Reshape x to a [n, m/n] matrix
        data_avg = transpose(sum(y, 1) / pts);  % Calculate the mean over the 1st dim
        %         if j==1
        %             xmin = min(data_avg);
        %             xmax = max(data_avg);
        %             xvec = linspace(xmin,xmax,nbins);
        %         end
        
        h(i,:)=hist(data_avg,xvec);
        
    end
    
    for i=1:length(intT)
        hnorm(i,:) = h(i,:)./max(h(i,:));
    end
    
    out(j).h = h;
    out(j).hnorm = hnorm;
    
    % extract fidelity
    f1 = [];
    f2 = [];
    vis =[];
    for i=1:length(intT)
        hline = hnorm(i,:);
        if plt
            figure(560); clf; scatter(xvec,hline);
            drawnow;
        end
        range = xmax-xmin;
        xmaxj = max(data);
        xminj = min(data);
        xvecj = linspace(xminj,xmaxj,nbins);
        c = xvecj(round(end/2));
        
        %fit to double gaussian
        fitfn=@(p,x) p(1).*exp(-((x-p(2)).^2)./(2*p(3).^2)) +  p(4).*exp(-((x-p(5)).^2)./(2*p(6).^2));
        p=[0.3 c-0.07*range 0.05*range 0.3 c+0.07*range 0.05*range];
        beta=fitwrap('plinit plfit',xvec,hline,p,fitfn);
        %display(j); pause(1);
        
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
    end
    
    out(j).f1 = f1;
    out(j).f2 = f2;
    out(j).f = (f1+f2)./2;
    out(j).vis = vis;
    thrsh = 0.7; %only find tunnel rate if smaller peak is within 70% of large peak
    if beta(1)>thrsh && beta(4)>thrsh
        out(j).multipeak=1;
    else
        out(j).multipeak=0;
    end
    
    
    
    %fourier transform
    sampT = 1/rate;%1/sampRate;
    timeVec = (0:length(data)-1)*sampT;
    freqVec = rate*(0:length(data)/2)/length(data);%sampRate*(0:length(data)/2)/length(data);
    freqData = fft(data);
    P2 = abs(freqData/length(data));
    P1 = P2(1:length(data)/2+1); P1(2:end-1) = 2*P1(2:end-1);
    P1log = log(P1);
    flog = log(freqVec);
    fitrngend = exp(10);
    endind = max(find(freqVec<fitrngend));
    
    
    %fit to A/(1+B^2f^2)
    fitfn=@(p,x) log(p(1)./(1+p(2).^2.*(exp(x)).^2));
    p=[P1(1) 1/exp(6)];
    beta=fitwrap('plinit plfit',flog(1:endind),P1log(1:endind),p,fitfn);
    %pause(1);
    
%     figure(1);clf; loglog(freqVec,P1);drawnow;
    
    out(j).fft = P1;
    out(j).tunnelrate = 1/beta(2);
    
    %     figure(558); clf;
    %     loglog(freqVec(3:100000),P1(3:100000), 'DisplayName', 'Channel A');
    %     xlabel('Freq (Hz)'); ylabel('|P(f)|');
    
    
    
    
    
end

if plt
    sz = size(out,2);
    hh = [];
    for i=1:sz
        hh(i,:) = out(i).h;
        hhnorm(i,:) = out(i).hnorm;
    end
    
    f571=figure(571);clf;
    imagesc(hhnorm);%imagesc(flipud(hhnorm));
    colorbar;
    ax = f571.CurrentAxes;
    szylab = size(ax.YTick,2);
    ylabel([d.scan.loops(1).setchan ' (V)']);
    yticklab = linspace(d.scan.loops(1).rng(1), d.scan.loops(1).rng(2), szylab);
    for i=1:szylab
        yticklabstr{i} = num2str(yticklab(i));
    end
    ax.YTickLabel = yticklabstr;
    szxlab = size(ax.XTick,2);
    xticklab = linspace(xvec(1), xvec(end), szxlab);
    for i=1:szxlab
        xticklabstr{i} = num2str(xticklab(i));
    end
    ax.XTickLabel = xticklabstr;
    xlabel('DAQ (arb units)');
    set(ax,'Ydir','normal');
    set(ax,'Xdir','normal');
    
    maskedrange = [min(find([out.multipeak]>=1)) max(find([out.multipeak]>=1))];
    tvals = abs([out.tunnelrate]*1e-3);
    f572 = figure(572); clf; hold on;
    scatter(linspace(maskedrange(1),maskedrange(2),maskedrange(2)-maskedrange(1)+1),tvals(maskedrange(1):maskedrange(2)));
    ax572 = f572.CurrentAxes;
    ylabel('Tunneling rate (kHz)');
    xlabel([d.scan.loops(1).setchan ' (V)']);
    szxlab = size(ax572.XTick,2);
    scanrange = linspace(d.scan.loops(1).rng(1), d.scan.loops(1).rng(2), d.scan.loops(1).npoints);
    xticklab = linspace(scanrange(maskedrange(1)), scanrange(maskedrange(2)), szxlab);
    for i=1:szxlab
        xticklabstr{i} = num2str(xticklab(i));
    end
    ax572.XTickLabel = xticklabstr;
    
    drawnow;
    
    %prepare for export
    opts=struct();
    opts.file='';
    opts.title=file;
    opts.figures=[571];
    pptprep(opts);
    
end




end
