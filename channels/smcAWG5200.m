function val = smcAWG5200(ico, val, rate)
% function val = smcAWG5200(ico, val, rate)
% driver for AWG5200, adapted from smcAWG5000
% not sure what's the difference between  channel 1 and 2
% 1: freq (FG mode), 2: clock (AWG mode), 3-6: CH1-4 amplitude,
% 7: jump to line (requires active sequence),
% 8-11: CH5-8 amplitude,
% 12-19 DC offset for channels 1-8,
% 20-51: MARKER 1,2 Low/High for channels 1-8
% 52-59: skew for channels 1-8
%
% Extra fields that can go into smdata.inst(x).data
%   chain    ; setting the frequency or pulseline on this instrument 'chains' to the specified instrument;
%              this allows one to seamlessly set the pulseline on many awg's together.
%   clockmult; a multiplier to be applied to any clock frequency sets on this device.
%              allows 7k and 5k to be mixed.

global smdata;

cmds = {'CLOC:SRAT', 'CLOC:SRAT', 'SOUR1:VOLT', 'SOUR2:VOLT', 'SOUR3:VOLT', 'SOUR4:VOLT', 'JUMP:FORC',...
    'SOUR5:VOLT', 'SOUR6:VOLT', 'SOUR7:VOLT', 'SOUR8:VOLT',...
    'SOUR1:VOLT:OFFS', 'SOUR2:VOLT:OFFS','SOUR3:VOLT:OFFS','SOUR4:VOLT:OFFS',...
    'SOUR5:VOLT:OFFS', 'SOUR6:VOLT:OFFS','SOUR7:VOLT:OFFS','SOUR8:VOLT:OFFS',...
    'SOUR1:MARK1:VOLT:LOW', 'SOUR1:MARK1:VOLT:HIGH', 'SOUR1:MARK2:VOLT:LOW', 'SOUR1:MARK2:VOLT:HIGH',...
    'SOUR2:MARK1:VOLT:LOW', 'SOUR2:MARK1:VOLT:HIGH', 'SOUR2:MARK2:VOLT:LOW', 'SOUR2:MARK2:VOLT:HIGH',...
    'SOUR3:MARK1:VOLT:LOW', 'SOUR3:MARK1:VOLT:HIGH', 'SOUR3:MARK2:VOLT:LOW', 'SOUR3:MARK2:VOLT:HIGH',...
    'SOUR4:MARK1:VOLT:LOW', 'SOUR4:MARK1:VOLT:HIGH', 'SOUR4:MARK2:VOLT:LOW', 'SOUR4:MARK2:VOLT:HIGH',...
    'SOUR5:MARK1:VOLT:LOW', 'SOUR5:MARK1:VOLT:HIGH', 'SOUR5:MARK2:VOLT:LOW', 'SOUR5:MARK2:VOLT:HIGH',...
    'SOUR6:MARK1:VOLT:LOW', 'SOUR6:MARK1:VOLT:HIGH', 'SOUR6:MARK2:VOLT:LOW', 'SOUR6:MARK2:VOLT:HIGH',...
    'SOUR7:MARK1:VOLT:LOW', 'SOUR7:MARK1:VOLT:HIGH', 'SOUR7:MARK2:VOLT:LOW', 'SOUR7:MARK2:VOLT:HIGH',...
    'SOUR8:MARK1:VOLT:LOW', 'SOUR8:MARK1:VOLT:HIGH', 'SOUR8:MARK2:VOLT:LOW', 'SOUR8:MARK2:VOLT:HIGH',...
    'SOUR1:SKEW', 'SOUR2:SKEW', 'SOUR3:SKEW', 'SOUR4:SKEW', 'SOUR5:SKEW', 'SOUR6:SKEW', 'SOUR7:SKEW', 'SOUR8:SKEW'};

if all(ico(2:3) == [7 0])
    cmds{7} = 'SCST';
end
if all(ico(2:3) == [7 1]) % Guarantee jump happens before return; important for trigger waits w/ multiple awgs.
    % AWG will not jump if waiting for trigger.  Pre *trg helps this.
    
    query(smdata.inst(ico(1)).data.inst,sprintf('JUMP:FORC %d;*OPC?',val));
    
%     tic
%     cmdStr=sprintf('*TRG;JUMP:FORC %d',val);
%     %cmdStr=sprintf('JUMP:FORC %d',val);
% 
%     %cmdStr=sprintf('*TRG;SOURCE1:JUMP:FORC %d',val);
% 
%     fprintf(smdata.inst(ico(1)).data.inst,cmdStr);
%     toc
%     tic
%     query(smdata.inst(ico(1)).data.inst,'*OPC?');
%     toc
    
    %   fprintf(smdata.inst(ico(1)).data.inst,sprintf('*TRG;SEQ:JUMP %d;*OPC?',val));
    %   fscanf(smdata.inst(ico(1)).data.inst);
    
    %   fprintf(smdata.inst(ico(1)).data.inst,sprintf('*TRG;SEQ:JUMP %d;*OPC?',val));
    %   good=0;
    %   while ~good
    %       good=(smdata.inst(ico(1)).data.inst.BytesAvailable>0);
    %   end
    %   fread(smdata.inst(ico(1)).data.inst,smdata.inst(ico(1)).data.inst.BytesAvailable);
    
    %JMN 2018_06_05
    % cmdstr=sprintf('*TRG;SEQ:JUMP %d',val);
    % fprintf(smdata.inst(ico(1)).data.inst,cmdstr);
    % query(smdata.inst(ico(1)).data.inst,'*OPC?');
    %pause(.05)
    
    %
    if isfield(smdata.inst(ico(1)).data,'chain') && ~isempty(smdata.inst(ico(1)).data.chain)
        ico(1)=smdata.inst(ico(1)).data.chain;
        % QHF: allow chain for different awg models, same below at line 85
        switch smdata.inst(ico(1)).device
            case 'AWG5000'
                smcAWG5000(ico,val);
            case 'AWG5200'
                smcAWG5200(ico,val);
            otherwise
                error('Unknown chained AWG, inst = %d, plesase check smdata.inst.device.', ico(1));
        end
    end
    return;
end

if any(ico(2) == [ 1 2 ])  && isfield(smdata.inst(ico(1)).data,'clockmult') && ~isempty(smdata.inst(ico(1)).data.clockmult)
    mult=smdata.inst(ico(1)).data.clockmult;
else
    mult=1;
end

switch ico(2)
    case -7;
%         switch ico(3)
%             case 1
%                 fprintf(smdata.inst(ico(1)).data.inst, sprintf('%s %f', cmds{ico(2)}, val*mult));
%                 smdata.inst(ico(1)).data.line = val;
%             case 0
%                 val = smdata.inst(ico(1)).data.line;
%             otherwise
%                 error('Operation not supported');
%         end
        
    otherwise
        switch ico(3)
            case 1
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('%s %f', cmds{ico(2)}, val*mult));
                if any(ico(2) == [ 7 1 2]) && isfield(smdata.inst(ico(1)).data,'chain') && ~isempty(smdata.inst(ico(1)).data.chain)
                    ico(1)=smdata.inst(ico(1)).data.chain;
                    switch smdata.inst(ico(1)).device
                        case 'AWG5000'
                            smcAWG5000(ico,val);
                        case 'AWG5200'
                            smcAWG5200(ico,val);
                        otherwise
                    end
                end
                if 1 && ico(2) == 2  % Make sure frequency changes are synchronus.
                    query(smdata.inst(ico(1)).data.inst, '*OPC?');
                end
            case 0
                val = query(smdata.inst(ico(1)).data.inst, sprintf('%s?', cmds{ico(2)}), '%s\n');
                val = str2double(str2num(val)); % Not sure it always works
            otherwise
                error('Operation not supported');
        end
end
