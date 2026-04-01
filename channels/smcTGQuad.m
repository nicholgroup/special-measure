function [val, rate] = smcTGQuad(ico, val, rate)
%Channels on the DAC are labelled 0-3
%Operational Codes
%%% '*IDN?'
%%%
%%% 'RDY?'
%%%
%%% GET: 'GET_DAC,(CHANNEL)' corresponds to smget(channel)
%%% 
%%% SET: 'SET,(CHANNEL),(VOLTAGE)' corresponds to smset(channel,voltage)
%%% 
%%% RAMP1: 'RAMP1,(CHANNEL),(INITIAL VOLTAGE),(FINAL VOLTAGE),(# of STEPS),
%%% (DELAY between STEPS)' correpsonds to smset(channel,final voltage,
%%% rate). The initial voltage is the value of whatever the DAC has already
%%% been set to. 
%%%
%%% First channel listed in set determines the number of steps to take'
%%%For example 'RAMP3, Channel1, Channel2, Channel3, Initial Voltage 1,
%%%Initial Voltage 2, Initial Voltage 3, Final Voltage 1, Final Voltage 2,
%%%Final Voltage 3, Number of Steps, Delay between Steps' this corresponds
%%%to smset([1,2,3],[V1,V2,V3],Rate]
%%% The initial voltages are obtained from GET just like for RAMP1. 
global smdata;

%JMN 2018_03_16 
%Major hack. The decadac driver interprets a negative rate as a triggered
%ramp. In this driver, case 3 is the triggered operation.
if exist('rate','var') && rate<0
    ico(3)=3;
end

if size(ico,1) ~= 1 %If trying to ramp more than one channel
    channels = ico(:,2); %pulls all the channel values from ICO
    channel = min(channels); %chooses the lowest numbered channel
    instrument = ico(:,1); %pulls the instrument number column from ICO
    instrument = mode(instrument); %pull the instrument number from the column (there should only be one instrument anyways)
    values = smdata.inst(instrument).data.valsToRamp; %pull the voltages from values array
    operation = ico(:,3); %picks the operation number array
    operation = mode(operation); %sets it to what should be one
    ico = []; %clears the ICO array
    ico = [instrument, channel, operation]; %Make a row vector so the driver can use it
    rate = smdata.inst(instrument).data.ratesToRamp(1,1); %picks the first rate given
end
switch ico(3)
    case 0 %SMGET
        channel = ico(2)-1; %DAC Channels are programmed to be 0-3, MATLAB channels are 1-4. Selects the correct channel
        val = query(smdata.inst(ico(1)).data.inst,['GET_DAC,' num2str(channel)]);
        val = str2double(val);
    case 1 %SMSET
        if  exist('rate','var') && isfinite(rate)
            if  exist('channels','var')
                nchan = length(channels);               
            else
                nchan = 1;
                channels = ico(2);
                values = smdata.inst(ico(1)).data.valsToRamp;
            end
            delay = 10; %microseconds between each step, can resolve 1uS
            stepsize = delay*rate/100000; %1V/s results in steps of 100uV
            switch nchan
                case 1 %RAMP 1
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1;
                    store = channel0+1;
                    Vf = values(1,1);
                    Vi0 = smdata.inst(ico(1)).data.vals(store);
                    steps = abs((Vf - Vi0)/stepsize);          
                    fprintf(smdata.inst(ico(1)).data.inst,['RAMP1,' num2str(channel0) ',' num2str(Vi0) ',' num2str(Vf) ',' num2str(steps) ',' num2str(delay)]);
                    smdata.inst(ico(1)).data.vals(store) = val;
                case 2 %RAMP 2
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1;
                    store0 = channel0+1;                  
                    Vi0 = smdata.inst(ico(1)).data.vals(store0);
                    Vf0 = values(1,1);
                    channel1 = smdata.channels(channels(2,1)).instchan(1,2)-1;
                    store1 = channel1+1;
                    Vi1 = smdata.inst(ico(1)).data.vals(store1);
                    Vf1 = values(2,1);
                    steps = abs((Vf0 - Vi0)/stepsize);                    
                    fprintf(smdata.inst(ico(1)).data.inst,['RAMP2,' num2str(channel0) ',' num2str(channel1) ',' num2str(Vi0) ',' num2str(Vi1) ',' num2str(Vf0) ',' num2str(Vf1) ',' num2str(steps) ',' num2str(delay)]);
                    smdata.inst(ico(1)).data.vals(store0)= Vf0;
                    smdata.inst(ico(1)).data.vals(store1) = Vf1;
                case 3 %RAMP 3
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1;
                    store0 = channel0+1; 
                    Vi0 = smdata.inst(ico(1)).data.vals(store0);
                    Vf0 = values(1,1);
                    channel1 = smdata.channels(channels(2,1)).instchan(1,2)-1;
                    store1 = channel1+1; 
                    Vi1 = smdata.inst(ico(1)).data.vals(store1);
                    Vf1 = values(2,1);
                    channel2 = smdata.channels(channels(3,1)).instchan(1,2)-1;
                    store2 = channel2+1; 
                    Vi2 = smdata.inst(ico(1)).data.vals(store2);
                    Vf2 = values(3,1);
                    steps = abs((Vf0 - Vi0)/stepsize);
                    fprintf(smdata.inst(ico(1)).data.inst,['RAMP3,' num2str(channel0) ',' num2str(channel1) ',' num2str(channel2) ',' num2str(Vi0) ',' num2str(Vi1) ',' num2str(Vi2) ',' num2str(Vf0) ',' num2str(Vf1) ',' num2str(Vf2) ',' num2str(steps) ',' num2str(delay)]);
                    smdata.inst(ico(1)).data.vals(store0) = Vf0;
                    smdata.inst(ico(1)).data.vals(store1) = Vf1;
                    smdata.inst(ico(1)).data.vals(store2) = Vf2;
                case 4 %RAMP 4
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1; %Selects the DAC Channels
                    store0 = channel0+1; 
                    Vi0 = smdata.inst(ico(1)).data.vals(store0);
                    Vf0 = values(1,1); %Determines the voltage you want
                    channel1 = smdata.channels(channels(2,1)).instchan(1,2)-1;
                    store1 = channel1+1; 
                    Vi1 = smdata.inst(ico(1)).data.vals(store1);
                    Vf1 = values(2,1);
                    channel2 = smdata.channels(channels(3,1)).instchan(1,2)-1;
                    store2 = channel2+1;
                    Vi2 = smdata.inst(ico(1)).data.vals(store2);
                    Vf2 = values(3,1);
                    channel3 = smdata.channels(channels(4,1)).instchan(1,2)-1;
                    store3=channel3+1;
                    Vi3 = smdata.inst(ico(1)).data.vals(store3);
                    Vf3 = values(4,1);
                    steps = abs((Vf0 - Vi0)/stepsize);
                    fprintf(smdata.inst(ico(1)).data.inst,['RAMP4,' num2str(channel0) ',' num2str(channel1) ',' num2str(channel2) ',' num2str(channel3) ',' num2str(Vi0) ',' num2str(Vi1) ',' num2str(Vi2) ',' num2str(Vi3) ',' num2str(Vf0) ',' num2str(Vf1) ',' num2str(Vf2) ',' num2str(Vf3) ',' num2str(steps) ',' num2str(delay)]);
                    smdata.inst(ico(1)).data.vals(store0) = Vf0;
                    smdata.inst(ico(1)).data.vals(store1) = Vf1;
                    smdata.inst(ico(1)).data.vals(store2) = Vf2;
                    smdata.inst(ico(1)).data.vals(store3) = Vf3;
            end
        else
            chan = ico(2)-1;
            fprintf(smdata.inst(ico(1)).data.inst,['SET,' num2str(chan) ',' num2str(val)]);
            store = chan+1;
            smdata.inst(ico(1)).data.vals(store) = val;
        end
    case 3 %%Trigger
                if  exist('rate','var') && isfinite(rate)
            if  exist('channels','var')
                nchan = length(channels);               
            else
                nchan = 1;
                channels = ico(2);
                values = smdata.inst(ico(1)).data.valsToRamp;
            end
            delay = 10; %microseconds between each step, can resolve 1uS
            %JMN 2018_03_20 the following is a fudge factor needed to make
            %the ramp timing correct. I am not sure why it is needed. In
            %the future, this should be fixed on the arduino code. Probably the arduino clock is not what we think it is.
            %or it could be a hard coded parameter in smdata.inst.data.
            ff=6.784*10/delay;
            stepsize = delay*1e-6*rate*ff; %1V/s results in steps of 100uV
            %stepsize=delay*rate/100000;
            switch nchan
                case 1 %RAMP 1
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1;
                    store = channel0+1;
                    Vf = values(1,1);
                    Vi0 = smdata.inst(ico(1)).data.vals(store);
                    steps = abs((Vf - Vi0)/stepsize); 
                    fprintf(smdata.inst(ico(1)).data.inst,['TRIG,RAMP1,' num2str(channel0) ',' num2str(Vi0) ',' num2str(Vf) ',' num2str(steps) ',' num2str(delay)]);
                    fscanf(smdata.inst(ico(1)).data.inst); %needed because Arduino puts "waiting for trigger" JMN
                    smdata.inst(ico(1)).data.vals(store) = val;
                case 2 %RAMP 2
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1;
                    store0 = channel0+1;                  
                    Vi0 = smdata.inst(ico(1)).data.vals(store0);
                    Vf0 = values(1,1);
                    channel1 = smdata.channels(channels(2,1)).instchan(1,2)-1;
                    store1 = channel1+1;
                    Vi1 = smdata.inst(ico(1)).data.vals(store1);
                    Vf1 = values(2,1);
                    steps = abs((Vf0 - Vi0)/stepsize);                    
                    fprintf(smdata.inst(ico(1)).data.inst,['TRIG,RAMP2,' num2str(channel0) ',' num2str(channel1) ',' num2str(Vi0) ',' num2str(Vi1) ',' num2str(Vf0) ',' num2str(Vf1) ',' num2str(steps) ',' num2str(delay)]);
                    fscanf(smdata.inst(ico(1)).data.inst); %needed because Arduino puts "waiting for trigger" JMN
                    smdata.inst(ico(1)).data.vals(store0)= Vf0;
                    smdata.inst(ico(1)).data.vals(store1) = Vf1;
                case 3 %RAMP 3
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1;
                    store0 = channel0+1; 
                    Vi0 = smdata.inst(ico(1)).data.vals(store0);
                    Vf0 = values(1,1);
                    channel1 = smdata.channels(channels(2,1)).instchan(1,2)-1;
                    store1 = channel1+1; 
                    Vi1 = smdata.inst(ico(1)).data.vals(store1);
                    Vf1 = values(2,1);
                    channel2 = smdata.channels(channels(3,1)).instchan(1,2)-1;
                    store2 = channel2+1; 
                    Vi2 = smdata.inst(ico(1)).data.vals(store2);
                    Vf2 = values(3,1);
                    steps = abs((Vf0 - Vi0)/stepsize);
                    fprintf(smdata.inst(ico(1)).data.inst,['TRIG,RAMP3,' num2str(channel0) ',' num2str(channel1) ',' num2str(channel2) ',' num2str(Vi0) ',' num2str(Vi1) ',' num2str(Vi2) ',' num2str(Vf0) ',' num2str(Vf1) ',' num2str(Vf2) ',' num2str(steps) ',' num2str(delay)]);
                    fscanf(smdata.inst(ico(1)).data.inst); %needed because Arduino puts "waiting for trigger" JMN
                    smdata.inst(ico(1)).data.vals(store0) = Vf0;
                    smdata.inst(ico(1)).data.vals(store1) = Vf1;
                    smdata.inst(ico(1)).data.vals(store2) = Vf2;
                case 4 %RAMP 4
                    channel0 = smdata.channels(channels(1,1)).instchan(1,2)-1; %Selects the DAC Channels
                    store0 = channel0+1; 
                    Vi0 = smdata.inst(ico(1)).data.vals(store0);
                    Vf0 = values(1,1); %Determines the voltage you want
                    channel1 = smdata.channels(channels(2,1)).instchan(1,2)-1;
                    store1 = channel1+1; 
                    Vi1 = smdata.inst(ico(1)).data.vals(store1);
                    Vf1 = values(2,1);
                    channel2 = smdata.channels(channels(3,1)).instchan(1,2)-1;
                    store2 = channel2+1;
                    Vi2 = smdata.inst(ico(1)).data.vals(store2);
                    Vf2 = values(3,1);
                    channel3 = smdata.channels(channels(4,1)).instchan(1,2)-1;
                    store3=channel3+1;
                    Vi3 = smdata.inst(ico(1)).data.vals(store3);
                    Vf3 = values(4,1);
                    steps = abs((Vf0 - Vi0)/stepsize);
                    fprintf(smdata.inst(ico(1)).data.inst,['TRIG,RAMP4,' num2str(channel0) ',' num2str(channel1) ',' num2str(channel2) ',' num2str(channel3) ',' num2str(Vi0) ',' num2str(Vi1) ',' num2str(Vi2) ',' num2str(Vi3) ',' num2str(Vf0) ',' num2str(Vf1) ',' num2str(Vf2) ',' num2str(Vf3) ',' num2str(steps) ',' num2str(delay)]);
                    fscanf(smdata.inst(ico(1)).data.inst); %needed because Arduino puts "waiting for trigger" JMN
                    smdata.inst(ico(1)).data.vals(store0) = Vf0;
                    smdata.inst(ico(1)).data.vals(store1) = Vf1;
                    smdata.inst(ico(1)).data.vals(store2) = Vf2;
                    smdata.inst(ico(1)).data.vals(store3) = Vf3;
            end
        else
            chan = ico(2)-1;
            fprintf(smdata.inst(ico(1)).data.inst,['TRIG,SET,' num2str(chan) ',' num2str(val)]);
            store = chan+1;
            smdata.inst(ico(1)).data.vals(store) = val;
        end
    otherwise
        error('Operation not supported')
end