function [  ] = niceFigure(in)
% niceFigure() attempts to make a publication-quality figure. 
%[  ] = niceFigure(opts) makes a matlab figure look kind of nice
% The input argument "in" used to be the aspect ratio "asepct."
% It can either be an aspect ratio, or it can be a struct with the
% following fields aspect, fontSize, lineWidth


if ~isstruct(in)
    aspect=in;
    opts=struct();
    opts.aspect=aspect;
    opts.fontSize=12;
    opts.lineWidth=1;
else
    opts=in;
end

set(findall(gcf,'type','text'),'FontSize',opts.fontSize,'FontName','Helvetica');
set(findall(gcf,'type','axes'),'FontSize',opts.fontSize, 'FontName','Helvetica','Box','on','LineWidth',opts.lineWidth);
set(findall(gcf,'type','axes'),'FontSize',opts.fontSize,'FontName','Helvetica','LineWidth',opts.lineWidth);


%set(findall(gcf,'type','axes'),'FontSize',14,'FontName','Helvetica','Box','off','LineWidth',2);
% set(gca,'ytick',[]) ; 
% set(gca,'xtick',[]) ;

set(gcf, 'units', 'inches', 'pos', [2 2 6 6]) 
set(findall(gcf,'type','line'),'LineWidth',opts.lineWidth);

hAllAxes = findobj(gcf,'type','axes');
hLeg = findobj(hAllAxes,'tag','legend');
hColor = findobj(hAllAxes,'tag','Colorbar');

hAxes = setdiff(hAllAxes,hLeg); % All axes which are not legends
hAxes = setdiff(hAxes,hColor); % All axes which are not legends and not colorbars

for i=1:length(hAxes)
    pbaspect(hAxes(i),[opts.aspect 1 1]);
    set(hAxes(i),'YDir','norm');
end


% turn off title
%title('');
end

