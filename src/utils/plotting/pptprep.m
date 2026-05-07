function pptprep(opts)
% pptprep fills out the ppt plot box
% pptprep(opts) populates the ppt dialog box.
% opts is a structure with fields (all optional), or a cell array
%  opts.file
%  opts.body
%  opts.constants -- displayed under constants
%  opts.title -- defaults to beautified file name
%  opts.figures
persistent ppt;

% og_dir = pwd;
% cd(opts.path);

if iscell(opts)
  opts=struct(opts{:});
end

if ~exist('ppt','var') || isempty(ppt) || ~ishandle(ppt.figure1)
  ppt=guidata(pptplot);
end

if isfield(opts,'file')
    set(ppt.e_file,'String',opts.file);
end

if isfield(opts,'figures')
    if isa(opts.figures,'matlab.ui.Figure')
       opts.figures = [opts.figures.Number]; 
    end
    set(ppt.e_figures,'String',['[',sprintf('%d ',opts.figures),']']);
end
if isfield(opts,'body')
    set(ppt.e_body,'String',opts.body);
end
if isfield(opts,'constants')
    set(ppt.e_body,'String',opts.constants);
end

file=get(ppt.e_file,'string');
prettyfile=regexprep(file,'(sm_)|(\.mat)','');
descr=get(ppt.e_body,'string');
if isempty(descr)
    indentdescr='';
else
  for i=1:size(descr,1)
    indentdescr(i,:)= regexprep(descr(i,:),'^(.)','\t$1','lineanchors');
  end
end

if isfield(opts,'title')
    set(ppt.e_title,'String',opts.title);
else
    set(ppt.e_title,'String',prettyfile);
end

clipboard('copy',sprintf('%s\n%s\n\n',['===' prettyfile],indentdescr));
set(ppt.exported,'Value',0);

oneNotePrep(opts);
end

