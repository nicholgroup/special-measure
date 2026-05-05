function [out] = anaRFA(files)
%anaRFA(file1,file2) analyzes 2 RFA scans to determine optimum frequency/phase
%   files should be cell of two (2) RFA scans that mimic RF performance.
%   e.g. one file should be scan RFA with current full on and the other
%   file should be scan RFA with current pinched off using RF associated
%   plunger gate. Both files should have the same scan ranges
%
%   anaRFA just subtracts the two scans and looks for highest sensitivity
%   point

if ~exist('files','var')
    [~,~, files]=smgetfile('sm*RFA*.mat');
end

if ~iscell(files)
    files={files};
end

%analyze

d1 = load(files{1});
d2 = load(files{2});

delta = abs(d1.data{1}-d2.data{1});

maximum = max(max(delta));
[yi,xi]=find(delta==maximum);

%plot

xrng = d1.scan.loops(1).rng;
xpts = d1.scan.loops(1).npoints;
x = linspace(xrng(1), xrng(2), xpts);
xlab = d1.scan.loops(1).setchan;

yrng = d1.scan.loops(2).rng;
ypts = d1.scan.loops(2).npoints;
y = linspace(yrng(1), yrng(2), ypts);
ylab = d1.scan.loops(2).setchan;

figure(111); clf; 
imagesc(x,y,delta); hold on;
scatter(x(xi),y(yi),100,'k','filled');
set(gca,'YDir','Normal');
xlabel(xlab);
ylabel(ylab);

sprintf('Set %s to %d and %s to %d',xlab,x(xi),ylab,y(yi))

out.Freq = y(yi);
out.Phase = x(xi);





end

