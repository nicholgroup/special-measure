function [out] = leverArmCB(file,elecTemp)
% leverArmCB(file,elecTemp) takes a CB peak file and determines the lever arm

out = struct;

if ~exist('file','var') || isempty(file)
    file=uigetfile('sm*.mat','MultiSelect','on');
end

if ~exist('elecTemp','var');
    elecTemp = input('What is the electron temperature in K? ');
end

if ~iscell(file)
    file={file};
end

alpha=zeros(1,length(file));
erralpha=zeros(1,length(file));

for j=1:length(file)
    d=load(file{j});
    if j==1
        dat=d.data{1};
    else
        dat = dat + d.data{1};
    end
    
    if size(dat,2)>1 %EJC: changed from size(dat,1)>1 10/28/2020
        dat = squeeze(nanmean(dat));
    end
    
    

dat = dat/length(file);

i=3;f=d.scan.loops(1).npoints;
xvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);

xv=xvals(i:f);
yv=dat(i:f);
figure(334); clf; plot(xv,yv)

% [n,edges]=histcounts(yv,40);
% [~,baseind]=max(n);
% baseline=edges(baseind);
baseline = nanmean(yv(1:10));

% adding line to subtract off baseline current so that peak find works for
% small peaks
yv = yv - baseline;
if size(yv,1)>size(yv,2)
    yv = yv';
end

[m,ind]=max(abs(yv));
%[m,ind]=min(yv);

kB=1.38e-23;
fitfn=@(p,x) p(1)+p(2).*cosh(((x-p(3)))/(p(4))).^(-2);
beta=[baseline yv(ind) xv(ind) .005];
[beta,~,~,~,~,err]=fitwrap('plinit plfit',xv,yv,beta,fitfn);
beta(4);
alpha(j) = 2*kB*elecTemp/(beta(4)*1.6e-19);
erralpha(j) = 2*kB*elecTemp/(err(4)*1.6e-19);

out.alpha=alpha;
out.erralpha=erralpha;
out.xv=xv;
out.yv=yv;

end

end
