function [ scan ] = sensorTrafofn2(scan, DAQ, side, fname)
%sensorTrafofn2 analyzes data and computes the sensor compensation trafofn.
%function [ scan ] = sensorTrafofn2( scan,fname)
%   Opens a data file for a sensor scan, computes the appropriate trafofn,
%   and modifies the input scan.
%
%   In the sensor scan, the sensor gate should be on the x axis, 
%   and the sweep gate should be on y axis
%
%   DAQ: Given a DAQ signal, find the corresponding P gate voltage using
%   two-point linear extrapolation.
%   side: 'L' or 'R' corresponds to left or right side of the transport peak

%   Then calculate trafofn with slope = delta Sensor / delta dot 
%   trafofn = sensor_0 + slp * (dot - dot_0) 

%   This function assumes that you have configured the input scan
%   appropriately to accept this trafofn.
%
%   See \Box\Nichol Group\Jefferson\scripts\SiQuadDot\ChrgNoise_SiQD_2023_05_20.mat for
%   examples on how to use

if ~exist('fname','var')
    %file=get_files('sm_sensor*.mat');
    file=get_files('sm_*.mat');  
    d=load(file{1});
else
    d=load(fname);
end

dataIndex=1;
data=squeeze(d.data{dataIndex});
xvals = linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
yvals = linspace(d.scan.loops(end).rng(1),d.scan.loops(end).rng(2),d.scan.loops(end).npoints);
xLab = d.scan.loops(1).setchan;
yLab = d.scan.loops(end).setchan; 
if iscell(yLab) 
    yLab = char(yLab{:});
    yLab = yLab(1,:); 
end
if iscell(xLab) 
    xLab = char(xLab{:});
end

if ~isempty(strfind(yLab,'SD')) && isempty(strfind(xLab,'SD'))
    fprintf('Transposing data \n')
    tmp = xvals; xvals=yvals; yvals=tmp;
    tmp = xLab; xLab = yLab; yLab = tmp;
    data=data';
end

f=figure(167); clf; f.Name = 'Sensor Trafofn';
%fsigma=[0.7 0.1];
dataDiff=diff(data,1);
%dataFilt = lowpass(fsigma,dataDiff); 
dataFilt = dataDiff; 
dataNorm = bsxfun(@rdivide,dataFilt,diff(yvals')); % equivalent to dataFilt./diff(yvals')
m=nanmean(dataNorm(:)); s=nanstd(dataNorm(:));

subplot(2,1,2); 
imagesc(xvals,yvals,data); colorbar; 
set(gca,'YDir','Normal'); hold on; 
xlabel(xLab); ylabel(yLab);

subplot(2,1,1)
yvalsD = (yvals(1:end-1)+yvals(2:end))/2;
imagesc(xvals,yvalsD,dataNorm);  
set(gca,'YDir','Normal'); hold on; 
title('Charge sensing'); ylabel(yLab);
 % xlabel(xLab); 
caxis([m-3*s,m+3*s]); colorbar; 

%simple error checking
nloop=length(scan.loops);
if length(scan.loops(nloop).setchan)~=2
    error('Unexpected number of setchans.')
end

if scan.loops(nloop).npoints<2
    error('Unexpected number of sweep gate voltages.')
end

% automatically find the sensor P gate voltage given a conductance value and side
% of the peak
X = [];  % sensor P gate
%Y = linspace(scan.loops(nloop).rng(1), scan.loops(nloop).rng(2), scan.loops(nloop).npoints); % sweep gate voltages
Y = [scan.loops(nloop).rng(1) scan.loops(nloop).rng(2)]; % sweep gate voltages: just use two points
for ii = 1:length(Y)
    
    if ii==1
        sensorSig = data(1,2:end);  % 1st data point of the sensor scan. Get rid of the 1st voltage point due to the filter response time.
    else
        sensorSig = data(end,2:end); % last data point of the sensor scan. Get rid of the 1st voltage point due to the filter response time.
    end

    [~,I]=sort(abs(sensorSig-DAQ)); % find the intersection

    if mean(sensorSig)<sensorSig(1) % determine whether it is a transport peak or dip
        [~,topidx]=min(sensorSig);
    elseif mean(sensorSig)>sensorSig(1)
        [~,topidx]=max(sensorSig);
    else
        error('Wrong top peak index')
    end

    if strcmp(side,'L') % left side of the transport peak
        I = I(I<topidx); ind = I(1);
        X(ii) = xvals(ind);
    elseif strcmp(side,'R') % right side of the transport peak
        I = I(I>topidx); ind = I(1);
        X(ii) = xvals(ind);
    end

end

xstring='[';
ystring='[';
for i=1:length(X)
    xstring=sprintf('%s %.3f ',xstring,X(i));
    ystring=sprintf('%s %.3f ',ystring,Y(i));
end
xstring=sprintf('%s]',xstring);
ystring=sprintf('%s]',ystring);

if length(X)==2    
    slope=(X(end)-X(1))/(Y(end)-Y(1));
    fnstr=sprintf('@(x,y,p)p(1)*(x(%d)-p(2))+p(3)',nloop);
    scan.loops(nloop).trafofn(2).fn=str2func(fnstr);
    scan.loops(nloop).trafofn(2).args={[slope, Y(1), X(1)]};
    fprintf('{[%.3f %.3f %.3f]}\n',slope,Y(1),X(1));
    figure(167); 
    subplot(2,1,2); line(X,Y,'Color','r','LineWidth',2); 
    subplot(2,1,1); line(X,Y,'Color','r','LineWidth',2);
else
    error('Wrong trafofn!')
end

% Do not use below
% % modify the scan using trafofn
% fnstr=sprintf('@(x,y,p,q) interp1(p,q,x(%d),''linear'',''extrap'')',nloop);
% scan.loops(nloop).trafofn(2).fn=str2func(fnstr);
% scan.loops(nloop).trafofn(2).args{1}=Y;
% scan.loops(nloop).trafofn(2).args{2}=X;
% 
% % print and plot to check
% fprintf('fn=@(x,y,p,q) interp1(p,q,x(%d))\nargs{1}=%s\nargs{2}=%s\n',nloop,ystring,xstring);
% rng = linspace(scan.loops(nloop).rng(1), scan.loops(nloop).rng(2), scan.loops(nloop).npoints);
% Xvals = interp1(scan.loops(nloop).trafofn(2).args{1},scan.loops(nloop).trafofn(2).args{2},rng,'linear','extrap');
% subplot(2,1,2); plot(Xvals,rng,'Color','r','LineWidth',2);
% subplot(2,1,1); plot(Xvals,rng,'Color','r','LineWidth',2);

end
