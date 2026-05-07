function [] = ana_pline( file )
%ana_pline( file )averages pline scans and plots along eps range

if ~exist('file','var')
    file=smgetfile('sm*.mat');
end

if ~iscell(file)
    file={file};
end

figure(901); clf;
fname = {};
for i=1:length(file)
    d = load(file{i});
    d.scantime = getscantime(d.scan,d.data);
    data = d.data{1};
    avgdata = nanmean(data);
    x = guessxv(d.scan.data.pulsegroups.name,d.scantime);
    
    nameind = max(strfind(file{i},'\')); 
    fname{i} = file{i}(nameind+1:end-4);
    plot(x,avgdata);
    l=legend(fname,'Interpreter','none');
    if i==1
        hold on;
    end
    
end
%xlabel('\epsilon (mV)');

% Pop up PPT dialogue 
ppt=guidata(pptplot);
set(ppt.e_file,'String',file{1});
set(ppt.e_figures,'String',['[',sprintf('%d ',901),']']);
set(ppt.e_body,'String','');
set(ppt.exported,'Value',0);

end


function xv=guessxv(grpname,scantime)
xv=plsinfo('xval',grpname,[],scantime);
dxv=sum(diff(xv,[],2),2);
[dm,di]=max(dxv);
if dm == 0
    fprintf('Warning: no xval variation\n');
    di=1; 
end
xv=xv(di,:);
end