function [out] = plotramsey(fx,fy,cx,cy,zpL,scale)
%[out]=plotramsey(fx,fy,cx,cy,zpL,scale) plots 2D ramsey scan and fft
%
%fx,fy define epsilon direction.
%cx,cy are compensation values for tunneling gate of x,y plunger gates
%zpL is optional argument for zeropad length for fft. default is 2048
%scale is optional argument to scale data. binary. default=1.


if ~exist('zpL','var') || isempty(zpL)
    zpL = 2048; %fft zero paddding
end

if ~exist('scale','var') || isempty(scale)
    scale = 1; %binary option to scale data
end

% load and scale data
[~,~, file]=smgetfile('sm*.mat');%file = uigetfile('sm*.mat');
d = load(file);
scan = d.scan;
data = d.data;
if scale
    sd = anaHistScaleV4(scan,data,300e-6,'L',[],'randplot');
else
    sd = d.data;
end
zvals = squeeze(nanmean(sd{1}));

% extract scan info
p1 = scan.data.pulsegroups(1).params;
p2 = scan.data.pulsegroups(end).params;
gd = scan.data.pulsegroups(1).xval;
ngroups = length(scan.data.pulsegroups);
xvals = gd(end,:); %gd(2,:);
try
    if p1(4)==p2(4) %tunneling gate is not being varied
        yvals = linspace((p1(2)+p1(4).*cx)./fx ,(p2(2)+p2(4).*cx)./fx,ngroups);
        ylab = '\epsilon (mV)';
    else
        yvals=linspace(p1(4),p2(4),ngroups);
        ylab = 'T (mV)'
    end
catch
    yvals = linspace(1,ngroups,ngroups);
    ylab = 'ngroup';
end

% calculate fft
dt = xvals(2) - xvals(1);
fftdata = zvals - nanmean(zvals,2);
[y,freq] = ezfft(fftdata,dt,2,zpL);
y = y(:,1:end/2);

if length(size(sd{1}))==2
    oneD = 1;
else
    oneD = 0;
end

figInd = 333;
figure(figInd); clf;
subplot(1,2,1);
if oneD
    plot(xvals,zvals);
    ylabel('Prob')
else
    cplot(xvals,yvals,zvals);
    ylabel(ylab);
    colorbar;
end
xlabel('Time (ns)');
title('Ramsey');
subplot(1,2,2);
if oneD
    plot(freq*1e3,y);
    ylabel('FFT');
else
    cplot(freq.*1e3,yvals,y);
    ylabel(ylab);
end
xlabel('Frequency (MHz)');
title({'FFT'});
colorbar;

%title(sprintf('Symmetric exchange: adprep:%3.3f mV ramp T34 to %3.3f mV and pulse %3.3f mV',evoEps,p1(8),p1(4)));
set(gca,'YDir','normal');
colorbar;
opts=struct();
opts.file=file;
opts.title='plotramsey output';
opts.figures=figInd;
opts.body='';
pptprep(opts);

out = struct;
out.xvals = xvals;
out.yvals = yvals;
out.zvals = zvals;
out.fft_x = freq;
out.fft_y = yvals;
out.fft_z = y;

end

