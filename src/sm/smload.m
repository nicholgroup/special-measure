function [smdata] = smload(file)
%SMLOAD loads an smdata file and does some elementary error checking.  

if ~exist('file','var') || isempty(file)
    [~,~,file] = smgetfile('sm*.mat');
end

load(file);

if length(smdata.file)==length(file)
    criteria=~all(smdata.file==file);
else
    criteria=isempty(regexp(smdata.file,file));
end
if isfield(smdata,'file')
    if criteria
        error('filename mismatch. Not loading.');
    end
else
    warning('No filename found. Loading smdata anyway.')
end
end

