function [ stateDec ] = smstate2dec(state)
%[ dec ] = smstate2dec(state )
% Converts a state vector, of size 1x40, consisting of zeros and ones, into
% a decimal number. This should be used with smcKeithley7001.
binState=dec2bin(state);
binState=str2num(binState);
binState=binState';
binState=num2str(binState);
binState(regexp(binState,' '))=[];
stateDec=bin2dec(binState);

end

