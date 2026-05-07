function [h,ax] = sugarcoatFig(figInd,aspRat,fontSize,TickDir)
%sugarcoatFig(figInd,aspRat,fontSize) makes figure look nicer and returns new figure handle and axes handle
% 
% [h,ax] = sugarcoatFig(figInd,aspRat)
% arguments:
% figInd = figure number
% aspRat = aspect ratio of output figure
% fontSize = figure font size
% TickDir = axes tick direcion
% h = handle to new figure
% ax = handle to new axes

anylog = 0;

if ~exist('figInd','var') || isempty(figInd)
    figInd = get(gcf,'Number');
end

if ~exist('aspRat','var') || isempty(aspRat)
    aspRat = 4/3;
end

if ~exist('fontSize','var') || isempty(fontSize)
    fontSize = 16;
end

if ~exist('TickDir','var') || isempty(TickDir)
    TickDir = 'in';
end

for k=1:length(figInd)
    %gather figure axes
    h=figure(figInd(k));
    offx = 3; offy = 1;
    width = 3; height = width*aspRat;
    ax=get(h,'children');
    if length(ax)==0
        break
    end
    ax(contains(get(ax,'type'),'colorbar'))=[];
    ax(contains(get(ax,'type'),'legend'))=[];
    ax(contains(get(ax,'type'),'text'))=[];
    set(h, 'Units', 'inches','position', [offx, offy, offx+width, offy+height/length(ax)]);
    
    %set axes parameters
    try
        if ~strcmp(ax.XScale,'log')
            set(ax,'XMinorTick', 'off');
        else
            anylog = 1;
        end
        if ~strcmp(ax.YScale,'log')
            set(ax,'YMinorTick', 'off');
        else
            anylog = 1;
        end
    end
    set(ax,...
        'FontName','Arial',...
        'FontSize',fontSize,... % 'FontSize',16,... modified by YFY on 7/6/2023
        'Box', 'on',...
        'TickDir', TickDir,... % default as 'in'. modified by YFY on 1/6/2024
        'LineWidth', 1.5);
    if ~anylog
        set(ax,'TickLength', [0.01 0.01]);
    else 
        set(ax,'TickLength', [0.02 0.02]);
    end
    
    lines = findobj(gcf,'Type','Line');
    for i = 1:numel(lines)
        lines(i).LineWidth = 2.0;
    end
end
end