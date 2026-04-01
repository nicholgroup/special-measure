function [val, rate] = smcScale(ico, val, rate)
% driver for the dewar scale
% channels for this instrument are 
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% 1: current
% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
% ramping not yet configured for this device.
global smdata;

switch ico(2) % 
    case 1 %reading
        switch ico(3)
            case 0 %get
                inst=smdata.inst(ico(1)).data.inst;
                fprintf(inst,'W\n');            
                d=fscanf(inst);
                fscanf(inst);
                ind=regexp(d,'lb');
                val=str2num(d(3:ind-1));

                
            otherwise
                error('Operation not supported');
        end
        

end
