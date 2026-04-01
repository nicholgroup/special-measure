function [val, rate] = smcKeysightB2900(ic, val, rate)
% [val, rate] = smcSR715(ic, val, rate)
% 1: source (volts) 
% 2: measure (current)


global smdata;
smu=smdata.inst(ic(1)).data.inst;

switch ic(2) % Channel
    case 1 % source (volts)
        switch ic(3)
            case 0 %get
                cmdStr='MEAS? (@1)';
                str=query(smu,cmdStr);
                inds=regexp(str,',');
                val=str2num(str(1:inds(1)-1));

            case 1  % set
                cmdStr=sprintf('VOLT %f',val);
                fprintf(smu,cmdStr);

                cmdStr='MEAS? (@1)';
                str=query(smu,cmdStr);
              
            otherwise
                error('Operation not supported');
        end

    case 2 % measure
        switch ic(3)
            case 0  % get
                cmdStr='MEAS? (@1)';
                str=query(smu,cmdStr);
                inds=regexp(str,',');
                val=str2num(str(1:inds(1)-1));

            otherwise
                error('Operation not supported');
        end


end

end
        
