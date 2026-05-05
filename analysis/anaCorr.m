function [out] = anaCorr(signal,cutOffFreq,filterCascadeCount,downsampleSegmentTime)
% anaCorr analyzes the correlation between different time series.
%
% designed for work with washington data file 5848 but should work for
% files of same size (acqTime = 1600 sec, acqFreq = 10kHz) - alternatively,
% one could make acqTime and acqFreq either saved variables with the scan
% or passable variables for this function
%
% for 5848 Channel A is RP2 and Channel B is LP1

out = struct;

%display(['Applied low-pass filter with cutoff frequency = ', num2str(cutOffFreq), 'Hz ', num2str(filterCascadeCount), ' time(s).']);
R = 1;
C = 1/(2*pi*cutOffFreq);

maxPlotFreq = 2*cutOffFreq;
maxPlotPts = 8e5;

if maxPlotFreq > 2
    maxPlotFreq = 2;
end

if ~iscell(signal)
    signal = {signal};
end

warning off

for i = 1:length(signal)
    
    % load signal
    d = load(signal{i});
    A = d.data{1};
    B = d.data{2};
    npts = length(A);
    acqFreq = 1e4;
    acqTime = 1600;
    timeVec = (0:npts-1)/acqFreq;
    
    % fourier transform
    sampT = 1/acqFreq;
    timeVec = (0:length(A)-1)*sampT;
    
    freqA = fft(A);
    freqB = fft(B);
    %     figure(223); clf; hold on;
    %     plot(abs(freqA), 'DisplayName','Channel A');
    %     plot(abs(freqB), 'DisplayName','Channel B'); legend show;
    
    % transfer function
    dt=1;
    len=dt*length(A);
    df=1/len;
    freqs=(1:length(A))*acqFreq/length(A);
    freqs(npts/2+1:end)=fliplr(freqs(1:npts/2));
    omegas=2.*pi.*freqs;
    [~, index] = min(abs(freqs-maxPlotFreq));
    transfer=1./(1+1i.*omegas.*R.*C).^filterCascadeCount;
    %figure(333); clf; plot(freqs(1:index),abs(transfer(1:index))); title('Transfer function');
    
    % ADD PLOT HERE TO LOOK AT SPECTRUM OF FILTERED SIGNAL
    filtFreqA = freqA.*transfer;
    filtFreqB = freqB.*transfer;
    
%     figure(226); clf;
%     semilogy(freqs(3:index),abs(filtFreqA(3:index)), 'DisplayName', 'Channel A (Filtered)');
%     hold on;
%     semilogy(freqs(3:index),abs(freqA(3:index)), 'DisplayName', 'Channel A (Unfiltered)'); title('Channel A spectrum'); legend show;
%     
%     figure(227); clf;
%     semilogy(freqs(3:index),abs(filtFreqB(3:index)), 'DisplayName', 'Channel B (Filtered)');
%     hold on;
%     semilogy(freqs(3:index),abs(freqB(3:index)), 'DisplayName', 'Channel B (Uniltered)');title('Channel B spectrum'); legend show;
%     
    % filtered signal
    filtA = ifft(freqA.*transfer,'symmetric');
    filtB = ifft(freqB.*transfer,'symmetric');
%     figure(224); clf; hold on;
%     plot(filtA(1:maxPlotPts),'DisplayName','Channel A (Filtered)');
%     plot(filtB(1:maxPlotPts),'DisplayName','Channel B (Filtered)'); title('Filtered Signal'); legend show;
%     
    % correlate filtered measurement
    [out(i).rhoFilt, out(i).pvalsFilt] = corrcoef(filtA,filtB);
    
    % average every 100 seconds of data collection (100000 pts) to create new
    % A and B datasets and compute rho for the whole data set of down sampled pts (avgFiltA/B, rhoAvgFilt)
    ptsPerAvg = downsampleSegmentTime*acqFreq; %time * acqFreq
    count = floor(length(A)/ptsPerAvg);
    avgFiltA = [];
    avgFiltB = [];
    for j = 1:count
        avgFiltA = [avgFiltA mean(filtA(1+ptsPerAvg*(j-1):ptsPerAvg*j))];
        avgFiltB = [avgFiltB mean(filtB(1+ptsPerAvg*(j-1):ptsPerAvg*j))];
    end
    [rhoAvgFilt, pvalsAvgFilt] = corrcoef(avgFiltA,avgFiltB);
    out(i).rhoAvgFilt = rhoAvgFilt(2);
    out(i).pvalsAvgFilt = pvalsAvgFilt(2);
    out(i).avgFiltA = avgFiltA;
    out(i).avgFiltB = avgFiltB;
    
    
    
    
%         display('___________Low-Pass Filtered & Down Sampled Signal___________');
%         display(['rhoAvgAB(avgFiltA,avgFiltB) = ', num2str(out(i).rhoAvgFilt(2))]);
%         display(['pval(filtA,filtB) = ', num2str(out(i).pvalsAvgFilt(2))]);
%       
      
%         % looking at power spectrum of correlation of signals
%         C_omega = conj(freqA).*freqB;
%         powerA = abs(freqA).^2;
%         figure(338); clf;
%         semilogy(freqs(3:index),abs(C_omega(3:index)),'DisplayName','Convolution');
%         hold on;
%         semilogy(freqs(3:index),powerA(3:index),'DisplayName','Power Spectrum A');
%         title('Hacky Convolution Type Thing');
%         legend show;
%         
%         figure(339); clf; hold on;
%         plot(avgFiltA,'DisplayName','AvgFiltA');
%         plot(avgFiltB,'DisplayName','AvgFiltB');
%         legend show;


end

time = linspace(0,dt*length(out(1).avgFiltA),length(out(1).avgFiltA));

warning on

figure(711); clf; hold on;
plot([out.rhoAvgFilt],'o');
ylabel('Correlation Coefficients');
xlabel('Scan');
title('Correlation Coeffecients (Down Sampled & Filtered)');

% figure(339); clf; hold on;
% plot(avgFiltA,'DisplayName','LP1');
% plot(avgFiltB,'DisplayName','RP1');
% xlabel('Time (s)');
% ylabel('Voltage (V)');
% title('Charge Noise Correlation');
% legend show;

