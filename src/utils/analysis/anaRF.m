function [out] = anaRF(files,plt)
%anaRF(file1,file2) analyzes 2 RFA or RFB scans to determine optimum frequency/phase
%   files should be cell of two (2) RFA or RFB scans that mimic RF performance.
%   e.g. one file should be scan RFA with current full on and the other
%   file should be scan RFA or RFB with current pinched off using RF associated
%   plunger gate. Both files should have the same scan ranges
%
%   anaRF just subtracts the two scans and looks for highest sensitivity
%   point

if ~exist('files','var')
    [~,~, files]=smgetfile('sm*scanRF*.mat');
end

if ~exist('plt','var')
    plt=1;
end

if ~iscell(files)
    files={files};
end

if length(files)<2 %hack to allow function to analyze just a single RF scan
    files{2} = files{1};
    single = 1;
else
    single = 0;
end

%analyze

d1 = load(files{1});
d2 = load(files{2});

delta = abs(d1.data{1}-d2.data{1});

maximum = max(max(delta));
if ~single
    [yi,xi]=find(delta==maximum);
else
    yi = [];
    xi = [];
end

%plot

xrng = d1.scan.loops(1).rng;
xpts = d1.scan.loops(1).npoints;
x = linspace(xrng(1), xrng(2), xpts);
xlab = d1.scan.loops(1).setchan;

yrng = d1.scan.loops(2).rng;
ypts = d1.scan.loops(2).npoints;
y = linspace(yrng(1), yrng(2), ypts);
ylab = d1.scan.loops(2).setchan;

f1ind = max(strfind(files{1},'\'));
f2ind = max(strfind(files{2},'\'));
f1short = files{1}(f1ind+1:end-4);
f2short = files{2}(f2ind+1:end-4);


if plt
    % plot results
    figure(111); clf;
    colormap('viridis');  % JHD 06/16/24: this looks better!
    
    subplot(2,3,1);
    imagesc(x,y,d1.data{1}); hold on;
    scatter(x(xi),y(yi),100,'r*');
    set(gca,'YDir','Normal');
    xlabel(xlab);
    ylabel(ylab);
    title(['Scan: ' f1short(end-3:end)]);
    colorbar;
    
    subplot(2,3,2);
    imagesc(x,y,d2.data{1}); hold on;
    scatter(x(xi),y(yi),100,'r*');
    set(gca,'YDir','Normal');
    xlabel(xlab);
    ylabel(ylab);
    title(['Scan: ' f2short(end-3:end)]);
    colorbar;
    
    subplot(2,3,3);
    imagesc(x,y,delta); hold on;
    scatter(x(xi),y(yi),100,'r*');
    set(gca,'YDir','Normal');
    xlabel(xlab);
    ylabel(ylab);
    title(['|' f1short(end-3:end) '-' f2short(end-3:end) '|']);
    colorbar;
    
    subplot(2,3,4);
    plot(y,range(d1.data{1},2),'ko-'); hold on;
    if ~single
        plot([y(yi) y(yi)],[min(range(d1.data{1},2)) max(range(d1.data{1},2))],'r--');
    end
    set(gca,'YDir','Normal');
    xlim([min(y) max(y)]);
    xlabel(ylab);
    ylabel('S11 proxy');
    title(['Scan: ' f1short(end-3:end)]);
    
    subplot(2,3,5);
    plot(y,range(d2.data{1},2),'ko-'); hold on;
    if ~single
        plot([y(yi) y(yi)],[min(range(d2.data{1},2)) max(range(d2.data{1},2))],'r--');
    end
    set(gca,'YDir','Normal');
    xlim([min(y) max(y)]);
    xlabel(ylab);
    ylabel('S11 proxy');
    title(['Scan: ' f2short(end-3:end)]);
    
    subplot(2,3,6);
    plot(y,range(d1.data{1},2),'b','DisplayName',f1short(end-3:end)); hold on;
    plot(y,range(d2.data{1},2),'g','DisplayName',f2short(end-3:end));
    plot(y,range(delta,2),'k','DisplayName',['|' f1short(end-3:end) '-' f2short(end-3:end) '|']);
    if ~single
        plot([y(yi) y(yi)],[min(range(delta,2)) max(range(delta,2))],'r--','HandleVisibility','off');
    end
    set(gca,'YDir','Normal');
    xlim([min(y) max(y)]);
    xlabel(ylab);
    ylabel('S11 proxy');
    legend('Location','best');
    %title(['|' f1short(end-3:end) '-' f2short(end-3:end) '|']);
end

opts=struct();
opts.file=files{1};
opts.body = sprintf('Scan 1:  %s \n Scan 2: %s \n Frequency=%0.1f MHz\n Phase=%0.4f V\n Delta=%0.4f V', f1short,f2short,y(yi)*1e-6,x(xi),maximum);
opts.title='On/off RF scans';
opts.figures=[111];
pptprep(opts);

%sprintf('Set %s to %d and %s to %d',xlab,x(xi),ylab,y(yi))

out.Freq = y(yi);
out.Phase = x(xi);
out.Delta = maximum;





end

