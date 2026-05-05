function anaTrans()
%   JHD 24/08/02
%   Run to select a single plunger scan on sensor to get eh deravative.
%
    filename = {smgetfile()};
    d=load(filename{1});

    scans = d.scan;
    data = d.data;


    xvals=linspace(scans.loops(1).rng(1),scans.loops(1).rng(2),scans.loops(1).npoints);
    sensorMult=1;
    %diffData = sensorMult.*(diff(d{1}')')./(xvals(2)-xvals(1)); %EJC 04/13/2021
    %xDiff = (xvals(1:end-1)+xvals(2:end))/2; %EJC 04/13/2021
    diffData = sensorMult.*(gradient(data{1}')')./(xvals(2)-xvals(1));
    xDiff = xvals;

    figInd=2232;
    figure(figInd); clf;
    subplot(1,2,2); plot(xvals,data{1},'b.-');
    title('Scan'); xlabel(scans.loops(1).setchan); ylabel('Signal');
    subplot(1,2,1); plot(xDiff,diffData,'b.-');
    title('Derivative'); xlabel(scans.loops(1).setchan); ylabel('Signal');

    opts=struct();
    opts.file=filename{1};
    % opts.path=filepath{1};
    opts.body = '';
    opts.title='Data';
    opts.figures=linspace(2232,figInd,figInd-2232+1);
    pptprep(opts);
    
end