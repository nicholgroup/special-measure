function [] = smcopy(file)
%SMCOPY copies and smdata file

if ~exist('file','var') || isempty(file)
    [~,~,file] = smgetfile('smdata*.mat');
end

load(file);

dir=uigetdir(pwd,'Select final directory');

[y,m,d] = ymd(datetime);
date_s=[num2str(y) '_' num2str(m) '_' num2str(d)];

fname=[dir '\smdata' '_' date_s '.mat'];
smdata.file=fname;
save(fname, 'smdata');

end

