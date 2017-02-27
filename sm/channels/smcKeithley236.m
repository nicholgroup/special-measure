function [val, rate] = smcdmm(ico, val, rate)
% driver for Keithley 236 source meter
% channels for this instrument are 
% 1: source (usually V)
% 2: measure (usually I)
% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
% ramping not yet configured for this device.
global smdata;

switch ico(2) % channel
    case 1 %source, usually voltage
        switch ico(3)
            case 0 %get
                val=query(smdata.inst(ico(1)).data.inst,'H0X'); %send trigger. The instrument must be configured first.
                k = strfind(val,',');
                val=str2double(val(1:k-1));
            case 1 %set
                fprintf(smdata.inst(ico(1)).data.inst,['B' num2str(val) ',0,0X']);
                
                
            otherwise
                error('Operation not supported');
        end
        
    case 2 %measure, usually current
        switch ico(3)
            case 0
                % get
                val=query(smdata.inst(ico(1)).data.inst,'H0X'); %send trigger. The instrument must be configured first.
                k = strfind(val,',');
                val=str2double(val(k+1:end));
                
             case 1 %set
                error('Operation not supported');
                                
            otherwise
                error('Operation not supported');
        end
end
