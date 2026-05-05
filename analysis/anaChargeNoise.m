function [ out ] = anaChargeNoise(input,file,config,bkgd_substract)
% anaChargeNoise analyzes charge noise data taken using chargeNoiseScans
%
% [ out ] = anaChargeNoise(input,file,config,bkgd_substract).
%
% input can be 'single', 'temp', 'vsd', 'accum', 'num_e', 'mag','time'.
% multiple inputs not yet supported.
%
% config is a struct. If one wants to pass a different lever arm
% (alpha_star) to analyze the data config should have field
% config.alpha_star = alpha_star
%
% final option is bkgd_subtract. by default it does not subtract background
% spectrum. takes options 'y' and 'n'
%
% output figures: 222 (charge noise), 223 (current noise), 234 (temp), 235
% (vsd), 236 (tunnel), 237 (num_e), 238 and 239 (accum), 294-301 (magx,
% magy, magz, mag)
%
% function looks for 'Vsd', 'MCsetpt', 'Fmax', 'Fmin', gatesID (as defined
% in chargeNoiseScan script). these must be available in configch

try
    set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex');
end

if ~exist('input','var')
    error('Empty output type. Please specify and retry.')
end

if ~exist('file','var')
    file=smgetfile('sm*spectrum*.mat');
end

if ~exist('bkgd_subtract','var')
    bkgd_subtract = 'n';
end

if ~iscell(file)
    file={file};
end

if ~iscell(input)
    input={input};
end

if exist('config','var')
    if isfield(config,'alpha_star')
        alpha_star = config.alpha_star;
    end
end

figure(222); clf;
figure(223); clf;
ctab={'r' 'g' 'b' 'c' 'm' 'y' 'k'};
ctab=[ctab ctab ctab ctab];
styletab=[repmat({'-'},[1,7]),repmat({'.-'},[1,7]),repmat({'o-'},[1,7]), repmat({'*-'},[1,7])];

out=struct;

figure(222); clf; hold on;
figure(223); clf; hold on;

warning off;
% QHF 2018/01/19: extracts gatesID from loaded files (see chargeNoiseScans)
for i=1:length(file)
    display([num2str(i), ' out of ' num2str(length(file))]);
    d=load(file{i});
    s=d.scan;
    cch=d.configch;
    cv=d.configvals;
    data=d.data{1};
    current=d.data{2};
    dIdV=s.data.dIdV;
    
    try
        timestr = d.scan.data.startTime;
        timestamp = datetime(timestr,'InputFormat','dd-MMM-yyyy HH:mm:ss');
    end
    %QHF: data taken prior to 2018/01/19 does not have gatesID field
    if isfield(d.scan.data,'gatesID') % xxc: updated at 11/5/2020, the old version is "isfield('gatesID',d.scan.data)"
        gatesID=d.scan.data.gatesID; %{P,T1,T2,A}
    else
        gatesID={'dP1','dT1','dT2','A'};
    end
    
    %JMN 2018/02/13 hard coded configchans=bad!! Changing to be smarter about
    %this.
    try
        imin=find(ismember(d.configch,'Fmin'),1);
        imax=find(ismember(d.configch,'Fmax'),1);
        freqs=linspace(d.configvals(imin),d.configvals(imax),400);
    catch
        try
            %old code here
            freqs=linspace(d.configvals(23),d.configvals(24),400);
        catch
            freqs=linspace(0,d.configvals(21),400);
        end
    end
    
    %freqs=linspace(0,6.1035,400);
    
    out(i).freqs=freqs;
    out(i).fileName=file{i};
    
    ind=regexp(fliplr(file{i}),'_');
    fnameFlip=fliplr(file{i});
    out(i).fnum=str2num(fliplr(fnameFlip(5:ind-1)));
    
    
    %Find current noise first
    for j=1:size(data,1)
        switch d.scan.data.pointID{j}
            case 'base'
                SI_B=data(j,:).^2/s.data.gain^2;
                out(i).SI_B=SI_B;
                
            case 'peak'
                SI_P=data(j,:).^2/s.data.gain^2;
                out(i).SI_P=SI_P;
                
            case 'left'
                SI_L=data(j,:).^2/s.data.gain^2;
                out(i).SI_L=SI_L;
                
            case 'right'
                SI_R=data(j,:).^2/s.data.gain^2;
                out(i).SI_R=SI_R;
                
        end
    end
    
    if strcmp(bkgd_subtract,'y')
        SI_Lbase = SI_L-SI_B;
        SI_Rbase = SI_R-SI_B;
        SI_Pbase = SI_P-SI_B;
    end
    
    alpha = s.data.alpha;
    if exist('config','var')
        if isfield(config,'alpha_star')
            alpha = alpha_star;
            out(i).alpha_star = alpha_star;
        end
    end
    
    %Subtract baseline and compute voltage noise
    for j=1:size(data,1)
        switch d.scan.data.pointID{j}
            
            case 'left'
                if strcmp(bkgd_subtract,'y')
                    Su_L=(SI_L-SI_B).*alpha^2./dIdV(j).^2;
                else
                    Su_L=(SI_L).*alpha^2./dIdV(j).^2;
                end
                out(i).Su_L=Su_L;
                
            case 'right'
                if strcmp(bkgd_subtract,'y')
                    Su_R=(SI_R-SI_B).*alpha^2./dIdV(j).^2;
                else
                    Su_R=(SI_R).*alpha^2./dIdV(j).^2;
                end
                out(i).Su_R=Su_R;
                
        end
    end
    
    
    % QHF 2018/01/19: omitted hard coded configvals index. now it looks for
    % names in configch and find corresponding values in configvals
    out(i).current=current;
    out(i).gatesID=gatesID;
    out(i).temp=cv(strcmp('MCtemp',cch));
    out(i).Vsd=cv(strcmp('Vsd',cch));
    out(i).T1=cv(strcmp(gatesID{2},cch));
    out(i).T2=cv(strcmp(gatesID{3},cch));
    out(i).TunnelAvg=(out(i).T1+out(i).T2)/2;
    out(i).Accum=cv(strcmp(gatesID{4},cch));
    out(i).alpha=s.data.alpha;
    out(i).rightloc = d.scan.loops.trafofn.args{1}(1);
    out(i).leftloc = d.scan.loops.trafofn.args{1}(2);
    out(i).baseloc = d.scan.loops.trafofn.args{1}(3);
    out(i).peakloc = d.scan.loops.trafofn.args{1}(4);
    out(i).basecurrent = d.data{2}(3);
    try
        out(i).time = timestamp;
    end
    if ismember('mag_x',input) || ismember('mag_y',input) || ismember('mag_z',input)
        out(i).Bx=cv(strcmp('Bx',cch));
        out(i).By=cv(strcmp('By',cch));
        out(i).Bz=cv(strcmp('Bz',cch));
    end
    
    if ismember('mag',input)
        out(i).B=cv(strcmp('B',cch));
    end
    %out(i).scanVars=scanVars{i};
    
    %for old datafile where 'Vdc' was used instead of 'Vsd'
    if isempty(out(i).Vsd)
        out(i).Vsd=cv(strcmp('Vdc',cch));
    end
    
    %Average the noise around 1 Hz
    bwStart=0.75;
    bwEnd=1.25;
    
    indStart=find(freqs>bwStart); indStart=indStart(1);
    indEnd=find(freqs>bwEnd); indEnd=indEnd(1);
    
    out(i).avgL=mean(Su_L(indStart:indEnd));
    out(i).avgR=mean(Su_R(indStart:indEnd));
    
    out(i).avgLI=mean(SI_L(indStart:indEnd));
    out(i).avgRI=mean(SI_R(indStart:indEnd));
    out(i).avgPI=mean(SI_P(indStart:indEnd));
    
    out(i).avgChrgNoise=sqrt((out(i).avgL + out(i).avgR)/2);
    out(i).avgChrgNoisePwr = (out(i).avgL + out(i).avgR)/2;
    
    
    %Fit the noise
    
    %threshold in A^2/Hz for rejecting peaks.
    thrshld_base=1e-25;
    thrshld_lr=1e-22;
    
    
    good_x=freqs(SI_B<thrshld_base);
    good_data_left=Su_L(SI_B<thrshld_base);
    good_data_right=Su_R(SI_B<thrshld_base);
    
    if isempty(good_x)
        thrshld_base = 1;
        warning(['Warning: Increased threshold to 1 in scan ', file{i}]);
        good_x=freqs(SI_B<thrshld_base);
        good_data_left=Su_L(SI_B<thrshld_base);
        good_data_right=Su_R(SI_B<thrshld_base);
        out(i).badscan = 1;
        if isempty(good_x)
            warning(['Warning: there are no points in the spectrum below a threshold value of 1 in file ', file{i}, '. Something probably went wrong in that scan.']);
        end
    else
        out(i).badscan = 0;
    end
    
    if good_x(1)>good_x(2)
        good_x=fliplr(good_x);
        good_data_left=fliplr(good_data_left);
        good_data_right=fliplr(good_data_right);
    end
    
    %bounds for fit
    freqStart=max([freqs(5),0.1]); %0.1
    freqEnd=9; %9 %good_x(end); %5 Max is 48
    
    %     startInd=3;
    %     endInd=length(good_data_right);
    
    startInd=find(good_x>freqStart,1);
    if startInd>1
        startInd=startInd-1;
    end
    %startInd = max(startInd,5);
    endInd=find(good_x>freqEnd,1);
    if freqEnd > max(good_x)
        endInd = length(good_x);
    end
    midInd = round((endInd-startInd)/2);
    
    
    %FIT A/f^beta
    good_data_left_lin = good_data_left;
    good_data_left=log10(good_data_left);
    good_x_lin = good_x;
    good_x=log10(good_x);
    fitfn=@(p,x) p(1)+p(2).*x;
    beta=[good_data_left(startInd) -1];
    [beta_l,l,~,~,~,err_l]=fitwrap('plinit plfit',good_x(startInd:endInd),good_data_left(startInd:endInd),beta,fitfn);
    out(i).A_l=10^beta_l(1); %JMN later overwritten
    out(i).A_l_err=abs(10^(beta_l(1)+err_l(1,1,1))-10^(beta_l(1))); %JMN later overwritten
    out(i).expon_l=beta_l(2);
    out(i).expon_l_err=(err_l(1,2,1));
    
    good_data_right_lin = good_data_right;
    good_data_right=log10(good_data_right);
    beta=[good_data_right(startInd) -1];
    [beta_r,r,~,~,~,err_r]=fitwrap('plinit plfit',good_x(startInd:endInd),good_data_right(startInd:endInd),beta,fitfn);
    out(i).A_r=10^beta_r(1); %JMN later overwritten
    out(i).A_r_err=abs(10^(beta_r(1)+err_r(1,1,1))-10^(beta_r(1))); %JMN later overwritten
    out(i).expon_r=beta_r(2);
    out(i).expon_r_err=(err_r(1,2,1));
    
    out(i).avgExpon = (out(i).expon_r + out(i).expon_l)*0.5;
    
    
    %     %FIT A/f^beta + B/1+C^2f^2
    %fitfn=@(p,x) log((p(1)./(10.^x).^p(2)) + (p(3)./(1+p(4).^2.*(10.^x).^2))); % A, beta, B, C
    %beta=[10^(good_data_left(midInd)*0.5) 1 10^(good_data_left(midInd)*0.5) 1];
    fitfn=@(p,x) log10((p(1)./(10.^x).^p(2)) + (p(3)./(1+p(4).^2.*(10.^x).^2))); % A, beta, B, C
    beta=[10^(good_data_left(midInd)) 1 10^(good_data_left(midInd)) 1];
    [beta_l_knee,l_knee,~,~,~,err_l_knee]=fitwrap('plinit plfit',good_x(startInd:endInd),good_data_left(startInd:endInd),beta,fitfn);
    
    drawnow;
    
    %beta=[10^(good_data_right(midInd)*0.5) 1 10^(good_data_right(midInd)*0.5) 1];
    beta=[10^(good_data_right(midInd)) 1 10^(good_data_right(midInd)) 1];
    [beta_r_knee,r_knee,~,~,~,err_r_knee]=fitwrap('plinit plfit',good_x(startInd:endInd),good_data_right(startInd:endInd),beta,fitfn);
    
    drawnow;
    
    %     % fitting to linear combination of power law + lorentzian
    %     %FIT A/f^beta + B/1+C^2f^2
    %     fitfn=@(p,x) (p(1)./(x.^p(2))) - (p(3)./(1+(p(4).^2).*(x.^2))); % A, beta, B, C
    %     beta=[good_data_left_lin(startInd) 1 good_data_left_lin(startInd) log(0.5)];
    %     [beta_l_knee,l_knee,~,~,~,err_l_knee]=fitwrap('plinit plfit',good_x_lin(startInd:endInd),good_data_left_lin(startInd:endInd),beta,fitfn);
    %     set(gca,'XScale','log','YScale','log');
    %     xlim([0.5 10]);
    %
    %     beta=[good_data_right_lin(midInd)*0.5 1 good_data_right_lin(midInd) 0.5];
    %     [beta_r_knee,r_knee,~,~,~,err_r_knee]=fitwrap('plinit plfit',good_x_lin(startInd:endInd),good_data_right_lin(startInd:endInd),beta,fitfn);
    %     set(gca,'XScale','log','YScale','log');
    %     xlim([0.5 10]);
    %
    
    xspace = linspace(good_x(startInd), good_x(endInd), 1000);
    fitL = fitfn(beta_l_knee,xspace);
    fitR = fitfn(beta_r_knee,xspace);
    %figure(7); clf;
    %plot(xspace,fitL,'b'); hold on;
    %plot(good_x(startInd:endInd),good_data_left(startInd:endInd),'r');
    
    dfitL = diff(fitL);
    dfitR = diff(fitR);
    dx = diff(xspace);
    f1ind = find(xspace>0,1); %JMN: ok, this makes sense, because x=log(freq)
    explknee = dfitL(f1ind)/dx(f1ind); %JMN ok, this makes sense. eval at 1 Hz.
    exprknee = dfitR(f1ind)/dx(f1ind); %JMN ok, this makes sense. eval at 1 Hz.
    
    out(i).expL_knee = explknee;
    out(i).expR_knee = exprknee;
    out(i).A_l = 10^fitL(f1ind); %JMN ok, this makes sense. eval at 1 Hz.
    out(i).A_r = 10^fitR(f1ind); %JMN ok, this makes sense. eval at 1 Hz.
    out(i).fitL = fitL;
    out(i).fitR = fitR;
    out(i).fitfreqs = xspace;
    
    
    
    
    %     % resample and extract expontnent
    %     xspace = linspace(good_x_lin(1), good_x_lin(end), 1000);
    %
    %     fitL = fitfn(beta_l_knee,xspace);
    %     fitR = fitfn(beta_r_knee,xspace);
    %     figure(7); clf;
    %     loglog(xspace,fitL,'b'); hold on;
    %     loglog(good_x_lin,good_data_left_lin,'r');
    %     dsInd = find(xspace>0.75,1);
    %     deInd = max(find(xspace<1.25));
    %
    %     dfitL = diff(log(fitL));
    %     dfitR = diff(log(fitR));
    %     f1ind = find(xspace>1,1);
    %     explknee = 10^dfitL(f1ind);
    %     exprknee = 10^dfitR(f1ind);
    %
    %out(i).expL_knee = -explknee;
    %out(i).expR_knee = -exprknee;
    
    %out(i).expL_knee = (log(fitL(deInd))-log(fitL(dsInd)))/(log(xspace(deInd))-log(xspace(dsInd)));
    %out(i).expR_knee = (log(fitR(deInd))-log(fitR(dsInd)))/(log(xspace(deInd))-log(xspace(dsInd)));
    
   
    %bounds for plotting   
    %     startInd= 3;
    %     endInd = length(good_data_right);
    
    % xxc: add the settings of the bounds back at 11/6/2020; This gives the lower and upper bounds of the "good" frequencies 
    if min(freqs)<min(10.^good_x)
        startInd = find(freqs>min(10.^good_x),1)-1;
    else
        startInd =2;
    end
    if max(freqs)> max(10.^good_x)
        endInd = find(freqs> max(10.^good_x),1)-1;
    else
        endInd = length(freqs);
    end
    
    %plot current noise spectra
    
    dispName=num2str(out(i).fnum);
    figure(222);
    subplot(1,2,1); hold on;
    plot(freqs(startInd:endInd),Su_L(startInd:endInd),'DisplayName',dispName); legend show;
    set(gca,'XScale','log','YScale','log');
    xlabel('Frequency (Hz)'); ylabel('spectral density (ev^2/Hz)'); title('left noise');
    
    subplot(1,2,2); hold on;
    plot(freqs(startInd:endInd),Su_R(startInd:endInd),'DisplayName',dispName); legend show;
    set(gca,'XScale','log','YScale','log');
    xlabel('Frequency (Hz)'); ylabel('spectral density (ev^2/Hz)'); title('right noise');
    
    ymin=min([min(SI_L),min(SI_L),min(SI_B),min(SI_P)])/5;
    ymax=max([max(SI_L),max(SI_R),max(SI_B),max(SI_P)])*5;
    
    
    %plot voltage noise spectra
    
    figure(223);
    subplot(1,4,1); hold on;
    plot(freqs(startInd:endInd),SI_L(startInd:endInd),'DisplayName',dispName); legend show;
    set(gca,'XScale','log','YScale','log');
    xlabel('Frequency (Hz)'); ylabel('spectral density (A^2/Hz)'); title('left noise');
    axis([0 freqs(endInd) ymin ymax]);
    
    
    subplot(1,4,2); hold on;
    plot(freqs(startInd:endInd),SI_R(startInd:endInd),'DisplayName',dispName); legend show;
    set(gca,'XScale','log','YScale','log');
    xlabel('Frequency (Hz)'); ylabel('spectral density (A^2/Hz)'); title('right noise');
    axis([0 freqs(endInd) ymin ymax]);
    
    
    subplot(1,4,3); hold on;
    plot(freqs(startInd:endInd),SI_P(startInd:endInd),'DisplayName',dispName); legend show;
    set(gca,'XScale','log','YScale','log');
    xlabel('Frequency (Hz)'); ylabel('spectral density (A^2/Hz)'); title('peak noise');
    axis([0 freqs(endInd) ymin ymax]);
    
    
    subplot(1,4,4); hold on;
    plot(freqs(startInd:endInd),SI_B(startInd:endInd),'DisplayName',dispName); legend show;
    set(gca,'XScale','log','YScale','log');
    xlabel('Frequency (Hz)'); ylabel('spectral density (A^2/Hz)'); title('baseline noise');
    axis([0 freqs(endInd) ymin ymax]);
    
    
end



opts=struct();
opts.file=file{1};
opts.body=strcat('file numbers ', num2str([out.fnum]));
opts.title='Charge noise data';

opts.figures = [222,223,777];

for i=1:length(input)
    switch input{i}
        
        case 'single'
            figure(777); clf; hold on;
            plot(freqs(startInd:endInd),SI_L(startInd:endInd),'DisplayName','Left');
            plot(freqs(startInd:endInd),SI_R(startInd:endInd),'DisplayName','Right');
            plot(freqs(startInd:endInd),SI_P(startInd:endInd),'DisplayName','Peak');
            plot(freqs(startInd:endInd),SI_B(startInd:endInd),'DisplayName','Baseline');
            plot(freqs(startInd:endInd),1e-2*SI_P(startInd)*(freqs(startInd:endInd)).^(-1),'DisplayName','1/f');
            legend show;
            set(gca,'XScale','log','YScale','log');
            xlabel('Frequency (Hz)','FontSize',18);
            ylabel('Current Spectral Density (A^2/Hz)','FontSize',18);
            title('Current Noise Power Spectral Density','FontSize',18);
            axis([0 freqs(endInd) ymin ymax]);
            
            if strcmp(bkgd_subtract,'y')
                figure(778); clf; hold on;
                plot(freqs(startInd:endInd),SI_Lbase(startInd:endInd),'DisplayName','Left-Base');
                plot(freqs(startInd:endInd),SI_Rbase(startInd:endInd),'DisplayName','Right-Base');
                plot(freqs(startInd:endInd),SI_Pbase(startInd:endInd),'DisplayName','Peak-Base');
                plot(freqs(startInd:endInd),SI_B(startInd:endInd),'DisplayName','Baseline');
                plot(freqs(startInd:endInd),1e-2*SI_P(startInd)*(freqs(startInd:endInd)).^(-1),'DisplayName','1/f');
                legend show;
                set(gca,'XScale','log','YScale','log');
                xlabel('Frequency (Hz)','FontSize',18);
                ylabel('Current Spectral Density (A^2/Hz)','FontSize',18);
                title('Current Noise Power Spectral Density (Baseline Subtracted)','FontSize',18);
                axis([0 freqs(endInd) ymin ymax]);
                
                opts.figures = [opts.figures 778];
            end
            
            
            %         case 'temp_avg'
            %
            % %             [plotTemp, sortIndex] = sort([out.temp]);
            % %             j = [out.avgChrgNoise];
            % %             sortedAvgChrgNoise = j(sortIndex);
            % %             k = [out.avgExpon];
            % %             sortedAvgExpon = k(sortIndex);
            %
            %             figure(777); clf; hold on;
            %             plot([out.temp],[out.avgChrgNoise],'ro-','DisplayName','Measured Data');
            %             xlabel('Temperature (K)','FontSize',18);
            %             ylabel('\Delta\epsilon at 1Hz (ev/sqrt(Hz))','FontSize',18);
            %             title('Charge Noise vs. Temperature','FontSize',18);
            %
            %             figure(778); clf; hold on;
            %             plot([out.temp],[out.avgExpon],'bo-','DisplayName','Measured Data');
            %             xlabel('Temperature (K)','FontSize',18);
            %             ylabel('Avg Expon','FontSize',18);
            %             title('Charge Noise vs. Temperature','FontSize',18);
            %
            %             figure(779); clf; hold on;
            %             plot([out.temp],[out(i).avgChrgNoisePwr],'go-','DisplayName','Measured Data');
            %             xlabel('Temperature (K)','FontSize',18);
            %             ylabel('\Delta\epsilon at 1Hz (ev^2/Hz)','FontSize',18);
            %             title('Charge Noise Power vs. Temperature','FontSize',18);
            %
            %             opts.figures = [opts.figures 777, 778];
            
            
        case 'temp'
            figure(777); clf; hold on;
            plot([out.temp],sqrt([out.avgL]),'ro','DisplayName','Left Side');
            plot([out.temp],sqrt([out.avgR]),'bo','DisplayName','Right Side');
            xlabel('Temperature (K)','FontSize',18);
            ylabel('\Delta\epsilon at 1Hz (ev/sqrt(Hz))','FontSize',18);
            title('Charge Noise vs. Temperature','FontSize',18);
            legend show;
            
            figure(780); clf; hold on;
            plot([out.temp],[out.avgChrgNoisePwr],'go','DisplayName','Measured Data');
            xlabel('Temperature (K)','FontSize',18);
            ylabel('\Delta\epsilon at 1Hz (ev^2/Hz)','FontSize',18);
            title('Charge Noise Power vs. Temperature','FontSize',18);
            
            [sortedTemp, sortIndex] = sort([out.temp]);
            j = [out.avgChrgNoisePwr];
            sortedAvgChrgNoisePwr = j(sortIndex);
            
            figure(781); clf; hold on;
            plot(sortedTemp,sortedAvgChrgNoisePwr,'bo','DisplayName','Measured Data','Linewidth',1.2);
            xlabel('Temperature (K)','FontSize',18);
            ylabel('\Delta\epsilon at 1Hz (ev^2/Hz)','FontSize',18);
            title('Charge Noise Power vs. Temperature','FontSize',18);
            
            %average nearest 5 points
            avgPoints = 5;
            w = (avgPoints-1)/2;
            acnp = sortedAvgChrgNoisePwr; % AverageChargeNoisePower
            avgLine = zeros(1,length(acnp));
            for i=1:length(acnp)
                if i > w & i < (length(acnp)-w+1)
                    avgLine(i) = mean(acnp(i-w:i+w));
                else
                    avgLine(i) = nan;
                end
            end
            avgLineName = ([num2str(avgPoints) ' Point Average Line']);
            plot(sortedTemp,avgLine,'r','DisplayName', avgLineName,'Linewidth',2);
            legend('Location','northwest');
            for i=1:length(sortedTemp)
                out(i).sortedTemp = sortedTemp(i);
                out(i).sortedAvgChrgNoisePwr = sortedAvgChrgNoisePwr(i);
                out(i).avgTempLine = avgLine(i);
            end
            
            
            figure(234); clf; hold on;
            subplot(2,2,1);
            hold on;
            errorbar([out.temp],[out.A_l],[out.A_l_err],'ro','DisplayName','Left');
            errorbar([out.temp],[out.A_r],[out.A_r_err],'bo','DisplayName','Right'); xlabel('Temperature (K)'); ylabel('spectral density (ev^2/Hz)'); title('Voltage noise amplitude vs temp');
            legend show;
            
            subplot(2,2,2);
            hold on;
            plot([out.temp],[out.avgL],'ro','DisplayName','Left');
            plot([out.temp],[out.avgR],'bo','DisplayName','Right'); xlabel('Temperature (K)'); ylabel('spectral density (ev^2/Hz)'); title('Avg voltage noise around 1 Hz vs temp');
            legend show;
            
            subplot(2,2,3);
            hold on;
            errorbar([out.temp],[out.expon_l],[out.expon_l_err],'ro','DisplayName','Left');
            errorbar([out.temp],[out.expon_r],[out.expon_r_err],'bo','DisplayName','Right'); xlabel('Temperature (K)'); ylabel('Exponent'); title('Exponent vs temp');
            legend show;
            
            subplot(2,2,4);
            hold on;
            plot([out.temp],[out.avgLI],'ro','DisplayName','Left');
            plot([out.temp],[out.avgRI],'bo','DisplayName','Right');
            plot([out.temp],[out.avgPI],'go','DisplayName','Peak');
            xlabel('Temperature (K)'); ylabel('spectral density (A^2/Hz)'); title('Average current noise around 1 Hz vs temp');
            legend show;
            
            figure(778); clf; hold on;
            plot([out.temp],[out.avgChrgNoise],'ro','DisplayName','Measured Data');
            xlabel('Temperature (K)','FontSize',18);
            ylabel('\Delta\epsilon at 1Hz (ev/sqrt(Hz))','FontSize',18);
            title('Average Charge Noise vs. Temperature','FontSize',18);
            
            figure(779); clf; hold on;
            plot([out.temp],[out.avgExpon],'bo','DisplayName','Measured Data');
            xlabel('Temperature (K)','FontSize',18);
            ylabel('Average \gamma (S_u \propto A/f^\gamma)','FontSize',18);
            title('Average Exponent vs. Temperature','FontSize',18);
            
            
            opts.figures = [opts.figures 234, 778, 779, 780];
            
        case 'vsd'
            figure(777); clf; hold on;
            plot([out.Vsd],sqrt([out.avgL]),'ro','DisplayName','Left Side');
            plot([out.Vsd],sqrt([out.avgR]),'bo','DisplayName','Right Side');
            xlabel('V_{sd} (V)','FontSize',18);
            ylabel('\Delta\epsilon at 1 Hz (eV/sqrt(Hz))','FontSize',18);
            title('Charge Noise vs. Source-Drain Bias','FontSize',18);
            legend show;
            
            figure(235); clf;
            subplot(2,2,1);
            hold on;
            errorbar([out.Vsd],[out.A_l],[out.A_l_err],'ro','DisplayName','Left');
            errorbar([out.Vsd],[out.A_r],[out.A_r_err],'bo','DisplayName','Right'); xlabel('Vsd (V)'); ylabel('Voltage noise spectral density (ev^2/Hz)'); title('Noise amplitude vs Vsd');
            legend show;
            
            subplot(2,2,2);
            hold on;
            plot([out.Vsd],[out.avgL],'ro','DisplayName','Left');
            plot([out.Vsd],[out.avgR],'bo','DisplayName','Right'); xlabel('Vsd (V)'); ylabel('Voltage noise spectral density (ev^2/Hz)'); title('Avg voltage noise around 1 Hz vs vsd');
            legend show;
            
            subplot(2,2,3);
            hold on;
            errorbar([out.Vsd],[out.expon_l],[out.expon_l_err],'ro','DisplayName','Left');
            errorbar([out.Vsd],[out.expon_r],[out.expon_r_err],'bo','DisplayName','Right'); xlabel('Vsd (V)'); ylabel('Exponent'); title('Exponent vs vsd');
            legend show;
            
            subplot(2,2,4);hold on;
            plot([out.Vsd],[out.avgLI],'ro','DisplayName','Left');
            plot([out.Vsd],[out.avgRI],'bo','DisplayName','Right');
            plot([out.Vsd],[out.avgPI],'go','DisplayName','Peak');
            xlabel('Vsd (V)'); ylabel('spectral density (A^2/Hz)'); title('Avg current noise around 1 Hz vs Vsd');
            legend show;
            
            opts.figures = [opts.figures 235];
            
        case 'tunnel'
            figure(236); clf; hold on;
            plot([out.TunnelAvg],[out.avgL],'ro','DisplayName','Left');
            plot([out.TunnelAvg],[out.avgR],'bo','DisplayName','Right');
            xlabel('Average Value of Tunneling Gates (V)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 236];
            
        case 'num_e'
            %             figure(777); clf; hold on;
            %             enum = 1:length([out.avgL]);
            %             labels{1} = 'N';
            %             for i=2:length(enum)
            %                 labels{i} = ['N+' num2str(i-1)];
            %             end
            %             plot(flip(enum),sqrt([out.avgL]),'ro','DisplayName','Left');
            %             plot(flip(enum),sqrt([out.avgR]),'bo','DisplayName','Right');
            %             set(gca,'xtick',1:length(enum));
            %             set(gca,'xticklabel',labels);
            %             xlabel('Number of Electrons in Dot','FontSize',18);
            %             ylabel('\Delta\epsilon at 1 Hz (eV/sqrt(Hz))','FontSize',18);
            %             title('Charge Noise vs. Electron Number','FontSize',18);
            %             legend show;
            
            figure(237); clf; hold on;
            enum = 1:length([out.avgL]);
            labels{1} = 'N';
            for i=2:length(enum)
                labels{i} = ['N+' num2str(i-1)];
            end
            plot(flip(enum),[out.avgL],'ro','DisplayName','Left');
            plot(flip(enum),[out.avgR],'bo','DisplayName','Right');
            set(gca,'xtick',1:length(enum));
            set(gca,'xticklabel',labels);
            xlabel('Number of Electrons in Dot'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 237];
            
        case 'accum'
            figure(238); clf; hold on;
            plot([out.Accum],[out.avgL],'ro','DisplayName','Left');
            plot([out.Accum],[out.avgR],'bo','DisplayName','Right');
            xlabel('Accumulation Gates (V)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            figure(239); clf; hold on;
            plot([out.Accum],[out.A_l],'ro','DisplayName','Left');
            plot([out.Accum],[out.A_r],'bo','DisplayName','Right');
            xlabel('Accumulation Gates (V)'); ylabel('spectral density (eV^2/Hz)'); title('Noise amplitude around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 238,239];
            
        case 'current'
            figure(240); clf; hold on;
            c1=[out.current]; c1=c1(1,:);
            c2=[out.current]; c2=c2(2,:);
            plot(c1,[out.avgR],'ro','DisplayName','Right');
            plot(c2,[out.avgL],'bo','DisplayName','Left');
            xlabel('Current (A)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            figure(241); clf; hold on;
            plot(c1,[out.A_r],'ro','DisplayName','Right');
            plot(c2,[out.A_r],'bo','DisplayName','Left');
            xlabel('Current (A)'); ylabel('spectral density (eV^2/Hz)'); title('Noise amplitude around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 240,241];
            
        case 'mag_x'
            figure(294); clf; hold on;
            plot([out.Bx],[out.avgL],'ro','DisplayName','Left');
            plot([out.Bx],[out.avgR],'bo','DisplayName','Right');
            xlabel('B_x (T)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            figure(295); clf; hold on;
            plot([out.Bx],[out.A_l],'ro','DisplayName','Left');
            plot([out.Bx],[out.A_r],'bo','DisplayName','Right');
            xlabel('B_x (T)'); ylabel('spectral density (eV^2/Hz)'); title('Noise amplitude around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 294,295];
            
        case 'mag_y'
            figure(296); clf; hold on;
            plot([out.By],[out.avgL],'ro','DisplayName','Left');
            plot([out.By],[out.avgR],'bo','DisplayName','Right');
            xlabel('B_y (T)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            figure(297); clf; hold on;
            plot([out.By],[out.A_l],'ro','DisplayName','Left');
            plot([out.By],[out.A_r],'bo','DisplayName','Right');
            xlabel('B_y (T)'); ylabel('spectral density (eV^2/Hz)'); title('Noise amplitude around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 296,297];
            
        case 'mag_z'
            figure(298); clf; hold on;
            plot([out.Bz],[out.avgL],'ro','DisplayName','Left');
            plot([out.Bz],[out.avgR],'bo','DisplayName','Right');
            xlabel('B_z (T)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            figure(299); clf; hold on;
            plot([out.Bz],[out.A_l],'ro','DisplayName','Left');
            plot([out.Bz],[out.A_r],'bo','DisplayName','Right');
            xlabel('B_z (T)'); ylabel('spectral density (eV^2/Hz)'); title('Noise amplitude around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 298,299];
            
        case 'mag'
            figure(300); clf; hold on;
            plot([out.B],[out.avgL],'ro','DisplayName','Left');
            plot([out.B],[out.avgR],'bo','DisplayName','Right');
            xlabel('B (T)'); ylabel('spectral density (eV^2/Hz)'); title('Avg voltage noise around 1 Hz');
            legend show;
            
            figure(301); clf; hold on;
            plot([out.B],[out.A_l],'ro','DisplayName','Left');
            plot([out.B],[out.A_r],'bo','DisplayName','Right');
            xlabel('B (T)'); ylabel('spectral density (eV^2/Hz)'); title('Noise amplitude around 1 Hz');
            legend show;
            
            opts.figures = [opts.figures 300,301];
            
        case 'time'
            
            figure(319); clf; hold on;
            plot([out.time],sqrt([out.avgL]),'ro','DisplayName','Left Side');
            plot([out.time],sqrt([out.avgR]),'bo','DisplayName','Right Side');
            xlabel('Timestamp'); ylabel('Charge Noise (eV/\surdHz)'); title('Average Charge Noise Around 1 Hz');
            legend show;
            
            figure(320); clf; hold on;
            subplot(3,1,1);
            hold on;
            plot([out.time],[out.rightloc],'ro','DisplayName','P Gate V Right');
            plot([out.time],[out.leftloc],'bo','DisplayName','P Gate V Left');
            %plot([out.time],sqrt([out.baseloc]),'go','DisplayName','P Gate V Base');
            plot([out.time],[out.peakloc],'mo','DisplayName','P Gate V Peak');
            xlabel('Timestamp'); ylabel('Plunger Gate Voltage (V)'); title('Plunger Gate Voltages Over Time');
            legend show;
            
            subplot(3,1,2);
            hold on;
            plot([out.time],sqrt([out.avgL]),'ro','DisplayName','Left Side');
            plot([out.time],sqrt([out.avgR]),'bo','DisplayName','Right Side');
            xlabel('Timestamp'); ylabel('Charge Noise (eV/\surdHz)'); title('Average Charge Noise Around 1 Hz');
            legend show;
            
            subplot(3,1,3);
            hold on;
            plot([out.time],[out.expL_knee],'ro','DisplayName','Left Side');
            plot([out.time],[out.expR_knee],'bo','DisplayName','Right Side');
            xlabel('Timestamp'); ylabel('\gamma'); title('Exponent at 1 Hz');
            legend show;
            
            
            figure(321); clf; hold on;
            plot([out.time],[out.A_l],'ro','DisplayName','Left Side');
            plot([out.time],[out.A_r],'bo','DisplayName','Right Side');
            xlabel('Timestamp'); ylabel('Charge Noise (eV^2/Hz)'); title('Average Charge Noise Power Around 1 Hz');
            legend show;
            
            figure(322); clf; hold on;
            subplot(2,1,1);
            hold on;
            plot([out.time],[out.rightloc],'ro','DisplayName','P Gate V Right');
            plot([out.time],[out.leftloc],'bo','DisplayName','P Gate V Left');
            %plot([out.time],sqrt([out.baseloc]),'go','DisplayName','P Gate V Base');
            plot([out.time],[out.peakloc],'mo','DisplayName','P Gate V Peak');
            xlabel('Timestamp'); ylabel('Plunger Gate Voltage (V)'); title('Plunger Gate Voltages Over Time');
            legend show;
            
            subplot(2,1,2);
            hold on;
            plot([out.time],[out.A_l],'ro','DisplayName','Left Side');
            plot([out.time],[out.A_r],'bo','DisplayName','Right Side');
            xlabel('Timestamp'); ylabel('Charge Noise (eV^2/Hz)'); title('Average Charge Noise Power 1 Hz');
            legend show;
            
            
            %             subplot(3,1,3);
            %             hold on;
            %             plot([out.time],[out.basecurrent],'ro','DisplayName','Baseline Current');
            %             xlabel('Timestamp'); ylabel('Baseline Current (A)'); title('Baseline Current vs Time');
            %             legend show;
            
            
            %             figure(321); clf; hold on;
            %             subplot(2,2,1);
            %             hold on;
            %             plot([out.time],[out.A_l],'ro','DisplayName','Left');
            %             plot([out.time],[out.A_r],'bo','DisplayName','Right'); xlabel('Timestamp'); ylabel('spectral density (ev^2/Hz)'); title('Voltage noise amplitude vs temp');
            %             legend show;
            %
            %             subplot(2,2,2);
            %             hold on;
            %             plot([out.time],[out.avgL],'ro','DisplayName','Left');
            %             plot([out.time],[out.avgR],'bo','DisplayName','Right'); xlabel('Timestamp'); ylabel('spectral density (ev^2/Hz)'); title('Avg voltage noise around 1 Hz vs temp');
            %             legend show;
            %
            %             subplot(2,2,3);
            %             hold on;
            %             plot([out.time],[out.expon_l],'ro','DisplayName','Left');
            %             plot([out.time],[out.expon_r],'bo','DisplayName','Right'); xlabel('Timestamp'); ylabel('Exponent'); title('Exponent vs temp');
            %             legend show;
            %
            %             subplot(2,2,4);
            %             hold on;
            %             plot([out.time],[out.avgLI],'ro','DisplayName','Left');
            %             plot([out.time],[out.avgRI],'bo','DisplayName','Right');
            %             plot([out.time],[out.avgPI],'go','DisplayName','Peak');
            %             xlabel('Timestamp'); ylabel('spectral density (A^2/Hz)'); title('Avg current noise around 1 Hz vs temp');
            %             legend show;
            
            
            
            
            
            opts.figures = [opts.figures 319 320 321];
            
        otherwise
            error('Incorrect input type. Please try again.')
    end
end

warning on;

pptprep(opts);

end

