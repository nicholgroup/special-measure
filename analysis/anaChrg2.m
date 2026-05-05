function [ out ] = anaChrg2(opt, file )
%anaChrg2 loads and plots a charge scan file.
%
%anaChrg2( opt , file ) loads file and processes the data with the
%following options
% opt:
%   'add': addtion, abs(xdiffdata) + abs(ydiffdata) --> defualt option
%   'mag': magnitude, sqrt(xdiffdata.^2 + udoffdata.^2)
%   'norm': normalize, abs(xdiffdata)/max(abs(xdiffdata(:))) + abs(ydiffdata)/max(abs(ydiffdata(:)))
% 
% differences from anaChrg.m:
% 1. uses smgetfile instead of uigetfile
% 2. subplot is 1x2 instead of 2x1
% 3. more options when plotting diff data
% Conclusion: basically no reason to use anaChrg ever

if ~exist('opt','var') || isempty(opt)
    opt = 'add';
end

if ~exist('file','var')
    file=smgetfile('sm*.mat');
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
            subplot(1,2,1);
            %imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1))));
            imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1)),1,2));

            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            subplot(1,2,2);
            imagesc(xvals,yvals,squeeze(nanmean(d.data{j},1)));
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            
        elseif length(size(d.data{1}))==2
            subplot(1,2,1);
            %imagesc(xvals,yvals,diff(d.data{j}));
            xdiffdata = diff(d.data{j},1,2);
            xdiffdata = xdiffdata(1:end-1,:);
            ydiffdata = diff(d.data{j},1,1);
            ydiffdata = ydiffdata(:,1:end-1);            
            switch opt
                case 'add'
                    diffdata = sqrt(xdiffdata.^2+ydiffdata.^2);
                case 'mag'
                    diffdata = abs(xdiffdata) + abs(ydiffdata);
                case 'norm'
                    diffdata = abs(xdiffdata)/max(abs(xdiffdata(:))) + abs(ydiffdata)/max(abs(ydiffdata(:)));
                case 'max'
                    for i = 1:size(xdiffdata,1)
                        for j = 1:size(xdiffdata,2)
                            diffdata(i,j) = max(abs(xdiffdata(i,j)),abs(ydiffdata(i,j)));
                        end
                    end
            end
            %diffdata = diffdata - median(diffdata(:));
            imagesc(xvals,yvals,diffdata);
            
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);
            end
            subplot(1,2,2);
            imagesc(xvals,yvals,d.data{j});
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
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
    out(i).xdiffdata=xdiffdata;
    out(i).ydiffdata=ydiffdata
    out(i).diffdata=diffdata;
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

