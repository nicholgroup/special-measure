function [filenames] = num2name(nums)
%num2name converts a sm file number to the full name. 
%[filenames] = num2name(nums)
%   converts a special-measure file number to the full name
%   nums is an array of file numbers
%   filenames is an array of filenames.


filenames={};
for i=1:length(nums)
    
    if iscell(nums)
        nn=nums{i};
        if isstr(nn)
            nn=str2num(nn);
        end
    else
        nn=nums(i);
    end
    filenames{i}=ls(['*_' num2str(nn) '.mat']);
end

end

