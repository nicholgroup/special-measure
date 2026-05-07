function [file path fullname] = smgetfile(search_name)
% wrapper function for uigetfile that allows plotData to pull data from any
% directory by including pathname

% smgetfile takes optional argument search_name (string) which gets pushed to
% uigetfile argument varargin and should be information about the filename
% one is searching for (e.g. 'sm*Drift*.mat' will display first the files
% with these characters in their filenames)

% smgetfile returns either:
% 1. a cell array of filenames (with path) if multiple files selected or
% 2. a string of the filename (with path) of a single file selected

%JMN 2019/09/24
% this function now has three outputs. The default does not include the
% path.

if ~exist('search_name','var')
    [file, path] = uigetfile('Multiselect','on');
else
    [file, path] = uigetfile(search_name,'Multiselect','on');
end

if ~iscell(file)
    fullname = [path file];
else
   for i=1:length(file)
       fullname{i} = [path file{i}]; 
   end
end

end
