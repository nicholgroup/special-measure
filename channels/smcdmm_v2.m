function [val, rate] = smcdmm(ico, val, rate)
% driver for Agilent DMMs with support for buffered readout. 
% Some instrument and mode dependent parameters hardcoded!
% For Keithley 2000 DMM, measurement rate is in power line cycles, and
% filtering is in number of averages.
global smdata;

switch ico(2) % channel
    case 1
        switch ico(3)
            case 0 %get
                val = query(smdata.inst(ico(1)).data.inst,  'FETCH?', '%s\n', '%f');
            otherwise
                error('Operation not supported');
        end
        
    case 2
        switch ico(3)
            case 0
                % this blocks until all values are available
                %val = sscanf(query(smdata.inst(ico(1)).data.inst,  'INIT?'), '%f,')';
                val = sscanf(query(smdata.inst(ico(1)).data.inst,  'FETCH?'), '%f,')';

            case 3 %trigger
                %trigger(smdata.inst(ico(1)).data.inst);                
                fprintf(smdata.inst(ico(1)).data.inst, 'INIT');

            case 4 % arm instrument
                %fprintf(smdata.inst(ico(1)).data.inst, 'INIT'); 
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR IMM');

                
            case 5 % configure instrument       
                
                time=1/rate;
                
                
                fprintf(smdata.inst(ico(1)).data.inst, 'INIT:CONT OFF;:ABORT');
                fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:NPLC 1'); %integrate 1 power line cycle
                fprintf(smdata.inst(ico(1)).data.inst, 'SENS:VOLT:DC:AVER:STAT OFF');

                fprintf(smdata.inst(ico(1)).data.inst,'FORM:ELEM READ');

                samptime=1/44; %assuming nplc =1, 50 Hz.
                
                %samptime = .04225; %34401A 20 ms integration time
                %samptime = .035; % %34401A 16.7 ms integration time
                %samptime = .4025; %34401A 200 ms
                 
                if 1/rate < samptime
                    trigdel = 0;
                    rate = 1/samptime;
                else
                    trigdel = 1/rate - samptime;
                end

                if val > 512 % 50000 for newer model
                    error('More than allowed number of samples requested. Correct and try again!\n');
                end
                
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:COUN 1');
                fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:COUN %d', val);
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:DEL %f', trigdel);
                smdata.inst(ico(1)).datadim(2, 1) = val;
                
            otherwise
                error('Operation not supported');
        end
end
dims = size(val);
if dims(1)>dims(2)
    val = val';
end
