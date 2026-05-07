function [T] = elecTempCS(file,alpha)
% elecTempCS measures the electron temperature by fitting a charge transition (typically use 0-1) 
%
% The charge sensors should be measured by as measured by a charge sensor,
% and is fit to the Fermi-Dirac distribution. Alpha is the lever arm.


if ~exist('alpha','var')
    display('ASSUMING GLOBAL VALUE OF ALPHA');
    global alpha
end

if ~exist('file','var') || strcmp(file,'')
    file=smgetfile('sm*.mat');
end

figure(567);clf; 

if ~iscell(file)
    file={file};
end

for i=1:length(file)
    d=load(file{i});
    dat=d.data{i};

dat = dat/length(file);

xvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);

if xvals(1)>xvals(end);
    xvals = fliplr(xvals);
    dat = fliplr(dat');dat = dat';
end

% [~,i] = min(dat); i = i-round(d.scan.loops(1).npoints/2);
% [~,f] = max(dat); f = f+round(d.scan.loops(1).npoints/2);
% 
% if i>f
%     i=1;f=d.scan.loops(1).npoints;
% elseif i < 1
%     i=1
% end
% 
% if f > length(dat)
%     f = length(dat)
% end
% 
% if abs(f-i)<d.scan.loops(1).npoints/4
%     i=1;f=d.scan.loops(1).npoints;
% end

i=1; f=length(dat);

xv=xvals(i:f);
yv = nanmean(dat);
%yv=dat(i:f);

if size(yv,2)>size(yv,1)
    yv = yv';
end

kB=1.38e-23;
fitfn=@(p,x) p(1)+p(5)*(x-p(3))+p(2)./(exp((p(3)-x)./p(4))+1);
beta=[mean(yv) (max(yv)-min(yv)) xvals(floor((i+f)/2)) 1e-4 1e-1];
beta=fitwrap_legend('plfit samefig',xv,yv',beta,fitfn);

T = beta(4)*alpha*1.6e-19/kB;

end

d = load(file{1});

try
xlabel(d.scan.loops.setchan);
ylabel('charge sensor signal');
title('');
legend show;

niceFigure(1);
end

end

