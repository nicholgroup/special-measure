function [ out ] = anaChrg( file )
%[ out ] = anaChrg( file )
%
% Loads and plots a charge scan file.

if ~exist('file','var')
    file=uigetfile('sm*.mat','MultiSelect','on');
end

if ~iscell(file)
    file={file};
end

ctab={'r' 'g' 'b' 'c' 'm' 'y' 'k'};
ctab=[ctab ctab ctab ctab];
styletab=[repmat({'-'},[1,7]),repmat({'.-'},[1,7]),repmat({'o-'},[1,7]), repmat({'*-'},[1,7])];

out=struct;
d=load(file{1});

if ~iscell(d.scan.loops(1).getchan)
    d.scan.loops(1).getchan={d.scan.loops(1).getchan};
end

for i=1:length(file)
    d=load(file{i});
    
    xvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
    yvals=linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
    for j=1:length(d.data)
        figInd=222+(i-1)*length(d.data)+(j-1);
        figure(figInd); clf;
        if length(size(d.data{j}))==3
            subplot(2,1,1);
            %imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1))));
            imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1)),1,1)); %derivative in y direction
            %imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1)),1,2)); %derivative in x direction

            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
%             colormap(gca,'parula'); % JHD 08/03/24
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            subplot(2,1,2);
            imagesc(xvals,yvals,squeeze(nanmean(d.data{j},1)));
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
%             colormap(gca,'parula');
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            
        elseif length(size(d.data{1}))==2
            subplot(2,1,1);
            %imagesc(xvals,yvals,diff(d.data{j}));
            imagesc(xvals,yvals,diff(d.data{j},1,2));

            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
%             colormap(gca,'parula'); % JHD 08/03/24
            c=colorbar;
            
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            subplot(2,1,2);
            imagesc(xvals,yvals,d.data{j});
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
%             colormap(gca,'parula');
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            
        else
            error('Unrecognized data size');
        end
        
    end
    out(i).data=d.data{1};
    out(i).diffdata=diff(d.data{j});
    out(i).xlabel=d.scan.loops(1).setchan;
    out(i).ylabel=d.scan.loops(2).setchan;
    out(i).xvals=xvals;
    out(i).yvals=yvals;
    out(i).scan=d.scan;
    
end


opts=struct();
opts.file=file{1};
opts.title='Data';
opts.figures=linspace(222,figInd,figInd-222+1);
pptprep(opts);
end

