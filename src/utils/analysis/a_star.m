function [a_star,specFiles,peakFiles] = a_star(files,minT,maxT)
%a_star calculates a lever arm from a temp sweep. 
%
% This function takes specfiles and cb peak files from a temp sweep and generates
% alpha star by plotting MC temp against electron temp (from MC temp = 
% 400mK to 1.5K) and forcing slope to be 1
%
%Returns: a_star, specFiles, peakFiles


%get files from temp sweep (select both spec and CB peak)
if ~exist('files','var')
    files=smgetfile('sm*.mat');
end

if ~iscell(files)
    files={files};
end

if ~exist('minT','var')
    minT = 0.2;%0.4
end
if ~exist('maxT','var')
    maxT = 1.5;
end

specFiles = {};
peakFiles = {};

%sort files
for i=1:length(files)
    if length(regexp(files{i},'spectrum'))>0
        specFiles{length(specFiles)+1} = files{i};
    else
        peakFiles{length(peakFiles)+1} = files{i};
    end
end


%analysis
MCTemp = zeros(1,length(specFiles));
elecTemp = zeros(1,length(specFiles));

warning off;
for i = 1:length(specFiles)
    display(['analyzing ' specFiles{i} '...']);
    display([num2str(i) '/' num2str(length(specFiles))]);
    specData = load(specFiles{i});
    mcsetptchan = find(strcmp('MCsetpt',specData.configch));
    alpha = specData.scan.data.alpha;
    MCTemp(i) = specData.configvals(mcsetptchan);
    out2 = elecTempCB(peakFiles{i},alpha);
    elecTemp(i) = out2.T;
    elecTempErr(i) = out2.errT;
end
warning on;
   
if elecTemp(1)>elecTemp(end)
    elecTemp = fliplr(elecTemp);
end
if MCTemp(1)>MCTemp(end)
    MCTemp = fliplr(MCTemp);
end
%elecTemp = elecTempCB(peakFiles,alpha); 

figure(381); clf; hold on;
errorbar(MCTemp, elecTemp, elecTempErr);
xlabel('MC Temp (K)');
ylabel('Electron Temp (K)');

% fit to extract correct lever arm alpha
[MCT_fit I] = sort(MCTemp);
indStart = find(MCT_fit>minT); indStart = indStart(1);
indEnd = find(MCT_fit<maxT); indEnd = indEnd(end);

MCT_fit = MCT_fit(indStart:indEnd);
elecT_fit = elecTemp(I);
elecT_fit = elecT_fit(indStart:indEnd);

fitfn=@(p,x) p(1).*x + p(2);
% mx + b

beta = [1 0];
[beta,~,~,~,~,err]=fitwrap('plinit plfit',MCT_fit,elecT_fit,beta,fitfn);
figure(500); xlabel('MC Temp (K)');ylabel('Electron Temp (K)')

alpha;
a_star = alpha/beta(1);

display(['fit from ' num2str(minT) ' to ' num2str(maxT) 'K']);
display('done');



end

