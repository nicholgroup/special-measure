function anaTransport()
%   JHD 24/08/02
%   Run to select a 2D sensor TP to get the deravative. Different from 1D
%   anaTrans
%   axis: int 
%       Default is 1. indicate which axis of the scan loops will be take
%       gradient
    filename = {smgetfile()};
    d=load(filename{1});
    dsz = size(d.data{1});
    ddim = length(dsz(dsz>1));
    sensorMult=1;
    if ddim==1
        scans = d.scan;
        data = d.data;
        xvals=linspace(scans.loops(1).rng(1),scans.loops(1).rng(2),scans.loops(1).npoints);
        %diffData = sensorMult.*(diff(d{1}')')./(xvals(2)-xvals(1)); %EJC 04/13/2021
        %xDiff = (xvals(1:end-1)+xvals(2:end))/2; %EJC 04/13/2021
        FY =gradient(data{1}');
        diffData = sensorMult.*(FY')./(xvals(2)-xvals(1));
        xDiff = xvals;

        figInd=2232;
        figure(figInd); clf;
        subplot(1,2,2); plot(xvals,data{1},'b.-');
        title('Scan'); xlabel(scans.loops(1).setchan); ylabel('Signal');
        subplot(1,2,1); plot(xDiff,diffData,'b.-');
        title('Derivative'); xlabel(scans.loops(1).setchan); ylabel('Signal');
    else
        i=1;
        xvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
        yvals=linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
        [FX, FY] =gradient(d.data{1}');
        diffData = sensorMult.*(FY')./(xvals(2)-xvals(1));
        xDiff = xvals;
        
        figInd=2232;
        figure(figInd); clf;
        subplot(1,2,2);
        if length(size(d.data{1}))==3
            imagesc(xDiff,yvals,squeeze(nanmean(diffData,1)));
        elseif length(size(d.data{1}))==2
            imagesc(xDiff,yvals,diffData);
        else
            error('Unrecognized data size');
        end
        out(i).data=diffData;
        out(i).xvals=xDiff;
        out(i).yvals=yvals;
        %JMN add cell checking and strjoin
        if ~iscell(d.scan.loops(1).setchan)
            d.scan.loops(1).setchan={d.scan.loops(1).setchan};
        end
        xlabel(strjoin(d.scan.loops(1).setchan,','),'Interpreter','none');
        if ~iscell(d.scan.loops(2).setchan)
            d.scan.loops(2).setchan={d.scan.loops(2).setchan};
        end
        ylabel(strjoin(d.scan.loops(2).setchan,','),'Interpreter','none');
        title(filename{i},'Interpreter','none');
        set(gca,'YDir','norm');
        c=colorbar;
        ylabel(c,d.scan.loops(1).getchan);
        
        subplot(1,2,1);
        if length(size(d.data{1}))==3
            imagesc(xvals,yvals,squeeze(nanmean(d.data{1},1)));
        elseif length(size(d.data{1}))==2
            imagesc(xvals,yvals,d.data{1});
        else
            error('Unrecognized data size');
        end
        out(i+1).data=d.data{1};
        out(i+1).xvals=xvals;
        out(i+1).yvals=yvals;
        %JMN add cell checking and strjoin
        if ~iscell(d.scan.loops(1).setchan)
            d.scan.loops(1).setchan={d.scan.loops(1).setchan};
        end
        xlabel(strjoin(d.scan.loops(1).setchan,','),'Interpreter','none');
        if ~iscell(d.scan.loops(2).setchan)
            d.scan.loops(2).setchan={d.scan.loops(2).setchan};
        end
        ylabel(strjoin(d.scan.loops(2).setchan,','),'Interpreter','none');
        title(filename{i},'Interpreter','none');
        set(gca,'YDir','norm');
        c=colorbar;
        ylabel(c,d.scan.loops(1).getchan);
        
    end

opts=struct();
opts.file=filename{1};
% opts.path=filepath{1};
opts.body = '';
opts.title='Data';
opts.figures=linspace(2232,figInd,figInd-2232+1);
pptprep(opts);
end