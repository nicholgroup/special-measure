function smsavechans(file)
% function smsavechans(file)
% save all channels from smdata to file.

global smdata;
channels = smdata.channels;
save(['smchan_', file], 'channels');

   