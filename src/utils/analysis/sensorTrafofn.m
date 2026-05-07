function [ scan ] = sensorTrafofn( scan,fname)
%sensorTrafofn analyzes data and computes the sensor compensation trafofn.
%function [ scan ] = sensorTrafofn( scan,fname)
%   Opens a data file for a sensor scan, computes the appropriate trafofn,
%   and modifies the input scan.
%
%   In the sensor scan, the sensor gate should be on the x axis, 
%   and the dot gate should be on y axis
%
%   Has you select line of constant signal from plot 
%   Then calculates trafofn with slope = delta Sensor / delta dot 
%   trafofn = sensor_0 + slp * (dot - dot_0) 
%   
%   This function assumes that you have configured the input scan
%   appropriately to accept this trafofn.
%
%   See z:qDots\matlab\matlab_beast\measure_qpc_and_cb_2014_03_28 for
%   examples on how to use

if ~exist('fname','var')
    file=get_files('sm_sensor*.mat');  
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
% if ~iscell(d.scan.loops(2).setchan)
%     d.scan.loops(2).setchan = {d.scan.loops(2).setchan};
% end
% if ~iscell(d.scan.loops(1).setchan)
%     d.scan.loops(1).setchan = {d.scan.loops(1).setchan};
% end
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


[X,Y]=ginput(); xinterp=[]; yinterp=[];
xstring='[';
ystring='[';
for i=1:length(X)
    xstring=sprintf('%s %.3f ',xstring,X(i));
    ystring=sprintf('%s %.3f ',ystring,Y(i));
    xinterp(end+1)=X(i);
    yinterp(end+1)=Y(i);
end

xstring=sprintf('%s]',xstring);
ystring=sprintf('%s]',ystring);

%simple error checking
nloop=length(scan.loops);
if length(scan.loops(nloop).setchan)~=2
    error('Unexpected number of setchans.')
end
if length(X) == 1 %you clicked one point. not sure what this is doing. Dont use. 
    error('Unexpected number of points.')
    [~,xInd] = min(abs(xvals-X));
    [~,yInd] = min(abs(yvals-Y));
    setVal = data(yInd,xInd);
    rp = @(x1,x2,x) heaviside(x-x1)-heaviside(x-x2); %1 between x1, x2
    
    [~,inds]=min(abs(data-setVal),[],2);
    xv = xvals(inds); 
    inc = floor(length(xv)/6); 
    for i = 1:6         
        vals = ((i-1)*inc+1):i*inc;
        p{i}=robustfit(yvals(vals),xv(vals));
    end
    %slope=p(2);
    %scan.loops(nloop).trafofn(2).fn=@(x,y,a) a(1)*(x(nloop)-a(2))+a(3)';
    %scan.loops(nloop).trafofn(2).fn=@(x,y,p,q) interp1(p,q,x(2),'linear','extrap');
    
    fnstr=sprintf('@(x,y,p,q) interp1(p,q,x(%d),''linear'',''extrap'')',nloop);
    scan.loops(nloop).trafofn(2).fn=str2func(fnstr);
    scan.loops(nloop).trafofn(2).args{1}=Y;
    scan.loops(nloop).trafofn(2).args{2}=X;
    fprintf('fn=@(x,y,p,q) interp1(p,q,x(%d))\nargs{1}=%s\nargs{2}=%s\n',nloop,string,xstring);
    rng = linspace(scan.loops(nloop).rng(1), scan.loops(nloop).rng(2), scan.loops(nloop).npoints); 
    Xvals = interp1(scan.loops(nloop).trafofn(2).args{1},scan.loops(nloop).trafofn(2).args{2},rng,'linear','extrap');
    subplot(2,1,2); plot(Xvals,rng,'Color','r','LineWidth',2); 
    subplot(2,1,1); plot(Xvals,rng,'Color','r','LineWidth',2); 
    
    fprintf('{[%.3f %.3f %.3f]}\n',slope,Y(1),X(1));
    figure(167); 
    subplot(2,1,2); line(p(1)+yvals*p(2),yvals,'Color','r','LineWidth',2); 
    subplot(2,1,1); line(p(1)+yvals*p(2),yvals,'Color','r','LineWidth',2); 
    %figure(40); clf; hold on
    %plot(yvals,xv);
    %plot(yvals,p(1)+yvals*p(2));
elseif length(X)==2    
    slope=(X(end)-X(1))/(Y(end)-Y(1));
    fnstr=sprintf('@(x,y,p)p(1)*(x(%d)-p(2))+p(3)',nloop);
    scan.loops(nloop).trafofn(2).fn=str2func(fnstr);
    scan.loops(nloop).trafofn(2).args={[slope, Y(1), X(1)]};
    fprintf('{[%.3f %.3f %.3f]}\n',slope,Y(1),X(1));
    figure(167); 
    subplot(2,1,2); line(X,Y,'Color','r','LineWidth',2); 
    subplot(2,1,1); line(X,Y,'Color','r','LineWidth',2); 
else
    fnstr=sprintf('@(x,y,p,q) interp1(p,q,x(%d),''linear'',''extrap'')',nloop);
    %scan.loops(nloop).trafofn(2).fn=@(x,y,p,q) interp1(p,q,x(end),'linear','extrap');
    scan.loops(nloop).trafofn(2).fn=str2func(fnstr);
    scan.loops(nloop).trafofn(2).args{1}=Y;
    scan.loops(nloop).trafofn(2).args{2}=X;
    fprintf('fn=@(x,y,p,q) interp1(p,q,x(%d))\nargs{1}=%s\nargs{2}=%s\n',nloop,ystring,xstring);
    rng = linspace(scan.loops(nloop).rng(1), scan.loops(nloop).rng(2), scan.loops(nloop).npoints); 
    Xvals = interp1(scan.loops(nloop).trafofn(2).args{1},scan.loops(nloop).trafofn(2).args{2},rng,'linear','extrap');
    subplot(2,1,2); plot(Xvals,rng,'Color','r','LineWidth',2); 
    subplot(2,1,1); plot(Xvals,rng,'Color','r','LineWidth',2); 
end

end

