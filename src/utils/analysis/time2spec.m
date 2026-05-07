function [ out ] = time2spec( file, plt, pltall, avg, pltavg, sen, sampRate, npoints, rate, figind, samefig, plttrendlines )
%time2spec Plots power spectra of a time series
%function [ out ] = time2spec( file, plt, pltall, avg, pltavg, sen, sampRate, npoints, rate )
%   file: input files
%   plt: boolean to toggle plotting
%   pltall: boolean option
%   pltavg: boolean option
%   sen: scaling factor
%   sampRate: not used?
%   npoints: not used?
%   rate: not used?
%   samefig: boolean option
%   plttrendlines: boolean option
%   '' to skip entry
%
% See also ezpsd

warning off;

if ~exist('file','var') || isempty(file)
    file=smgetfile;
end

if ~iscell(file)
    file = {file};
end

if ~exist('plt','var') || isempty(plt)
    plt=0;
end

if ~exist('avg','var') || isempty(avg)
    avg=0;
end

if ~exist('pltavg','var') || isempty(pltavg)
    pltavg=0;
end

if ~exist('sen','var') || isempty(sen)
    sen=1;
end

if ~exist('pltall','var') || isempty(pltall)
    pltall=0;
end

if ~exist('figind','var') || isempty(figind)
    figind = 823;
end

if ~exist('samefig','var') || isempty(figind)
    samefig = 0;
end

if ~exist('plttrendlines','var') || isempty(plttrendlines)
    plttrendlines = 0;
end

chk = 0;


for i=1:length(file)
    
    if i==1
        display('Beginning averaging...');
    else
        display(sprintf('Completed %d/%d files',i,length(file)));
    end
    
    d = load(file{i});
    dat = d.data{1}*(1/sen);
    s1 = size(d.data{1},1);
    for k=1:s1
        
        
        
        data = dat(k,:);
        
        
        if isfield(d.scan.data,'sampRate')
            sampRate = d.scan.data.sampRate;
        end
        
        if isfield(d.scan.data,'npoints')
            npoints = d.scan.data.npoints;
        end
        
        if isfield(d.scan.data,'rate')
            rate = d.scan.data.rate;%d.scan.data.rate;
        end
        
        data = data(1:npoints);
        L = length(data);
        
        %fourier transform
        sampT = 1/rate;
        %timeVec = (0:L-1)*sampT;
        freqVec = rate*(0:L/2)/L;
        [~,hz60ind] = min(abs(freqVec-60));
        %data=data-mean(data);
        Y = fft(data);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1); P1(2:end-1) = 2*P1(2:end-1);
        P1 = P1.^2;
        Hz60 = P1(hz60ind);
        if chk
            figure(5); hold on; loglog(freqVec,P1)
        end
        
        if plt
            figure(figind);
            if ~pltall || i==1
                clf;
            end
            if length(freqVec)>1e6
                loglog(freqVec(1:1e6),P1(1:1e6),'DisplayName',file{i});
            else
                loglog(freqVec,P1,'DisplayName',file{i});
            end
            hold on;
            xlabel('Frequency (Hz)');
            ylabel('|S(f)|');
            leg = legend('Location','best');
            set(leg, 'Interpreter','none');
        end
        
        out(i*k).f = freqVec;
        out(i*k).P = P1;
    end
end

%average ffts (assumes all have same sampRate/rate/npoints)
if avg
    
    Ptot = [out(1).P];
    for i=2:length(file)*s1
        Ptot = cat(3,Ptot,[out(i).P]);
    end
    Pavg = mean(Ptot,3);
    Hz60 = Pavg(hz60ind);
    
    if pltavg
        figure(figind+1);
        if ~samefig
            clf;
        else
            hold on;
        end
        if length(freqVec)>1e6
            loglog(freqVec(1:1e6),Pavg(1:1e6),'DisplayName','Data');
        else
            loglog(freqVec,Pavg);
        end
        hold on;
        xlabel('Frequency (Hz)');
        %ylabel('S_\epsilon (arb units)');
        ylabel('S (arb units)');
        title('Average Power Spectrum');
    end
    
    for i=1:length(file)*s1
        out(i).Pavg = Pavg;
    end
    
    
    fline=[];
    A=Pavg(min(find(freqVec>100)))*100;
    for i=1:min([1e6,length(freqVec)])
        fline(i) = A/freqVec(i);
    end
    
    if plttrendlines
        if length(freqVec)>1e6
            loglog(freqVec(1:1e6),fline(1:1e6),'k','DisplayName','1/f');
        else
            loglog(freqVec,fline,'k','DisplayName','1/f');
        end
    end
    legend show;
    
    
end

opts=struct();
opts.file=file{1};
opts.title='time2spec output';
opts.body = sprintf('n_avg (Bartletts)=%0.0f\n60 Hz peak=%d',s1,Hz60);
opts.figures = [];
if plt
    opts.figures=[opts.figures 823];
end
if pltavg
    opts.figures=[opts.figures 824];
end
pptprep(opts);






end

