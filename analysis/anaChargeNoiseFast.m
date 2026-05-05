function [ out ] = anaChargeNoiseFast(input,file)
% anaChargeNoiseFast analyzes charge noise data taken using
% chargeNoiseScans fast measurements.
%
% [ out ] = anaChargeNoiseFast(input,file) input 'single', 'temp', 'vsd',
% 'accum', 'num_e'. multiple inputs not yet supported.
%
% output figures: 234 (temp), 235 (vsd), 236 (tunnel), 237 (num_e), 238 and
% 239 (accum)
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
    file=smgetfile('sm*FastSpectrum*.mat');
end

if ~iscell(file)
    file={file};
end

if ~iscell(input)
    input={input};
end

out=struct;

for i=1:length(file)
    d=load(file{i});
    s=d.scan;
    cch=d.configch;
    
    cv=d.configvals;
    data=d.data{1};
    dIdV=s.data.dIdV;
    gatesID=d.scan.data.gatesID;

    out(i).fileName=file{i};
    
    ind=regexp(fliplr(file{i}),'_');
    fnameFlip=fliplr(file{i});
    out(i).fnum=str2num(fliplr(fnameFlip(5:ind-1)));
    
    for j=1:size(data,1)
        switch d.scan.data.pointID{j}
            case 'base'
                varI_B=std(data(j,:)).^2;
                out(i).varI_B=varI_B;
                
            case 'peak'
                varI_P=std(data(j,:)).^2;
                out(i).varI_P=varI_P;
                
            case 'left'
                varI_L=std(data(j,:)).^2;
                varV_L=varI_L/(dIdV(j)/s.data.alpha).^2;
                A_L=varV_L/log(size(data,2));
                sigma_mu_L=sqrt(A_L);
                out(i).A_L=A_L;
                out(i).varI_L=varI_L;
                out(i).sigma_mu_L=sigma_mu_L;
                
            case 'right'
                varI_R=std(data(j,:)).^2;
                varV_R=varI_R/(dIdV(j)/s.data.alpha).^2;
                A_R=varV_R/log(size(data,2));
                sigma_mu_R=sqrt(A_R);
                out(i).A_R=A_R;
                out(i).varI_R=varI_R;
                out(i).sigma_mu_R=sigma_mu_R;
                
        end
    end

    out(i).gatesID=gatesID;
    out(i).temp=cv(strcmp('MCsetpt',cch));
    out(i).Vsd=cv(strcmp('Vsd',cch));
    out(i).T1=cv(strcmp(gatesID{2},cch));
    out(i).T2=cv(strcmp(gatesID{3},cch));
    out(i).TunnelAvg=(out(i).T1+out(i).T2)/2;
    out(i).Accum=cv(strcmp(gatesID{4},cch));
    out(i).alpha=s.data.alpha;    
    
    
end



opts=struct();
opts.file=file{1};
opts.body=strcat('file numbers ', num2str([out.fnum]));
opts.title='Fast Charge noise data';

opts.figures = [];

for i=1:length(input)
    switch input{i}
        
        case 'single'
            0;
        
        case 'temp'           
            figure(234); clf; hold on;
            subplot(1,2,1);
            hold on;
            plot([out.temp],[out.A_L],'ro','DisplayName','Left');
            plot([out.temp],[out.A_R],'bo','DisplayName','Right');
            set(gca,'YScale','log');
            xlabel('Temperature (K)'); ylabel('Charge Noise at 1 Hz (ev^2)'); title('Charge Noise vs Vsd');
            legend show;
            
            subplot(1,2,2);
            hold on;
            plot([out.temp],[out.varI_L],'ro','DisplayName','Left');
            plot([out.temp],[out.varI_R],'bo','DisplayName','Right');
            plot([out.temp],[out.varI_B],'cd','DisplayName','Base');
            plot([out.temp],[out.varI_P],'ks','DisplayName','Peak');
            set(gca,'YScale','log');
            xlabel('Temperature (K)'); ylabel('Current Variance (A^2)'); title('Current Variance vs Vsd');
            legend show;
            
            opts.figures = [opts.figures 234];
            
        case 'vsd'
            figure(235); clf;
            subplot(1,2,1);
            hold on;
            plot([out.Vsd],[out.A_L],'ro','DisplayName','Left');
            plot([out.Vsd],[out.A_R],'bo','DisplayName','Right');
            set(gca,'YScale','log');
            xlabel('Vsd (V)'); ylabel('Charge Noise at 1 Hz (ev^2)'); title('Charge Noise vs Vsd');
            legend show;
            
            subplot(1,2,2);
            hold on;
            plot([out.Vsd],[out.varI_L],'ro','DisplayName','Left');
            plot([out.Vsd],[out.varI_R],'bo','DisplayName','Right');
            plot([out.Vsd],[out.varI_B],'cd','DisplayName','Base');
            plot([out.Vsd],[out.varI_P],'ks','DisplayName','Peak');
            set(gca,'YScale','log');
            xlabel('Vsd (V)'); ylabel('Current Variance (A^2)'); title('Current Variance vs Vsd');
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
            
        otherwise
            error('Incorrect input type. Please try again.')
    end
end



pptprep(opts);

end

