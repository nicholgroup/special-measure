function val = fplot2ppt(fig, scanfile, data, opts)
%function val = fplot2ppt(fig, scanfile, data)
%fig is figure number to be saved
%scanfile is datafile that generated figure
%data is struct with fields
%data.slidetitle
%data.comments: text to be added to slide under constants
%data.body: text to be added to slide under figure
%data.pptsavefile: ppt file to save it to, be careful of working directory
%opts can be 'noconfigvals', which will not include all of the congfigvals
%in the slide
% data.pptsavefile CANNOT be open if this is going to work.

if ~exist('opts','var')
   opts=''; 
end

if ~isempty(scanfile)
    load(scanfile, 'scan','configch','configvals'); %load all three separately, dont load data    
    
    %concatenate consts and vals
    try
        vals = scan.consts;
    catch
        vals=[];
    end
    if isempty(strfind(opts, 'noconfigval'))
        for j =1:length(configch)
            vals(end+1).setchan = configch{j};
            vals(end).val = configvals(j);
        end
    end
    slide.consts=vals;
else
    slide.consts = '';
end

slide.title = data.slidetitle;
slide.body = data.body;
slide.comments = data.comments;
slide.file=scanfile;

if exist('fig', 'var')
    qdsaveppt(data.pptsavefile,slide, ['-f' num2str(fig)]);
else
    qdsaveppt(data.pptsavefile,slide);
end