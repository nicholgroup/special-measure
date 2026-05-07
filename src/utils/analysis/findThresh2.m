function out = findThresh2(data_struct,file,thresh)
%finds threshold voltage and current for turnoff data. optional arg thresh
%for threshold value


%%%%%%%%% SET UP

if isempty(data_struct) %if no data struct, load file
    
    if ~exist('file','var') 
        [~,~, file] = smgetfile('sm*.mat');
    end

    if ~iscell(file)
        file={file};
    end
    
    d = load(file{1});
    n = d.scan.loops.npoints; % dimension of data
    I = d.data{1}; % store current
    V = linspace(d.scan.loops.rng(1),d.scan.loops.rng(2),n); %store voltage
    xchan = d.scan.loops.setchan;
    
else %get data from data_struct
    fields = fieldnames(data_struct);
    xchan = 'V';
    I = data_struct.y;
    %remove nan values to get correct value for n
    Inan = isnan(I);
    I = I(~Inan);
    n = length(I);
    %check if x values are included, if not, use indices
    if length(fields)==2
        V = data_struct.x; 
    else
        V = linspace(1,n,n);
    end
end


%%%%%%%%% DATA ANALYSIS

%remove nan values
Inan = isnan(I);
I = I(~Inan);
V = V(~Inan);
    
%update n
n = length(I);
    
%flip I if necessary
if nanmean(I)<0
    I = -I;
end
    
%normalize I
normI = I - min(I);
I = normI/range(normI);
    
%smooth I
smI = smooth(I,min(7,round(n/10)));
    
%slope
stepV = range(V)/n;
smdiffI = abs(gradient(smI,stepV));
    
[~,slopeInd] = max(smdiffI);
slopeV = V(slopeInd);

% estimate rms noise at the voltages lower than slopeV
nbins = 100;

%past versions
%[noiseI,noisebins] = hist(abs(smdiffI(1:slopeInd)),nbins);
%[noiseI,noisebins] = hist(abs(I),nbins);

[noiseI,noisebins] = hist(abs(I(slopeInd:end)),nbins); 

[~,noiseInd] = max(noiseI);
noise = noisebins(noiseInd);
if ~exist('thresh','var')
    % define threshold as 10x the estimated noise
    thresh = 10*noise; %amps
end

% find where device turns on
onInds = (I-noise > thresh);


%check that guessOn is not outlier
while 1
    guessOn = min(V(onInds)); %estimated threshold voltage
    guessInd = find(V==guessOn); %index for estimated threshold voltage
    try
        if onInds(guessInd-3:guessInd-1) %next few points are also on. therefore this is not an outlier
            break
        else
            onInds(guessInd) = false;
        end
    catch
        break
    end
end

% estimate that voltage turns on linearly to get a slightly more accurate
% estimation for threshold that is not limited by scan resolution
V1 = min(V(guessInd+1)); %voltage point below threshold current
V2 = V(guessInd); %voltage point above threshold current
I1 = I(guessInd+1); %current below threshold
I2 = I(guessInd); %current above threshold
dIdV = (I2-I1)/(V2-V1); %slope of voltage turn on in A/V

guessOn = V2 + (thresh - I2)/dIdV; % update guess voltage


%%%%%%%%% PLOTTING

%plot data and threshold pt
figure(1);clf;
plot(V,I,'k','DisplayName','Data'); hold on;
plot(guessOn,thresh,'md','DisplayName',sprintf('Threshold Voltage = %f',guessOn))

xlabel(xchan)
ylabel('I (A)')
xlim([min(V) max(V)]);
title('Threshold Voltage')
legend('Location','best')


%%%%%%%%% OUTPUTS

out.threshV = guessOn;
out.threshI = thresh;

end