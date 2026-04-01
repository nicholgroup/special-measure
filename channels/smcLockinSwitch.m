function [val, rate] = smcLockinSwitch(ico, val, rate)
% driver for Keithley switch box + lockin
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% channels for this instrument are 
% 1: group 1
% 2: group 2, 
% etc
% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
% ramping not yet configured for this device.
global smdata;
inst=smdata.inst(ico(1)).data.inst;

switch ico(2) %
    case 1 
        switch ico(3)
            case 0 %get
                %set switches
                %get lockin

            otherwise
                error('Operation not supported');

        end
        
    case 2
    case 3
        
        
end
