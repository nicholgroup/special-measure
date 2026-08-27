function [ out ] = plotData( file )
%plotData(file) attempts to nicely plot the data in a file.
% function [ out ] = plotData( file )
% file is an optional filename to plot, and out contains some processed
% data.

og_dir = pwd;

if ~exist('file','var')
    getfile_char = 'sm*.mat';
%     getfile_char = 'sm_B04_D2_B3_QD_shutoff*.mat';
    [~,~,file] = smgetfile(getfile_char);
    %file=uigetfile('sm*.mat','MultiSelect','on'); EJC: 5/3/18 replace with
    %smgetfile to be able to load from any directory
end

if ~iscell(file)
    file={file};
end

if ~file{1}(1)==0 %EJC 2019/09/05 added so if don't select file it just breaks
    
    figure(222);clf;
    figure(223);clf;
    ctab={'r' 'g' 'b' 'c' 'm' 'y' 'k'};
    ctab=[ctab ctab ctab ctab];
    styletab=[repmat({'-'},[1,7]),repmat({'.-'},[1,7]),repmat({'o-'},[1,7]), repmat({'*-'},[1,7])];
%     if length(file)<=28 % HY: 2024/10/09 increase the number of plot lines (colors)
%         ctab={'r' 'g' 'b' 'c' 'm' 'y' 'k'};
%         ctab=[ctab ctab ctab ctab];
%         styletab=[repmat({'-'},[1,7]),repmat({'.-'},[1,7]),repmat({'o-'},[1,7]), repmat({'*-'},[1,7])];
%     else
%         ctab={'r' 'g' 'b' 'c' 'm' 'y'
%         'k',"#0072BD",'#D95319','#EDB120','#7E2F8E','#77AC30','#4DBEEE','#A2142F'}
%         % Need to add name argument in the code down below where the plot
%         happens for this to work. not fixed yet. 
%         ctab=[ctab ctab ctab ctab];%14x4 plot options
%         styletab=[repmat({'-'},[1,14]),repmat({'.-'},[1,14]),repmat({'o-'},[1,14]), repmat({'*-'},[1,14])];
%     end 
    out=struct;
    d=load(file{1});

    % MAG 8/27/26: replaced all references to d.scan.loops with
    % loops_struct defined below. Added condition to accept smrunpyfile
    % output d.pyloops.
    if isfield(d, 'pyloops') && ~isempty(d.pyloops)
        loops_struct = d.pyloops;
    else
        loops_struct = d.scan.loops;
    end

    if ~iscell(loops_struct(1).getchan)
        loops_struct(1).getchan={loops_struct(1).getchan};
    end
    
    filepath = {}; filename = {}; ext = {};
    
    pulse=0;
    
    if isfield(d, 'scan') && isfield(d.scan,'data') % MAG 8/27/26 added first conditional
        if isfield(d.scan.data,'pulsegroups')
            figInd=222;
            figure(figInd); clf;
            imagesc(squeeze(nanmean(d.data{1})));
            set(gca,'YDir','norm');
            colorbar;
            pulse=1;
            i=1;
            
            [filepath{i}, filename{i}, ext{i}] = fileparts(file{i});
            
            out=d;
        end
    end
    
    if size(d.data{1},2)==1 || size(d.data{1},1)==1 && ~pulse%1D dataset
        for i=1:length(file)
            d=load(file{i});
            
            [filepath{i}, filename{i}, ext{i}] = fileparts(file{i});
            if ~iscell(loops_struct(1).getchan)
                loops_struct(1).getchan={loops_struct(1).getchan};
            end
            
            figInd=222;
            for j=1:length(loops_struct(1).getchan)
                figure(figInd+j-1);
                
                xvals=linspace(loops_struct(1).rng(1),loops_struct(1).rng(2),loops_struct(1).npoints);
                yvals=(d.data{j});
                plot(xvals,yvals,[ctab{i} styletab{i}],'DisplayName',file{i});
                hold on;
                %JMN 2020_08_04 changed out.xvals and out.yvals to cells.
                %This will probably break some stuff.
                %JMN 2022_08_19 I hate myself
                out(i).xvals=xvals;
                out(i).yvals{j}=yvals;
                out(i).filename = filename{i}; %added out.filename 2021_5_3 XXC
                
                l=legend(filename,'Interpreter','none');
                %JMN added cell check and strjoin
                if ~iscell(loops_struct(1).setchan)
                    loops_struct(1).setchan={loops_struct(1).setchan};
                end
                xlabel(strjoin(loops_struct(1).setchan,','),'Interpreter','none');
                if ~iscell(loops_struct(1).getchan)
                    ylabel(loops_struct(1).getchan);
                else
                    ylabel(loops_struct(1).getchan{j});
                end
            end
                        
            legend('Location','best'); %EJC 2019/09/23
    
            
            
        end
        
        %     l=legend(file,'Interpreter','none');
        %     xlabel(loops_struct(1).setchan);
        %     ylabel(loops_struct(1).getchan{j});
        
    elseif size(d.data{1},2)>1 && ~pulse
        
        for i=1:length(file)
            d=load(file{i});
            
            [filepath{i}, filename{i}, ext{i}] = fileparts(file{i});
            figInd=222+i-1;
            figure(figInd); clf;
            xvals=linspace(loops_struct(1).rng(1),loops_struct(1).rng(2),loops_struct(1).npoints);
            yvals=linspace(loops_struct(2).rng(1),loops_struct(2).rng(2),loops_struct(2).npoints);
            if length(size(d.data{1}))==3
                imagesc(xvals,yvals,squeeze(nanmean(d.data{1},1)));
            elseif length(size(d.data{1}))==2
                imagesc(xvals,yvals,d.data{1});
            else
                error('Unrecognized data size');
            end
            out(i).data=d.data{1};
            out(i).xvals=xvals;
            out(i).yvals=yvals;
            %JMN add cell checking and strjoin
            if ~iscell(loops_struct(1).setchan)
                loops_struct(1).setchan={loops_struct(1).setchan};
            end
            xlabel(strjoin(loops_struct(1).setchan,','),'Interpreter','none');
            if ~iscell(loops_struct(2).setchan)
                loops_struct(2).setchan={loops_struct(2).setchan};
            end
            ylabel(strjoin(loops_struct(2).setchan,','),'Interpreter','none');
            title(filename{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
            ylabel(c,loops_struct(1).getchan);
        end
    end
    
    try
    cd(filepath{1});
    end
    
    opts=struct();
    opts.file=filename{1};
    % opts.path=filepath{1};
    opts.body = '';
    opts.title='Data';
    opts.figures=linspace(222,figInd,figInd-222+1);
    pptprep(opts);
    cd(og_dir);
end

end
