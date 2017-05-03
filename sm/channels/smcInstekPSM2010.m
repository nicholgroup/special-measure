function [val, rate] = smcInstekPSM2010(ico, val, rate)
% driver for Instek PSM 2010
% channels for this instrument are 
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
    case 1 %current
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'CURR?'); 
                val=str2double(val);
            case 1 %set
                %fprintf('Setting current to %3.3f \n',val);
                fprintf(smdata.inst(ico(1)).data.inst,['CURR ' num2str(val)]);
                
                
            otherwise
                error('Operation not supported');
        end
        

end
