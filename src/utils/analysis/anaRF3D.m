function [out] = anaRF3D(files,plt)
%anaRF3D(file,plt) analyzes 1 scanRF_3D (scan with loop 1 = phase, loop 2 = freq, loop 3 = gate voltage)

out = struct;

if ~exist('files','var')
    [~,~, files]=smgetfile('sm*scanRF_3D*.mat');
end

if ~exist('plt','var')
    plt=1;
end

if ~iscell(files)
    files={files};
end


%analyze

d = load(files{1});
dat = d.data{1};
S11 = squeeze(range(dat,3));
[minS11,minind] = min(S11,[],2); 
freqs = linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
gateVals = linspace(d.scan.loops(3).rng(1),d.scan.loops(3).rng(2),d.scan.loops(3).npoints);
resFreq = freqs(minind)*1e-6;

%plot

if iscell(d.scan.loops(3).setchan)
    xlab = '';
    setchans = d.scan.loops(3).setchan;
    for i=1:length(setchans);
        xlab = [xlab setchans{i}];
    end
else
    xlab = d.scan.loops(3).setchan;
end

f1ind = max(strfind(files{1},'\'));
f1short = files{1}(f1ind+1:end-4);

if plt
   figure(112); clf;
   yyaxis left;
   plot(gateVals,minS11,'bx','MarkerSize',10);
   ylabel('Minimum of S11 proxy');
   yyaxis right;
   plot(gateVals,resFreq,'rx','MarkerSize',10);
   ylabel('Resonance frequency (MHz)');
   xlabel(xlab);
end

opts=struct();
opts.file=files{1};
opts.body = '';
opts.title='anaRF3D output';
opts.figures=[112];
pptprep(opts);




end

