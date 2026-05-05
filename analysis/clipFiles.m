function [ files ] = clipFiles(fstr)
%clipFiles(fstr) copies a list of files to the clipboard.
%   This function the user to select files, and then prints them in cell array
%   format to the command line. Also copies the cell array to the
%   clipboard. This is useful when you are pasting filenames into a script
%   for further analysis.
%
%   fstr is an optional filename specifier

if ~exist('fstr','var')
    fstr='sm*.mat';
end

[files dirs]=get_files(fstr);
fprintf('{'); 
for ifile=1:size(files,2)
    fprintf('''%s''...\n',files{ifile}); 
end
fprintf('}\n');

%Now make the clipboard buffer.
clipBuffer='{';
for ifile=1:size(files,2)
    clipBuffer=sprintf('%s ''%s''...\n',clipBuffer,files{ifile});
end
clipBuffer=sprintf('%s };',clipBuffer);
clipboard('copy',clipBuffer);

end

