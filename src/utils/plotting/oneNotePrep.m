function [] = oneNotePrep(opts)
%ONENOTEPREP prepares figures for pasting to one note. 
%   This function adds text to each figure to indicate the filename. Then,
%   it raises the first figure and copies it to the clipboard. The input
%   struct is the same as for pptprep.


fontSize=8; %in points. Each point is 1/72 of an inch.
pixelsPerLine=fontSize/72*96*1.4; %1.4 is a fudge factor. 
%Each pixel is 1/96 of an inch on windows and 1/72 of an inch on a mac`

if isfield(opts,'figures')
    if isa(opts.figures,'matlab.ui.Figure')
        opts.figures = [opts.figures.Number];
    end
    
    figure(opts.figures(1));
    %Copy the figure. I don't know of a better way to do this.
    savefig('fig_tmp');
    openfig('fig_tmp');
    
    f1=gcf;
    set(f1,'Units','pixels');
  
    if ~isfield(opts,'file')
        opts.file=[];
    end

    if ~isempty(opts.file)
        if ~endsWith(opts.file, '.mat')
            opts.file = [opts.file '.mat'];
        end
    end
    
    if ~isfield(opts,'body')
        opts.body=[];
    end
    
    %Load the scan file, and pull out consts and configchans
    try
        load(opts.file, 'scan','configch','configvals'); %load all three separately, don't load data
    catch %catch cases where file is empty, or it's not an smdata file.
        configch={};
    end
    
    g1={};
    for j =1:length(configch)
        val=configvals(j);
        chan=configch{j};
        if val < 1e6
            g1{j}=[chan sprintf('\t%s ','=') num2str(val)];
        else
            g1{j}=[chan sprintf('\t%s ','=') sprintf('%4e',val)];
        end
        
    end
    
    g=strjoin(g1,'\n');
    nlinesc=length(regexp(g,'\n'))+2; %number of lines for the configchans
    
    if isempty(opts.file)
        str=opts.body;
    elseif isempty(opts.body)
        str=opts.file;
    else
        str=strjoin({opts.file,opts.body},'\n');
    end
    nlines=length(regexp(str,'\n'))+2; %add some extra lines for the file+body
    
    %resize the figure and add the annotations.    
    fPos=f1.Position;
    ex1=nlinesc*pixelsPerLine-fPos(4); %how much we would need to extend the bottom for the configchans
    ex2=nlines*pixelsPerLine; %how much we need to extend the bottom for the file and body text
    if ~isempty(g)
        resizeFig(0,150,max([ex1,ex2]),0); %resize on the left and bottom.
        dim = [180 0 10 max([ex1-ex2,ex2])];
        annotation('textbox','Units','pixels','Position',dim,'String',str,'Interpreter','none','FontSize',fontSize,'FitBoxToText','on');
        %Switch back to normalized units for the configchans, because it's
        %easier to place them at the top of the figure this way.
        dim = [0 .85 .1 .1];
        annotation('textbox','Units','normalized','Position',dim,'String',g,'Interpreter','none','FontSize',fontSize,'FitBoxToText','on');
    else
        resizeFig(0,0,ex2,0);
        dim = [0 0 2 ex2];
        annotation('textbox','Units','pixels','Position',dim,'String',str,'Interpreter','none','FontSize',fontSize,'FitBoxToText','on');
    end
    
    figure(f1);
    hLegend = findobj(gcf, 'Type', 'Legend');
    % JHD, by default, the legend position always be best. 2025/6/13
    % if ~isempty(hLegend)
    %     for iL=1:length(hLegend)
    %         hLegend(iL).Location='southwest'; % 'Best' is not the best, JHD 05/18/24%this is copied from plotData. Somehow the figure resizing messes up the legend positioning.
    %     end
    % end
    print -clipboard -dbitmap -r75
    close(f1);  
    
end

end

