function [val, rate] = smcf70(ico,val,rate)
% driver for Sumitomo f70 compressor
% channels for this instrument are 
% ico is a three element vector. 
%ico(1) is the instrument number. 
%ico(2) is the channel number. 
%ico(3) is the operation.
% 1: status
% 2: hours
% 3: presssure
% 4: Temperature (1: He 2: Water out, 3: Water in)
% operation codes are
% 0: get
% 1: set
%
% The object for this driver can be created using the serial command.
% Currently, the instrument is on COM1. Make sure the terminator is set to
% 'CR'. The other default settings should be appropriate.
global smdata;

f70s = smdata.inst(ico(1)).data.inst;

switch ico(2)
    case 1 %status on or off
        switch ico(3)
            case 0 %get
                val = compressorstatus(f70s);
            case 1 %set, can be 0 or 1
                check = compressorstatus(f70s);
                if val ~= check
                    if val == 1
                        command = '$ON177CF';
                        res1 = 'System On \n';
                        res0 = 'Check Compressor \n';
                    elseif val == 0
                        command = '$OFF9188';
                        res1 = 'System did not shut down \n';
                        res0 = 'System Off \n';
                    else
                        command = '$OFF9188';
                        res0 = 'Received value not in logic. Comp Off \n';
                        res1 = 'Received value not in logic. Comp not responding to off command \n';
                    end
                    query(f70s,command);
                    check = compressorstatus(f70s);
                    if check == 1
                        fprintf(res1)
                    elseif check == 0
                        fprintf(res0)
                    else
                        fprintf('Com error \n')
                    end
                    val = check;
                end
                
                
        end
        
    case 2 %Return operating hours
        switch ico(3)
            case 0
                command = '$ID1D629';
                val = compressorresponse(f70s,command,10,15);                
        end
        
        
    case 3 %Return He pressure
        switch ico(3)
            case 0
                command = '$PR171F6';
                val = compressorresponse(f70s,command,6,8);
        end
    case 4 %Return Temperature
        switch ico(3)
            case 1 %Helium Discharge
                command = '$TE140B8';
                val = compressorresponse(f70s,command,6,8);
            case 2 %Water outlet
                command = '$TE241F8';
                 val = compressorresponse(f70s,command,6,8);
            case 3 %Water inlet
                command = '$TE38139';            
                val = compressorresponse(f70s,command,6,8);
        end         
        
        
        
end

    
function val = compressorstatus(f70s)
    fprintf(f70s,'$STA3504');
    value = fscanf(f70s);
    value = extractBetween(value,9,9);
    val = str2double(cell2mat(value));
end

function val = compressorresponse(f70s,command,l1,l2)
    value = query(f70s,command);
    value = extractBetween(value,l1,l2);
    val = str2double(cell2mat(value));
end

end %f70
        


