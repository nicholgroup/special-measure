function [val, rate] = smcSR715(ic, val, rate)
% [val, rate] = smcSR715(ic, val, rate)
% 1: major parameter, 
% 2: minor parameter, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 3: Frequency
% 4: drive volt


global smdata;
ia=smdata.inst(ic(1)).data.inst;

switch ic(2) % Channel
    case 1 % major parameter
        switch ic(3)
            case 0  % get
                cmdStr='XALL?';
                str=query(ia,cmdStr);
                inds=regexp(str,'G0');
                
                if isempty(inds)
                    inds=regexp(str,'O0');
                end
                
                if isempty(inds) % 2023/12/1 JD and YFY
                    inds=regexp(str,'G2'); 
                end
                
                if isempty(inds)
                    inds = regexp(str, 'G1');
                end
                
                val=str2num(str(inds(1)+3:inds(2)-2));

            otherwise
                error('Operation not supported');
        end

    case 2 % minor parameter
        switch ic(3)
            case 0  % get
                cmdStr='XALL?';
                str=query(ia,cmdStr);
                inds=regexp(str,'G0');
                val=str2num(str(inds(2)+3:end-4));

            otherwise
                error('Operation not supported');
        end

    case 3 % Frequency
        switch ic(3)
            case 0  % get
                cmdStr='FREQ?';
                str=query(ia,cmdStr);
                val=str2num(str);
            otherwise
                error('Operation not supported');
        end


    case 4 % drive voltage
        switch ic(3)
            case 0  % get
                cmdStr='VOLT?';
                str=query(ia,cmdStr);
                val=str2num(str);
            otherwise
                error('Operation not supported');
        end

end

end
        
