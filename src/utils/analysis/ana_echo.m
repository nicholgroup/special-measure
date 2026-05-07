function [figs pars sdata ]=ana_echo(file,config)
%ana_echo analyzes qubit oscillation data
%
%[figs pars sdata ]=ana_echo(file,config)
% config is a config struct describing what to do.  File can be blank
%
% Note that the file name is cached in a persistent variable.
%
% Possible fields in config:
% ts: the total evolution times (or epsilon values, for a ramsey experiment) 
%   as a vector, ie. 0.05:0.05:2.  If ts
%   is nan(default), try to guess from group xvals.
% t1: Default ratio of t1 to tmeas
% dbz: a list of which channels have dbz data. defaults to any pulsegroup w/ dbz in the name.
% rng: points to fit. [1 10] means first 10 xvals.  [5 inf] means 5 onwared.
% grng: groups to fit.  [ .5 inf] means .5 onward.  uses group xvals
% frames: reps to fit in the scan. (5:20) means fit reps 5-20.
% channel: a list of channels to fit.
% nodbz: skip dbz fit
% offset: offset between lines in figure 100
% side: which set in tunedata to look at .
% djde: djde in MHz/mV for computing epsilon noise
% djdevj: slope of djde vs J for computing epsilon noise for any J
% acut: cutoff amplitude
% alpha: lever arm of dot in eV/V
% histscale: histogram scaling option. defaults to 'G' for group by group, also can take 'L' for line-by-line scaling. 
% histopts: anything that is an option for anaHistScale. Default is
% "noplot"
% dxlabel: 
% guessf: guess oscillation frequency. This is good for aliased
% oscillations. Default pulls this out from fft.
% betaguess: guess for the exponent of the noise spectrum, defaults to 1
% opts: general set of options that can have the following words
%   afitdecay: fit decay only if amplitude is bigger than 5
%   echocenter: plots center time of echo curve vs evo time
%   echonoise: computes high frequency noise based on echo decay using the
%       specified value of djde
%   echophase: plots phase of echo curve vs evo time
%   epsrms or epsRMS: calculate rms epsilon noise.
%   even: fits every other ramsey group starting with 2 
%   fitdecay: fits for the decay envelope 
%   frq: Plots freq vs epsilon
%   guessxval: tries to guess the xvals (times) from the group def.
%   nocenter: constrains the center of the decay to be at zero time 
%   nodbz: no dbz group included in the scan
%   nofitdbz: do not fit the dbz group
%   noref: does not subtract the dbz frequency from the measured
%       frequencies to better extract exchange frequencies.
%   noscale: no historgram 
%   odd: fits every other ramsey group starting with 1 
%   per: Plots period vs epsilon
%   piphase: hack to fit echo oscillations better with a pi shift relative
%       to dt=0
%   power: fits the decay exponent
%   ramsey: single evo ramsey; 
%   ramt2: plots the ramsey t2 time
%   samedt: use this if all groups have the same timing. This saves time in
%   loading the pulse log.
%
% possible values of opts not yet documented: 
% amp:
% plotenv:
% rmoutlierpdiff:
% nocolor:
% fitoffset (for frq decay)
%
%
% deprecated opts:
% ramq, phase
% eg: ana_echo('',struct('opts','ramsey afitdecay ramt2 nodbz','rng',[3 inf],'grng',[0 inf],'side','B'))
% this will analyze a ramsey experiment on side B, taking times from 3
% nanoseconds to infinity, analyzing all groups, with no dbz group.
% ana_echo('',struct('opts','ramsey nodbz guessxval noref','side','A'))
% this will analyze a ramsey experiment on side A, without subtracting a
% dBz frequency, and trying to guess the epsilon values from the pulse
% informatoin.


figs=[];
pars = [];
plotnum=1;
fitdescr='';
persistent lastname;
persistent sdata_cache;
persistent fileinfo;
persistent xvt_cache;
persistent p_cache;


if ~exist('file','var') || isempty(file)
    if ~isstr(lastname)
        lastname='';
    end
    file=uigetfile('sm*.mat','ana_echo',lastname);
end

if isempty(file)
    return;
end
cache=0;
if strcmp(lastname,file) && ~isempty(sdata_cache) && ~isempty(fileinfo)
    st=dir(file);
    if st.bytes == fileinfo.bytes && st.datenum == fileinfo.datenum
        cache=1;
    end
    fileinfo=st;
end
lastname=file;

if ~exist('config','var')
    config=struct();
end

% Load the data file
if cache
    if ~isopt(config,'quiet') % bug, config not defined yet.
        fprintf('Using cached copy of file %s\n',file);
    end
    sdata=sdata_cache;
else
    sdata=load(file);  % Load the scan, data.. This lets us auto-generate some options.
    fileinfo=dir(file);
    sdata_cache=sdata;
end
data=sdata.data;
scan=sdata.scan;

scantime=getscantime(scan,data);
pars.scantime = scantime;

%EJC: 2020/09/07
starttime = datetime(data{2}(1),'ConvertFrom','datenum');
firstnan = min(find(isnan(data{1})));
if ~isempty(firstnan)
    endtime = datetime(sdata.data{2}(firstnan-1),'ConvertFrom','datenum');
else
    endtime = datetime(sdata.data{2}(end),'ConvertFrom','datenum');
end
tottime = duration(endtime-starttime,'Format','s');


% Parse options
config = def(config,'opts','');   % Random boolean options
config = def(config,'rng',[]);    % Range of points to fit, ie [10 inf];
config = def(config,'grng',[]);   % Group range points to fit, ie [1.1 1.5];
config = def(config,'channel',1); % Range of channels to fit. fixme to be smarter
config = def(config,'t1',nan);   % Default ratio of t1 to tmeas.  fixme to be smarter.
config = def(config,'frames',[]); % Default frames to fit.
%config = def(config,'xlabel','T (\mus)'); % Default xlabel for inter-group series (put into
%the ramsey section below)
config = def(config,'dxlabel','T (ns)');  % Default xlabel for intra-group series
config = def(config,'fitopts','interp');  % Interpolate xbals for fits\
config = def(config,'fb',100);    % Base number of figures to output.
config = def(config,'spsize',[2 2]); % Number of subplots for 'minor' figures.
% cellfun(@(p) ~isempty(p),regexp({scan.data.pulsegroups.name},'[dD][bB][zZ]'))
config = def(config,'dbz', find(cellfun(@(p) ~isempty(p),regexp({scan.data.pulsegroups.name},'[dD][bB][zZ]')))); % Is there a dBz group?
config = def(config,'side',[]); % Side of dot examined.
config = def(config,'ts', nan); % Group xvals.
config = def(config,'acut',nan);  % Cutoff amplitude
config = def(config,'alpha',0.1); % lever arm in eV/V
config = def(config,'betaguess',1); % guess beta for erms noise calc
config = def(config,'histscale','G'); % scaling method for histograms ('G' = group, 'L'= line by line)
config = def(config,'histopts','noplot'); % scaling method for histograms ('G' = group, 'L'= line by line)
config = def(config,'guessf',[]); % guess oscillation frequency. Good to use for aliased signals.


if isopt(config,'ramsey') || isopt(config,'Ramsey')
    if isopt(config, 'singlegroup')
        config.opts = [config.opts 'fitdecay nocenter gauss'];
    else
        config.opts=[config.opts 'amp per frq gauss fitdecay nocenter ramq ramt2 epsRMS eps1Hz plotenv'];
    end
    config = def(config,'xlabel','eps (mV)');  % Default xlabel for intra-group series
else
    config = def(config,'xlabel','T (\mus)'); % Default xlabel for inter-group series
end

if isopt(config,'echo')
    config.opts=[config.opts 'freq amp per'];
end

if isempty(config.frames)
    config.frames=1:size(data{config.channel},1);
end
if isempty(config.side)
    switch scan.loops(1).getchan{1}
        case 'DAQ2'
            config.side='right';
        case 'DAQ1'
            config.side='left';
        otherwise
            error('Unable to determine side');
    end
end

if isnan(config.t1)
    [t1t config.t1] = att1(config.side,scantime,'before');
end

notdbz=setdiff(1:length(scan.data.pulsegroups),config.dbz);

%======================
% Find the dt's for individual scan lines.
ngrps=length(scan.data.pulsegroups);
if ngrps==1
    ngrps=scan.data.conf.nrep;
    notdbz=(1:ngrps);
end

%JMN 2020_12_13
if isopt(config,'samedt')
    loopNum=1;
else
    loopNum=ngrps;
end

for i=1:loopNum %ngrps%length(scan.data.pulsegroups)
    try
        xvt=plsinfo('xval', scan.data.pulsegroups(i).name, [],scantime); 
        dxvt=diff(xvt,[],2) ~= 0;
        [mc ind]=max(sum(dxvt,2));
        dt(i,:)=xvt(ind,:);
        if ismember(i,notdbz)
            xv(:,i)=xvt(:);
        end
    catch
        try
            warning('plsinfo is corrupt. params may be meaningless');
            dt(i,:) = 1:size(data{config.channel},3);
        end
    end
end
config = def(config, 'dt', dt); % dts
dt = config.dt; %hack to keep backward compatibility
if any(size(dt)==1)
    dt = repmat(dt,size(data{1},2),1);
end
if isnan(config.ts)
    % Guess the group xval from the params
    if isopt(config,'guessxval')
        pulseparams=[];
        for i = notdbz

            p=plsinfo('params', scan.data.pulsegroups(i).name, [],scantime);
            
            if isempty(p)
                fprintf('Warining; no parameters on group %s\n',scan.data.pulsegroups(i).name);
                fprintf('Probable logging error.  Throwing out data.\n');
                p=repmat(nan,size(pulseparams,2),1);
            end
            %JMN 2022_11_16
            %pulseparams(:,i)=p;
            pulseparams(i,:)=p; 

        end
        % Find the varpar that changes
        %JMN 2022_11_16
        %[r c]=find(diff(pulseparams(:,notdbz),[],2) ~= 0);
         [r c]=find(diff(pulseparams(notdbz,:),[],1) ~= 0);

        switch mode(c)
            case 2
                xlab = 'T $(\mu{}s)$';
            case 3
                xlab = '$\epsilon$ (mV)';
            otherwise
                xlab = '?';
        end
        if isnan(mode(c))
            ts=1:length(notdbz);
        else
            %JMN 2022_11_16
            %ts=pulseparams(mode(c),:)';
            ts=pulseparams(:,mode(c))';
        end
    else
        ts=[];
        [r c] = find(diff(xv,[],2) ~= 0);
        if ~isempty(r)
            ts = xv(mode(r),:)';
        else
            fprintf('No xval changes from group to group.  Try guessxval\n');
            ts = xv(1,:);
        end
    end
else
    ts=config.ts;
    if (length(ts) ~= ngrps) %length(scan.data.pulsegroups))
        error('The length of TS (%d) must be the same as the number of groups (%d)\n',length(ts),length(scan.data.pulsegroups));
    end
end

ts=ts(:);
if isopt(config,'even')
    notdbz=notdbz(2:2:end);
end
if isopt(config,'odd')
    notdbz=notdbz(1:2:end);
end
% Scale the data
if ~isopt(config,'noscale')
    %the next line is a hack. will break when ana_echo can do more than one
    %channel at once.
    t1=ones(config.channel,1).*config.t1;
    %data_all=anaHistScale(scan,data,config.t1);
    %data_all=anaHistScale(scan,data,t1); %commented out on 12/16/2020 to incorporate options for hist scaling
    data_all = anaHistScaleV4(scan,data,t1,config.histscale,'',config.histopts); %EJC 2020/12/16 added option to scale histograms line by line
    yl='P(T)';
    if isfield(config,'offset')
        offset=config.offset;
    else
        offset=1/3;
    end
else
    data_all=data;
    yl='V_{rf} (mV)';
    offset=4e-4;
end

if isopt(config, 'offsetoff')
    offset = 0;
end

%pars.pulseparams = pulseparams;
omega_dbz=2*pi/32; % Assume this if there is no dbz reference.

for i=1:length(config.channel)
    data=data_all{config.channel(i)};
    fb=config.fb+100*(i-1);
    
    %=================
    % Plot the main data
    o=0;
    if ~isopt(config,'noplot')
        figure(fb); figs=[figs gcf];
        clf;
    end
    colors='rgbcmk';
    color=@(x) colors(mod(x,end)+1);
    params=[];
    errs = [];
    badfit_mat = [];
    for j=1:length(notdbz) % Fit all the rest of the data.
        ind=notdbz(j);
        if isopt(config, 'singlegroup')
            rdata = squeeze(nanmean(data(config.frames,:)));
        else
            rdata=squeeze(nanmean(data(config.frames,ind,:),1))'+o;
        end
        o=o+offset;
        if ~isopt(config, 'noplot')
            if isopt(config,'lines')
                plot(dt(ind,:),rdata,[color(j) '.-']);
            else
                plot(dt(ind,:),rdata,[color(j) '.']);
            end
        end
        if ~isopt(config,'nofit')
            if isopt(config,'noplot')
                %[fp,ff,se,badfit]=fitosc(dt(ind,:),rdata,[config.opts],config.rng,[color(j) '-']);
                [fp,ff,se,badfit]=fitosc(dt(ind,:),rdata,[config.opts],config.rng,[color(j) '-'],config.guessf);
            else
                %[fp,ff,se,badfit]=fitosc(dt(ind,:),rdata,['plot' config.opts],config.rng,[color(j) '-']);
                [fp,ff,se,badfit]=fitosc(dt(ind,:),rdata,['plot' config.opts],config.rng,[color(j) '-'],config.guessf);
            end
            params(j,:) = fp;   %fit parameters of oscillations across each line (npls)
            if ~(min(dt(j,:))-(abs(dt(j,2)-dt(j,1))*100) < params(j,5)) | ~(params(j,5) < max(dt(j,:))+(abs(dt(j,2)-dt(j,1))*100)) %EJC: classify non-sensical echo centers as bad fits
                badfit = 1;
            end
            badfit_mat(j) = badfit;
            %JMN 2020_03_26 Is this used for anything? %EJC: yes
            try
                errs(j,:) = se;
            end
        end
        if ~isopt(config,'noplot')
            ylabel(yl);
            xlabel(config.dxlabel);
            hold on;
        end
    end
    if isopt(config,'nofit')
        return;
    end
    pars.params=params;
    pars.err = errs;
    pars.ts=ts;
    pars.dt=dt;
    if length(params) > 3
        if size(params,1) > 10
            js = params(3:end-3,4); %EJC 2020/09/23: remove outlier Js
            goodjs = find(mean(js)-3*std(js)<js & js<mean(js)+3*std(js));
            if length(goodjs)>(length(params)/2)
                goodjs = goodjs(1:round(length(params)/2));
            end
            jbar = nanmean(js(goodjs));
            %jbar=mean(params(3:end-3,4));
        else
            jbar=mean(params(:,4));
        end
    else
        jbar=nan;
    end
    title(sprintf('|J|=%g Mhz',1e3*jbar/(2*pi)));
    fitdescr = [ fitdescr sprintf('|J|=%g Mhz\n',1e3*jbar/(2*pi)) ];
    
    if ~isopt(config,'nodbz')
        for i=1:length(config.dbz)
            dbzdata=squeeze(nanmean(data(config.frames,config.dbz(i),:),1))';
            [plotnum figs] = nextfig(config,plotnum,fb,figs);
            plot(dt(1,:),dbzdata,'b.');
            xlabel('T (ns)');
            ylabel(yl);
            
            if ~isopt(config,'nofitdbz')
                [fp,ff,se,badfit]=fitosc(dt(1,:),dbzdata,['fitdecay nocenter plot ' config.fitopts],[]);
                hold on;
                str=sprintf('T_2^*=%.3g ns, V=%.3f, T=%.3f, phi=%f',1./fp(6),2*sqrt(fp(2)^2+fp(3)^2),2*pi/fp(4),atan2(fp(3),fp(2))-pi);
                title(str);
                pars.dbzt2=1./fp(6);
                fitdescr = [ fitdescr sprintf('dBz_%d: ',config.dbz(i)) str sprintf('\n') ];
                omega_dbz = fp(4);
                pars.omega_dbz=omega_dbz;
            else
                title('dBz reference');
            end
        end
    end
    
    
    ts=ts(notdbz);
    % Plot various handy things.
    % amplitude vs. xval
    if isopt(config,'amp')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        %ampfunc=@(x) 2*((abs(x(:,4)) > 0.01) .* (abs(x(:, 6)) < .2).*(sqrt(x(:, 2).^2 + x(:, 3).^2)));
        ampfunc=@(x) 2*(sqrt(x(:, 2).^2 + x(:, 3).^2));
        a=ampfunc(params);
        plot(ts,a,'b.');
        if ~isnan(config.acut)
            cut=config.acut*median(a(1:3));
            mask=(a > cut);
        else
            mask=~isnan(a);
        end
        if isopt(config, 'rmoutlier')
            %mask = mask & (abs(a) <1);
            mask = mask & (abs(a) <1) & ~badfit_mat';
            %2020/09/11 EJC: below might need some work... thresholds are arbitrary... should be scaled to dt
            %mask = mask & ~([~mask(1:2); (smooth(abs(diff(a,2)),3)>0.03)] & [~mask(1); (abs(diff(a))>0.03)]);
        end
        plot(ts(mask),ampfunc(params(mask,:)),'b.');
        pars.ampT = ts(mask);
        pars.ampA = ampfunc(params(mask,:));
        if isopt(config,'linfit')
            ind = find(ts' > config.grng(1) & ts' < config.grng(2) & mask'); %EJC: 2020/02/05 fixed
            fpp = fitwrap('plfit',ts(ind)', ampfunc(params(ind,:))', [-1 0], @(p,x) p(1)*x + p(2));
            str = [sprintf('Amp %g t + %g',fpp(1),fpp(2))];
            fp=[];
            fp(1) = fpp(2); fp(2) = (fpp(2)+fpp(1)*mean(ts(ind)))/fpp(1);
        elseif isopt(config,'logfit')
            ind = find(ts' > config.grng(1) & ts' < config.grng(2) & mask(:)');
            fpp = fitwrap('plfit',ts(ind)', log(ampfunc(params(ind,:)))', [-1 0], @(p,x) p(1)*x + p(2));
            str = [str sprintf('Amp exp^(%g t + %g)',fpp(1),fpp(2))];
            fp=[];
            fp(1) = fpp(2); fp(2) = 1/fpp(1);
        else
            [fp,junk,fstr,ferr]=fitdecay(ts(mask)',ampfunc(params(mask,:))',['plot' config.opts],config.grng);
            str=['Amp' fstr];
            str= [str sprintf('Amp=%.3g T_2^{echo}=%.3g Q=%.1f T=%.3g',fp(1),fp(2),fp(2)/(1e-3*2*pi/jbar),2*pi/mean(jbar))];
        end
        title(str);
        fitdescr = [ fitdescr 'Amp: ' str sprintf('\n') ];
        ylabel(yl);
        xlabel(config.xlabel);
        try
            pars.ferr = ferr;
        end
        pars.amp = fp(1);
        if ~isempty(config.grng)
            ind = find(ts > config.grng(1) & ts < config.grng(2));
        else
            ind=1:length(ts);
        end
        pars.maxamp=max(ampfunc(params(ind,:)));
        pars.T2 = fp(2);
        pars.Q = fp(2)/(1e-3*2*pi/jbar);
        pars.Jbar = jbar;
        pars.T= 2*pi/mean(jbar);
        pars.afp = fp;
    end
    
    % Plot various handy things.
    % amplitude vs. xval
    if isopt(config,'per')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        perfunc=@(params) 2*pi./params(:,4);
        plot(ts,perfunc(params),'b.');
        title('Period');
        ylabel('T (ns)');
        xlabel(config.xlabel);
    end
    
    if isopt(config,'frq')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        if ~isopt(config,'noref')
            %omega_dbz = 2*pi*4.5e-3; % Hack by YFY 11/17/2022
            freqfunc=@(params) sqrt( abs(params(:,4)./(2*pi)).^2-((omega_dbz/((2*pi)))^2)) .* sign(params(:,4) - omega_dbz);
        else
            freqfunc=@(params) params(:,4)./(2*pi);
        end
        plot(ts,1e3*freqfunc(params),'b.');
        %fp=fitdecay(ts',ampfunc(params)',['plot' opts]);
        %title(sprintf('Amp=%.3g T_2^{echo}=%.3g Q=%.1f T=%.3g',fp(1),fp(2),fp(2)/(1e-3*2*pi/jbar),2*pi/mean(jbar)));
        ylabel('J (MHz)');
        xlabel(config.xlabel);
        
        %JMN 2015_09_18
        %only fit the frequencies below the nyquist freq.
        %assume dt is the same for all
        %assume lowest frequency is last.
        %     fnyq=1/(2.*(dt(2,2)-dt(2,1)))*1e3;
        %     freqList=1e3*freqfunc(params);
        %     ind=find(diff(flipud(freqList))<0,1); %the first point that goes down.
        %     %[val ind]=max(freqList(freqList<fnyq));
        %     inds=(length(freqList)-ind+1:1:length(freqList));
        
        if isopt(config,'fitoffset')
            [decp decf] = fitdecay(ts',1e3*freqfunc(params)','plot fitoffset',config.grng);
            %[decp decf] = fitdecay(ts(inds)',freqList(inds)','plot fitoffset',config.grng);
            
        else
            [decp decf] = fitdecay(ts',1e3*freqfunc(params)','plot',config.grng);
            %[decp decf] = fitdecay(ts(inds)',freqList(inds)','plot',config.grng);
            
        end
        str=sprintf('decay const = %.2d', decp(2));
        title(str);
        fitdescr = [ fitdescr 'Freq: ' str sprintf('\n') ];
        % 2nd form is more useful for quickly guestimating J's.
        %fitdescr = [ fitdescr sprintf('J(eps) = %.3g * exp(-eps/%.3g) + %.3g Mhz',decp(1:3)) ];
        fitdescr = [ fitdescr sprintf('J(eps) = 100 * exp(-(eps-%.4g)/%.3g) + %.3g Mhz',log(decp(1)/100)*decp(2),decp(2),decp(3))] ;
        pars.freqfunc=@(eps) 100*exp(-(eps-log(decp(1)/100)*decp(2))/decp(2))+decp(3);
        pars.decp = decp;
        
        pars.freq = [ts';1e3*freqfunc(params)'];
    end
    if isopt(config,'ramt2')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        plot(ts,abs(1./params(:,6)));
        xlabel(config.xlabel);
        ylabel('T_2^*, ns');
    end
    
    if isopt(config,'epsRMS')|| isopt(config,'epsrms')
        bg = config.betaguess;
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        %dJdE is in MHz/mV
        djde = (1/decp(2))*(1e3*freqfunc(params)-decp(3)); %Offset does not contribute to slope
        plot((djde(ind)).^(-2/(bg+1)),abs(1./params(ind,6)),'.'); hold on; % T2* here is in ns
        noiseslope = (djde(ind).^(-2/(bg+1)))'/abs(1./(params(ind,6)))'; % this is matlab shorthand for least squares slope
        plot([0 djde(ind(end)).^(-2/(bg+1))],[0 djde(ind(end)).^(-2/(bg+1))]./noiseslope,'g');
        %       erms = noiseslope/(2*pi*sqrt(2)); % No mikey; see our paper pg. 4
        erms=sqrt(2)*noiseslope/(2*pi);
        pars.erms = erms; %EJC: 2020/09/07
        pars.djde = djde;
        % dJ/dE is in MHz/mV=GHz/V, t2* is in ns, so erms in in v.
        xlabel(sprintf('(dJ/deps)^{-2/(%g+1)} (mV/MHz)',bg));
        ylabel ('T2^* (ns)');
        title(sprintf('RMS Voltage noise =%g (\\muV)',erms*1e6));
        fitdescr = [ fitdescr sprintf('RMS Noise: %g uV\n',erms*1e6)];
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        plot(1e3*freqfunc(params),djde);
        xlabel('J');
        ylabel('dJ/d\epsilon (MHz/mV)');
        
        % EJC 2020/02/6
        if isopt(config,'eps1Hz') || isopt(config,'eps1hz')
            time = dt(1,:)'*1e-6; %time in sec
            %fmin = 1/(1*60);%1/max(time); %min frequency of noise contribution (1/total acquisition time)
            fmin = 1/(1*seconds(tottime));%EJC 2020/09/07 added tottime instead of just 60s estimate; %min frequency of noise contribution (1/total acquisition time)
            fmax = 1e9/(dt(1,end)-dt(1,end-1)); %max frequency of noise contribution (1/min evolution time)
            %A = ((erms*config.alpha)^2/(sqrt(2)*bg*abs(log(fmax/fmin)))*1e12); % sqrt(charge noise power at 1Hz), sqrt(A) where S \propto A/f.
            %EJC 2020/04/09: I think above gets the effective lever arm
            %wrong. Below is correct using alpha=(alpha_1^2+alpha_2^2)^(-1/2)
            A = ((erms*config.alpha)^2/(bg*abs(log(fmax/fmin)))*1e12); % sqrt(charge noise power at 1Hz), sqrt(A) where S \propto A/f.
            fitdescr = [ fitdescr sprintf('eps@1Hz: %g ueV^2/Hz',A)];
            pars.A = A;
        end
    end
    if isopt(config,'echocenter')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        plot(ts,params(:,5));
        xlabel(config.xlabel)
        ylabel('Echo center (ns)');
    end
    if isopt(config,'echophase')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        plot(ts,unwrap(atan2(params(:,3),params(:,2))));
        xlabel(config.xlabel)
        ylabel('Echo Phase (radians)');
    end
    if ~isopt(config,'nocolor')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        rdata=reshape(permute(data,[1 3 2]),size(data,1),size(data,2)*size(data,3));
        imagesc(rdata(config.frames,:));
    end
    if isopt(config,'mean')
        [plotnum figs] = nextfig(config,plotnum,fb,figs);
        rdata=nanmean(data(config.frames,:,:),1);
        imagesc(squeeze(rdata));
    end
    
    if (isopt(config,'echonoise') && isfield(config,'djde') && ~isempty(config.djde)) || (isopt(config,'echonoise') && isfield(config,'djdevj'))
        %this only works with power and exponential decay. not 'both'
        if ~isfield(config,'djdevj')
            djde = config.djde*1e9; %MHz/mV into Hz/V
        else
            djde = (1e3*pars.Jbar/(2*pi))*config.djdevj;
            djde=djde*1e9; %MHz/mV into Hz/V; JMN 2020_03_26
        end
        if isopt(config,'power')
            beta = fp(4)-1;
            gval=gamma(-1-beta)*sin(pi*beta/2);
        else
            beta = 0;
            gval=pi/2;  % Limit of gval above as beta->0
        end
        
        %JMN 2020_03_26 the analysis below expects T2 to eventually be in
        %s. The code assumed it was in us.
        if pars.T2>10
            T2conv=1e-9; %T2 is in ns
        else
            T2conv=1e-6; %T2 is in us
        end
        
        pars.Se = (2*pi/abs(2^-beta*(-2+2^beta)*(T2conv*pars.T2)^(1+beta)*(2*pi*djde)^2*gval));
        % In limit as beta->0, this is 1/(4*pi^2)
        pars.Se = pars.Se / ( (2*pi)^beta); % 1/f, not 1/omega
        pars.Seps = @(f) pars.Se/f^beta;
        
        %fitdescr = [ fitdescr sprintf('Noise@1Mhz: %g nV (beta=%g)\n',sqrt(pars.Seps(1e6))*1e9,beta)];
        
        %JMN: 4/9/2015
        %I think the above calculation is wrong, and should be
        %         pars.Sphi=(2*pi/abs(2^-beta*(-2+2^beta)*(1e-6*pars.T2)^(1+beta)*gval));
        %         pars.Seps2=@(f) pars.Sphi*(2*pi)^(-1-beta)*(djde)^(-2)/f^beta;
        
        %JMN: 3/26/2020
        %I think the above calculation should be reduced by a factor of 2.
        %I think the Cywinski paper assume a single-sided spectrum, in
        %which case we do not need to convert with the extra a factor of 2.
        %pars.Sphi=(pi/abs(2^-beta*(-2+2^beta)*(T2conv*pars.T2)^(1+beta)*gval));    
        %pars.Seps2=@(f) pars.Sphi.*(2.*pi).^(-1-beta).*(djde).^(-2)./f.^beta;

        %EJC: 11/9/2020
        % I think the above defition of Seps2 is correct, but Sphi does not
        % have the correct normalization. 
        pars.Sphi=(1/abs(2^-beta*(-2+2^beta)*(T2conv*pars.T2)^(1+beta)*gval));    
        pars.Seps2=@(f) pars.Sphi.*(2.*pi).^(-1-beta).*(djde).^(-2)./f.^beta;
        
        fitdescr = [ fitdescr sprintf('Noise@1Mhz: %g nV (%g nV)(beta=%g)\n',sqrt(pars.Seps(1e6))*1e9,sqrt(pars.Seps2(1e6))*1e9,beta)];
        
    end
    
end
%pars = params;
figs = unique(figs);
if isa(figs,'matlab.ui.Figure') %make compatible with matlab R2014b
    if strcmp(config.histscale,'G')
        figs = [figs.Number 401]; %2019/02/10  YPK hack to add histogram in ppt
    elseif strcmp(config.histscale,'L')
        figs = [figs.Number];
    end
end
if ~isopt(config,'noppt')
    prettyfile=regexprep(file,'(sm_)|(\.mat)','');
    indentdescr= regexprep(fitdescr,'^(.)','\t$1','lineanchors');
%     ppt=guidata(pptplot);
%     set(ppt.e_file,'String',file);
%     set(ppt.e_figures,'String',['[',sprintf('%d ',figs),']']);
%     set(ppt.e_title,'String',prettyfile);
%     set(ppt.e_body,'String',fitdescr);
%     clipboard('copy',sprintf('%s\n%s\n\n',['===' prettyfile],indentdescr));
%     set(ppt.exported,'Value',0);
%     
    opts=struct();
    opts.file=file;
    opts.body = fitdescr;
    opts.title=prettyfile;
    opts.figures=figs;
    pptprep(opts);
end

fprintf(sprintf('%s\n%s\n\n',['===' prettyfile],indentdescr));
return;

%   if ~isempty(strfind(opts,'phase'))
%       pl.col = name;
%       pl.x = 7;
%       pl.y='@(x)unwrap(atan2(x(:,2),x(:,3)))';
%       pl.params=ts';
%       f3=makefits(col, pl, ds(1), length(ds));
%       dvdisplay(col,f3,'flag9');
%       dvdisplay(col,f3,'title','String','Ramsey Phase');
%       dvdisplay(col,f3,'xlabel','String',xlab,'interpreter','latex');
%       dvdisplay(col,f3,'ylabel','String','Phase (rad)');
%       dsa=union(dsa,f3);
%   end
%
%   if ~isempty(strfind(opts,'pdiff'))
%       pl.col = name;
%       pl.x = '@(x) x(1:2:end,7)';
%       pl.y='@(x)unwrap(atan2(x(1:2:end,2),x(1:2:end,3))-atan2(x(2:2:end,2),x(2:2:end,3)))';
%       pl.params=ts';
%       f3=makefits(col, pl, ds(1), length(ds));
%       dvdisplay(col,f3,'flag9');
%       dvdisplay(col,f3,'title','String','Ramsey Phase Change');
%       dvdisplay(col,f3,'xlabel','String',xlab,'interpreter','latex');
%       dvdisplay(col,f3,'ylabel','String','Phase (rad)');
%       dsa=union(dsa,f3);
%
%       dvfit(col,f3,'plint plfit ause',[1 1], '@(p,x) p(1)*x+p(2)',[1 1 ]);
%       fp=dvfit(col,f3,'getp');
%       dvdisplay(col,f3,'flag9');  % Seems to mean 'title'; talk to Hendrik
%       dvdisplay(col,f3,'title',...
%         'String',sprintf('$d\\phi/dt = %.3f rad/\\mu{}sec$',fp(1)),...
%         'Interpreter','latex');
%
%
%       pl.col = name;
%       pl.x = '@(x) x(1:2:end,7)';
%       pl.y='@(x)unwrap(atan2(x(1:2:end,2),x(1:2:end,3))-atan2(x(2:2:end,2),x(2:2:end,3)))';
%       pl.params=ts';
%       f3=makefits(col, pl, ds(1), floor(length(ds)/4));
%       dvdisplay(col,f3,'flag9');
%       dvdisplay(col,f3,'title','String','Early Ramsey Phase Change');
%       dvdisplay(col,f3,'xlabel','String',xlab,'interpreter','latex');
%       dvdisplay(col,f3,'ylabel','String','Phase (rad)');
%       dsa=union(dsa,f3);
%
%       dvfit(col,f3,'plint plfit ause',[1 1], '@(p,x) p(1)*x+p(2)',[1 1 ]);
%       fp=dvfit(col,f3,'getp');
%       dvdisplay(col,f3,'flag9');  % Seems to mean 'title'; talk to Hendrik
%       dvdisplay(col,f3,'title',...
%         'String',sprintf('$d\\phi/dt = %.3f rad/\\mu{}sec$',fp(1)),...
%         'Interpreter','latex');
%
%   end
%
%
%
%
%   if ~isempty(strfind(opts,'ramt2'))
%       pl.col = name;
%       pl.x=7;
%       pl.y = '@(x) 1./x(:,6)';
%       pl.params=ts';
%       f3=makefits(col, pl, ds(1), length(ds));
%       dsa=union(dsa,f3);
%       dvdisplay(col,f3,'flag9');  % Seems to mean 'title'; talk to Hendrik
%       dvdisplay(col,f3,'title',...
%           'String',sprintf('Ramsey T_2^*',fp(1),fp(2)),...
%           'Interpreter','tex');
%       dvdisplay(col,f3,'ylabel','String','T_2^*','interpreter','latex');
%       dvdisplay(col,f3,'xlabel','String',xlab,'interpreter','latex');
%   end
%
% end
%    dvplot(col,dsa);
% return;
%
% % Make sure there are no scoping issues
% function fitdecay(col,f)
%   dvfit(col,f,'plint plfit ause',[1 1 0], '@(p,x) p(1)*exp(-x/p(2))+p(3)',[1 1 0]);
% return;
%

function [fp,ff,se,badfit]=fitosc(x,y,opts,rng,style,guessf)
% initialization function
badfit = 0;
fig=gcf;
fifn.fn = @fioscill;
fifn.args = {1,[]}; %JMN 2021_11_09: added second argument to account for changes in fioscill

cosfn = '@(y, x)y(1)+y(2)*cos(y(4)*x) + y(3) * sin(y(4)*x)';
cosfn2 = '@(y, x)y(1)+(y(2)*cos(y(4)*x) + y(3) * sin(y(4)*x)).*exp(-(x-y(5)).^2 * y(6).^2)'; %used most of time
cosfn3 = '@(y,x)y(1)+(y(2)*cos(y(4)*x) + y(3) * sin(y(4)*x)).*(y(5)*x)'; %linear decay
cosfn4 = '@(y, x)y(1)+y(2)*cos(y(4)*x) + y(3) * sin(y(4)*x)';
cosfn5 = '@(y, x)y(1)+y(2)*cos(y(4)*x+y(3)).*exp(-(x-y(5)).^2 * y(6).^2)';

decfn2 = '@(y,x) y(1)+(sqrt(y(2)^2+y(3)^2)).*exp(-(x-y(5)).^2 * y(6).^2)'; %EJC: 2020/02/07: gaussian decay envelope
decfn2n = '@(y,x) y(1)-(sqrt(y(2)^2+y(3)^2)).*exp(-(x-y(5)).^2 * y(6).^2)';

if exist('rng','var') && ~isempty(rng)
    pts=x>rng(1) & x <rng(2);
    x=x(pts);
    y=y(pts);
end

if isempty(strfind(opts,'fitdecay')) || (~isempty(strfind(opts,'afitdecay')) && std(y) < 2e-2)
    if ~isempty(strfind(opts,'piphase'))
        fifn.args={3 guessf}; % pi phase shift
    else
        fifn.args={2 guessf}; %No decay
    end
    [fp,~,~,~,~,err,se]=fitwrap('fine plfit',x,y,fifn, cosfn5, [1 0 1 1 0 0]); %initial guess doesn't fit y2, y5, or y6
    ig = [fp(1), fp(2)*cos(fp(3)), fp(2)*sin(fp(3)), fp(4:6)];
    if ~isempty(guessf)
        ig(4) = guessf*2*pi;
    end
    [fp,~,~,~,mserr,err,se]=fitwrap('fine plfit plinit',x,y,ig, cosfn2, [1 1 1 1 1 1]);
    %display(['error = ' num2str(nanmean(se))]);
    if nanmean(se)>1e3 %10 %EJC: empiracal threshold... may need work. Increasing this threshold to be very high works because added catch to consider any fit with nonsensical echo center to be bad
        badfit = 1;
    end
    ff=str2func(cosfn2);
    f2=str2func(decfn2); f2n=str2func(decfn2n);
elseif isempty(strfind(opts,'nocenter'))
    fifn.args={2 guessf}; % Decay and center
    fp=fitwrap('fine',x,y,fifn, cosfn5, [1 0 1 1 0 0]);
    ig = [fp(1), fp(2)*cos(fp(3)), fp(2)*sin(fp(3)), fp(4:6)];
    [fp,~,~,~,~,err,se]=fitwrap('fine',x,y,fifn,cosfn2, [1 1 1 1 0 0]);
    [fp,~,~,~,~,err,se]=fitwrap('fine',x,y,fp, cosfn2, [1 1 1 1 1 1]);
    ff=str2func(cosfn2);
else      % Decay but no center
    fifn.args={2 guessf};
    [fp,~,~,~,~,err,se]=fitwrap('fine',x,y,fifn, cosfn5, [1 0 1 1 0 0]);
    fp = [fp(1), fp(2)*cos(fp(3)), -fp(2)*sin(fp(3)), fp(4:6)];
    [fp,~,~,~,~,err,se]=fitwrap('fine',x,y,fp, cosfn2, [1 1 1 1 0 1]);
    ff=str2func(cosfn2);
    f2=str2func(decfn2); f2n=str2func(decfn2n);
end
if ~isempty(strfind(opts,'plot'))
    figure(fig);
    hold on;
    if ~isempty(strfind(opts,'interp'))
        x=linspace(x(1,1),x(1,end),512);
    end
    if exist('style','var') && ~isempty('style')
        plot(x,ff(fp,x),style);
        if ~isempty(strfind(opts,'plotenv'))
            plot(x,f2(fp,x),style,'LineWidth',1.5);
            plot(x,f2n(fp,x),style,'LineWidth',1.5);
        end
    else
        plot(x,ff(fp,x),'r-');
        if ~isempty(strfind(opts,'plotenv'))
            plot(x,f2(fp,x),'r-','LineWidth',1.5);
            plot(x,f2n(fp,x),'r-','LineWidth',1.5);
        end
    end
end
return;

function [fp,ff,fitstring,ferr]=fitdecay(x,y,opts,rng,style)
% initialization function
ferr = 0;
fig=gcf;

if isempty(strfind(opts,'fitoffset'))
    mask=[1 1 0];
else
    mask=[1 1 1];
end

if exist('rng','var') && ~isempty(rng)
    pts=x>rng(1) & x <rng(2);
    x=x(pts);
    y=y(pts);
end

if ~isempty(strfind(opts,'gauss'))
    ff=@(p,x) p(1)*exp(-(x/p(2)).^2)+p(3);
    init=[1 max(x)/3 min(y)];
    init(1)=range(y)/(ff(init,min(x)-init(3)));
    fmt='Decay: %.3f exp(-(t/%3f)^2)+%g\n';
    fperm=[1 2 3];
elseif ~isempty(strfind(opts,'both'))
    ff=@(p,x) p(1)*exp(-(x/p(2)).^2-x/p(4))+p(3);
    init=[1 max(x)/3 min(y) max(x)/10];
    init(1)=range(y)/(ff(init,min(x))-init(3));
    mask(4)=1;
    fperm=[1 2 3];
    fmt='Decay: %.3f exp(-t/%3f -(t/%3f)^2)+%g\n';
elseif ~isempty(strfind(opts,'power'))
    ff=@(p,x) p(1)*exp(-(x/p(2)).^p(4))+p(3);
    init=[1 max(x)/3 min(y) 1];
    mask(4)=1;
    init(1)=range(y)/(ff(init,min(x))-init(3));
    fperm=[1 2 4 3];
    fmt='Decay: %.3f exp(-(t/%3f)^{%f})+%g\n';
else
    ff=@(p,x) p(1)*exp(-x/p(2))+p(3);
    init=[1 max(x)/3 min(y)];
    init(1)=range(y)/(ff(init,min(x))-init(3));
    fmt='Decay: %.3f exp(-t/%3f)+%g\n';
    fperm=[1 2 3];
end

if isempty(strfind(opts,'fitoffset'))
    init(3)=0;
end

[fp,~,~,~,~,~,ferr] = fitwrap('plinit plfit',x,y,init,ff,mask);
fitstring=sprintf(fmt,fp(fperm));
if ~isempty(strfind(opts,'plot'))
    figure(fig);
    hold on;
    if ~isempty(strfind(opts,'interp'))
        x=linspace(x(1,1),x(1,end),512);
    end
    if exist('style','var') && ~isempty('style')
        plot(x,ff(fp,x),style,'LineWidth',2);
    else
        plot(x,ff(fp,x),'r-');
    end
end
return;

% Apply a default.
function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;

function b=isopt(config,name)
b=~isempty(strfind(config.opts,name));
return;

function [plotnum figs] = nextfig(config, plotnum, fb, figs)
figure(1+fb+floor((plotnum-1)/prod(config.spsize)));
if(mod(plotnum-1,prod(config.spsize)) == 0)
    clf;
end
subplot(config.spsize(1),config.spsize(2), mod(plotnum-1,prod(config.spsize))+1);
figs=unique([figs gcf]);
plotnum=plotnum+1;
return