function [h,ax] = sugarcoatFigv2(figInd,aspRat,multiplier)
%sugarcoatFigv2 makes a nice figure with different options than sugarcoatFig
% 
%[h,ax] = sugarcoatFigv2(figInd,aspRat,multiplier)
% arguments:
% figInd = figure number
% aspRat = aspect ratio of output figure 
% multiplier scales output figure size
% h = handle to new figure
% ax = handle to new axes

anylog = 0;

if ~exist('figInd','var') || isempty(figInd)
    figInd = get(gcf,'Number');
end
if ~exist('aspRat','var') || isempty(aspRat)
    aspRat = 4/3;
end
if ~exist('multiplier','var') || isempty(multiplier)
    multiplier = 1;
end

for k=1:length(figInd)
    %gather figure axes
    h=figure(figInd(k));
    offx = 5; offy = 2;
    width = 3.2*multiplier; height = width*aspRat*multiplier;
    ax=get(h,'children');
    if length(ax)==0
        break
    end
    
    cb_temp = ax(contains(get(ax,'type'),'colorbar'));
    ax(contains(get(ax,'type'),'colorbar'))=[];
    ax(contains(get(ax,'type'),'legend'))=[];
    ax(contains(get(ax,'type'),'text'))=[];
    set(h, 'Units', 'centimeters','position', [offx, offy, offx+width, offy+height/length(ax)]);
    ax.Units = 'centimeters';
    
    % format colorbar
    if length(cb_temp)>=1
        cb = cb_temp;
        set(cb,...
            'FontName','Arial',...
            'FontSize',10,...
            'LineWidth', 1);
        ax_pos = ax.Position;
        cb.Units = 'centimeters';
        cb_pos = get(cb,'Position');
        cb.Position = [cb_pos(1) (ax_pos(2)+ax_pos(4))/2 cb_pos(3)*2/3 cb_pos(4)/2];
        ax.Position = ax_pos;
        cb.Label.Rotation = 0;
        cb.Label.Units = 'centimeters';
        lab_pos = cb.Label.Position;
        cb.Label.Position = [lab_pos(1)*1/3 lab_pos(2)*2.5];  
    end
    
    
    
    %set axes parameters
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
    set(ax,...
        'FontName','Arial',...
        'FontSize',10,...
        'Box', 'on',...
        'TickDir', 'in',...
        'LineWidth', 1);
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