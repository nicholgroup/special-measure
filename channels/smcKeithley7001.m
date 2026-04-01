function [val, rate] = smcKeithley7001(ico, val, rate)
% driver for Keithley 7001 switch box
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% channels for this instrument are 
% 1: state of all switches (a 40-bit number. Each bit is the state of a
% switch)
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
    case 1 %switch status
        switch ico(3)
            case 0 %get
                cmdStr='clos? (@1!1:1!40)';
                val=query(inst,cmdStr);
                val(regexp(val,','))=[];
                val(end)=[];
                val=bin2dec(val);
            case 1 %set
                %convert the integer number back to the binary array
                state=str2num(dec2bin(val)')';
                len=length(state);
                state=[zeros(1,40-len) state];
                
                %get the current state
                current=query(inst,'clos? (@1!1:1!40)');
                current=str2num(current);
                
                %if change<1, then we need to open the switch it.
                %if change>1, then we need to close it
                change=state-current;
                
                toOpen=(change==-1);
                openInds=find(toOpen);
                toClose=(change==1);
                closeInds=find(toClose);
                
                openStr='OPEN (@';
                for i=1:length(openInds)
                    openStr=[openStr '1!' num2str(openInds(i))];
                    if i<length(openInds)
                        openStr=[openStr ','];
                    end
                end
                openStr=[openStr ')'];
                
                closeStr='CLOS (@';
                for i=1:length(closeInds)
                    closeStr=[closeStr '1!' num2str(closeInds(i))];
                    if i<length(closeInds)
                        closeStr=[closeStr ','];
                    end
                end
                closeStr=[closeStr ')'];
                
                fprintf(inst,closeStr);
                fprintf(inst,openStr);
                
                
            otherwise
                error('Operation not supported');
        end
        
        
end
