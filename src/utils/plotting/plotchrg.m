function [out] = plotchrg(file,snr)
%for plotting chrg stability diagrams, removing sensor drift column/column
%and row/row (does not fit to a plane)

out = struct;

if ~exist('file','var') | isempty(file)
    [~,~,file] = smgetfile('sm*.mat');
end

if ~exist('snr','var')
    snr = 0;
end

if ~iscell(file)
    file={file};
end

fname = split(file,'\');
fname = fname{end};
fname = fname(1:end-4);

d = load(file{1});
x = linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
y = linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
if length(size(d.data{1}))>2
    z = squeeze(nanmean(d.data{1}));
else
    z = d.data{1};
end
zz = detrend(detrend(z)')';
[dzdx,dzdy] = gradient(z);
[dzzdx,dzzdy] = gradient(zz);
diffz = abs(dzdx) + abs(dzdy);
diffzz = abs(dzzdx) + abs(dzzdy);

figure(222); clf; 
cmap = colormap('gray');
colormap(flipud(cmap));
subplot(2,2,1);
cplot(x,y,z);
xlabel(d.scan.loops(1).setchan);
ylabel(d.scan.loops(2).setchan);
title('Raw data'); 
subplot(2,2,2);
cplot(x,y,zz);
xlabel(d.scan.loops(1).setchan);
ylabel(d.scan.loops(2).setchan);
title('Detrended data'); 
subplot(2,2,3);
cplot(x,y,diffz);
xlabel(d.scan.loops(1).setchan);
ylabel(d.scan.loops(2).setchan);
title('Raw diff data'); 
subplot(2,2,4);
cplot(x,y,diffzz);
xlabel(d.scan.loops(1).setchan);
ylabel(d.scan.loops(2).setchan);
title('Detrended diff data'); 

% approximate SNR?
if snr
    outsnr = chrgsnr(x,y,diffzz);
    bodystr = outsnr.outstr;
    out = outsnr;
else
    bodystr = '';
end

out.x = x;
out.y = y;
out.z = z;


opts=struct();
opts.file = file{1};
opts.body = bodystr;
opts.title='plotchrg output';
opts.figures = [222];
pptprep(opts);

end

