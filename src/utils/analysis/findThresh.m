function out = findThresh(file,thresh)
% findThresh determines threshold voltage of current vs voltage trace
% thresh is optional argument that specifies the minimum current of the
% 'on' state. By default, the function identifies this by. It is units of
% amps.



%%%%%%%%% SET UP

% if file does not exist, choose file
if ~exist('file','var')
    [~,~, file] = smgetfile('sm*.mat');
end

% if file is not stored in a cell - put it in cell to make compatible with
% multiple files (future versions)
if ~iscell(file)
    file={file};
end


%%%%%%%%% DATA ANALYSIS

d = load(file{1}); %load file
n = d.scan.loops.npoints; % dimension of data
I = d.data{1}; % store current
V = linspace(d.scan.loops.rng(1),d.scan.loops.rng(2),n); %store voltage


%remove nan values
Inan = isnan(I);
I = I(~Inan);
V = V(~Inan);
%update n
n = length(I);
dV = abs(V(2)-V(1)); %voltage step size

% if current reading is negative - flip positive
if nanmean(I)<0
    I = -I;
end

% if voltage is going from high to low, flip
if V(end)<V(1)
    V = fliplr(V);
    I = fliplr(I);
end

% normalize current. This just makes some of the analysis a little easier
normI = I - min(I);
%normI = normI/range(normI); % normalized current
I = normI/range(normI);

% if thresh does not exist, determine based on estimated noise
% assumes the first 10% of data points are nominally 0 current
% find where slope is the max. assume this is on curve
diffI = gradient(I); %derivative of I
smdiffI = gradient(smooth(I,min(7,round(n/10)))); %smoothed derivative of I
[~,slopeInd] = max(smdiffI);
slopeV = V(slopeInd); % voltage for the steepest part of the turn on curve

% estimate rms noise at the voltages lower than slopeV
nbins = 100;
%[noiseI,noisebins] = hist(abs(diffI(1:slopeInd)),nbins); 
[noiseI,noisebins] = hist(abs(I(1:slopeInd)),nbins); 

[~,noiseInd] = max(noiseI);
noise = noisebins(noiseInd);
if ~exist('thresh','var')
    % define threshold as 10x the estimated noise
    thresh = 10*noise; %amps
end

% find where device turns on
% a better version of this would fit the turn on curve in this regime and
% extract the threshold voltage from the fit so that it was not limited by
% the resolution of the data. possible later versions.

onInds = (I-noise > thresh);

% while loop below is a crude attempt to ensure voltage point is not an outlier.
% Can definitely be improved.
while 1
    if ~any(onInds) %2021/12/13 EJC
        onInds = (I < 0.03);
    end
    guessOn = min(V(onInds)); %estimated threshold voltage
    guessInd = find(V==guessOn); %index for estimated threshold voltage
    if onInds(guessInd+1:guessInd+3) %next few points are also on. therefore this is not an outlier
        break
    else
        onInds(guessInd) = false;
    end
end

% estimate that voltage turns on linearly to get a slightly more accurate
% estimation for threshold that is not limited by scan resolution
V1 = min(V(guessInd-1)); %voltage point below threshold current
V2 = V(guessInd); %voltage point above threshold current
I1 = I(guessInd-1); %current below threshold
I2 = I(guessInd); %current above threshold
dIdV = (I2-I1)/(V2-V1); %slope of voltage turn on in A/V

guessOn = V2 + (thresh - I2)/dIdV; % update guess voltage to be where 

% store 
thresholdV = guessOn; % store threshold
thresholdI = thresh;
thresholdInd = guessInd;


%%%%%%%%% PLOTTING

% create label for x axis of plot
for i=1:length(d.scan.loops.setchan)
    if i==1
        gatestr = d.scan.loops.setchan{i};
    else
        gatestr = [gatestr, ', ' d.scan.loops.setchan{i}]; 
    end
end
gatestr = [gatestr ' (V)'];

isOn = ones(size(I))*max(I)/2;

% plot data and calculated threshold
figure(700); clf;
plot(V,I,'k','DisplayName','Data'); hold on;
plot(V(onInds),isOn(onInds),'g.','HandleVisibility','off'); 
plot(V(~onInds),isOn(~onInds),'r.','HandleVisibility','off'); 
plot(thresholdV,thresholdI,'bd','DisplayName',sprintf('Threshold Voltage=%0.3f +/- %0.3f V',thresholdV,dV)); 
plot(slopeV,I(slopeInd),'md','DisplayName',sprintf('Maximum Slope Voltage=%0.3f +/- %0.3f V',slopeV,dV));
%line([thresholdV thresholdV],[0 max(I)/2],'Color',[0.5 0.5 0.5]);
xlabel(gatestr);
ylabel('I (A)');
xlim([min(V) max(V)]);
title('Threshold Voltage Analysis');
legend('Location','best');


%%%%%%%%% STORE FUNCTION OUTPUTS 

out.gate = d.scan.loops.setchan;
out.thresholdV = thresholdV;
out.thresholdI = thresholdI;
out.maxSteepV = slopeV;

end