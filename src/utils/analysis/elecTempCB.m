function [out] = elecTempCB(file,alpha)
% elecTempCB takes a CB peak file and determines the electron temperature 
%
% [out] = elecTempCB(file,alpha)
% alpha is the lever arm.
out = struct;

if ~exist('file','var')
    file=uigetfile('sm*.mat','MultiSelect','on');
end

if ~exist('alpha','var')
    alpha = input('What is the value of alpha? ');
end

if ~iscell(file)
    file={file};
end

T=zeros(1,length(file));
errT=zeros(1,length(file));

for j=1:length(file)
    d=load(file{j});
    if j==1
        dat=d.data{1};
    else
        dat = dat + d.data{1};
    end
    
    if size(dat,1)>1
        %JMN 2020_10_27
        %dat = squeeze(nanmean(dat));
    end
    
    

dat = dat/length(file);

i=3;f=d.scan.loops(1).npoints;
xvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);

xv=xvals(i:f);
yv=dat(i:f);
figure(334); clf; plot(xv,yv)

[n,edges]=histcounts(yv,40);
[~,baseind]=max(n);
baseline=edges(baseind);

% adding line to subtract off baseline current so that peak find works for
% small peaks
%yv = yv - baseline;
if size(yv,1)>size(yv,2)
    yv = yv';
end

[~,ind]=max(abs(yv));
%[m,ind]=max(abs(yv));
%[m,ind]=min(yv);

kB=1.38e-23;
fitfn=@(p,x) p(1)+p(2).*cosh(((x-p(3)))/(p(4))).^(-2);
beta=[baseline yv(ind) xv(ind) .0005];
[beta,~,~,~,~,err]=fitwrap('plinit plfit',xv,yv,beta,fitfn);
beta(4);
T(j) = beta(4)*alpha*1.6e-19/(2*kB);
errT(j) = err(1,4)*alpha*1.6e-19/(2*kB); % err: standard error %JMN 2020_10_27 changed from err(4)*... to err(1,4,1)*...

out.T=T;
out.errT=errT;
out.xv=xv;
out.yv=yv;

end


