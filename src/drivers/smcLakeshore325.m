function [val, rate] = smcLakeshore325(ico, val, rate)
% driver for Lakeshore 325 power supply
% channels for this instrument are 
% 1: loop A
% 2: loop B
% 3: Setpoint A
% 4: Setpoint B
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
    case 1 %loop A
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'KRDG? A');
                val=str2double(val);
                                
            otherwise
                error('Operation not supported');
        end
        
    case 2 %loop B
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'KRDG? B');
                val=str2double(val);
                                
            otherwise
                error('Operation not supported');
        end
        
    case 3 %setpoint for loop A
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'SETP? 1');
                val=str2double(val);
                
            case 1 %set
                cmdStr=sprintf('SETP 1,%3.3f',val);
                fprintf(smdata.inst(ico(1)).data.inst,cmdStr);
        end
        
    case 4 %setpoint for loop B
        
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'SETP? 2');
                val=str2double(val);
                
            case 1 %set
                cmdStr=sprintf('SETP 2,%3.3f',val);               
                fprintf(smdata.inst(ico(1)).data.inst,cmdStr);
        end

    case 5 %heater range for loop A
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'RANGE? 1');
                val=str2double(val);
                
            case 1 %set
                cmdStr=sprintf('RANGE 1,%d',val);
                fprintf(smdata.inst(ico(1)).data.inst,cmdStr);
        end
        
    case 6 %heater range for loop B
        
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'RANGE? 2');
                val=str2double(val);
                
            case 1 %set
                cmdStr=sprintf('RANGE 2,%d',val);              
                fprintf(smdata.inst(ico(1)).data.inst,cmdStr);
        end
end
