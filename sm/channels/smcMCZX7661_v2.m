function val = smcMCZX7661_v2(ico,val,~)
    %function val = smcMCZX7661_v2(ico,val,~)
    % control minicircuits digital step attenuators with Jim's digital IO
    % smdata.inst(xx).data should have:
        % inst: the usual com object to the digital io box
        % pause: the time to pause with the latch high on the step atten
        % config: struct array with fields:
        %     atten: attenuation of each line
        %     line: e.g. 'port0/line2' on the USB device
        %     val: 0 for off, 1 for on
        % latch: the line attached to the latch of the step attenuator
    % the board doesn't allow reading the values, so the values are always
    % cached in smdata.inst(xx).data.config.val
    % ico(3) = 0: read
    % ico(3) = 1: set
    % ico(3) = 4; configure things as outputs on the box

   global smdata;
   if ico(2)~=1
       error('channel must be = 1');
   end
    switch ico(3)
       case 0
           val = sum([smdata.inst(ico(1)).data.config().val].*[smdata.inst(ico(1)).data.config().atten]);
       case 1
           % TODO: see if val is inside of allowed range, if not, peg it
           if val > sum(ones(size(smdata.inst(ico(1)).data.config())).*[smdata.inst(ico(1)).data.config().atten])
              val =  sum(ones(size(smdata.inst(ico(1)).data.config())).*[smdata.inst(ico(1)).data.config().atten]);
           end
           if val < min([smdata.inst(ico(1)).data.config.atten])
              val = 0; 
           end
           % TODO: find the values for the bits of the step attenuator
           % this should be robust to not having them in order
           bits = false(1,length(smdata.inst(ico(1)).data.config));
           [attens, ii]=sort([smdata.inst(ico(1)).data.config.atten],'descend');
           for j = 1:length(attens)
               if j==1
                  bits(j)= (val>attens(j)); 
               else
                   bits(j) = (val-bits(1:j-1)*attens(1:j-1)')>=attens(j);
               end
           end
           bits = bits(ii);
           for j= 1:length(bits)
              smdata.inst(ico(1)).data.config(j).val = bits(j); 
           end
           %TODO: set latch low, set bits correct, set latch high, pause,
           %set latch low
           query(smdata.inst(ico(1)).data.inst,sprintf('L%i;',smdata.inst(ico(1)).data.latch));
           for j = 1:length(bits)
               if bits(j)
                    query(smdata.inst(ico(1)).data.inst,sprintf('H%i;',smdata.inst(ico(1)).data.config(j).line)); % set to high
               else
                   query(smdata.inst(ico(1)).data.inst,sprintf('L%i;',smdata.inst(ico(1)).data.config(j).line)); % set to low
               end
           end
           query(smdata.inst(ico(1)).data.inst,sprintf('H%i;',smdata.inst(ico(1)).data.latch));
           pause(smdata.inst(ico(1)).data.pause);
           query(smdata.inst(ico(1)).data.inst,sprintf('L%i;',smdata.inst(ico(1)).data.latch));
        
        case 4 % configure the lines and latch as outputs
            for j = [[smdata.inst(ico(1)).data.config.line],smdata.inst(ico(1)).data.latch]
               query(smdata.inst(ico(1)).data.inst,sprintf('O%i;',j)); 
            end
    
            
       otherwise
            error('operation not supported');
   end
end
