function smConfigP5023A(VNAname,cntrl)
%{ Configures P5023A USB VNA for measurements.
% Run this immediately after creating visa object to set vna to detault.
% This could also be a postfn in scans to set it to default setting after
% an experiment.
%}

% cntrl could have
%{
cntrl.clock.source
            freq: external ref frequency, default is 10 MHz; sets only if
            clock.source = 'EXT'
            source='?' returns query results
cntrl.defaultS: 0, no measurement
                1: S11
                4: 4-Sparams
%}

%e.g.
%{
smConfigP5023A(ksP5023A,struct('clock',struct('source','EXT','freq',1e6)):sets EXT ref frequency
%}

global smdata
%find object index in smdata.inst
%VNAname='VNA_KS';

if ~iscell(VNAname)
    VNAname={VNAname};
end

tmp= strcmp({smdata.inst(:).name},VNAname{1});
toolN=find(tmp);

% find control names
cntrlNames=fieldnames(cntrl); %field names
nCntrl=numel(cntrlNames); %number of the field names

% check communication
try
    query(smdata.inst(toolN).data.inst,'*IDN?');
catch
    error('%s communication error!',smdata.inst(toolN).name);
end


for k=1:nCntrl%loop over control
    %Check for completion of last operation
    counter=1;
    while ~query(smdata.inst(toolN).data.inst,'*OPC?')
        pause(1/100);%
        counter=counter+1;
        if counter>=1000
            error('OPC error \n ');
        end
    end
    
    switch cntrlNames{k}
        case 'autoTrig'
            %turns continuous trigger on
            if cntrl.autoTrig
                try
                    fprintf(smdata.inst(toolN).data.inst,'SENS:SWE:MODE CONT');
                    fprintf(smdata.inst(toolN).data.inst, 'TRIG:SOUR IMM');% Internal continuous trigger
                    fprintf(smdata.inst(toolN).data.inst, 'SENS:AVER:CLE');
                catch
                    fprintf("Can't turn trigger on\n")
                end
            else
                fprintf(smdata.inst(toolN).data.inst,'INIT:CONT OFF');% continuous trigger of
            end
            
        case 'clock' %clock
            %Auto detect presence of EXT clock source at refIn, default is  INT
            if strcmp(cntrl.clock.source,'EXT')
                try
                    %set
                    fprintf(smdata.inst(toolN).data.inst,sprintf('SENS:ROSC:SOUR:EXT:%d',cntrl.clock.freq));
                catch
                    warning('Unknown external clock frequency, using default 10 MHz\n');
                    fprintf(smdata.inst(toolN).data.inst,sprintf('SENS:ROSC:SOUR:EXT:%d',10e6));
                end
                
            end
            %return the clock source and freq for set and get i.e. ?
            %set cntrl.clock.source = '?' for query only
            cntrl.clock.source = strip(query(smdata.inst(toolN).data.inst,['SENS:ROSC',':SOUR?']));
            cntrl.clock.freq = str2double(strip(strip(query(smdata.inst(toolN).data.inst,[cmnd,':EXT:FREQ?'])), '+'));
        case 'preset'
            if cntrl.preset
                fprintf(smdata.inst(toolN).data.inst, ':SYSTem:PRESet');
            end
            
        case 'defaultS'
            if cntrl.defaultS
                %Clear the event status registers and all errors which may be in the VNA's
                %queue
                fprintf(smdata.inst(toolN).data.inst,'*CLS');
                %fprintf(ks, ':SYSTem:PRESet');
                % fprintf(smdata.inst(toolN).data.inst, ':CALCulate:PARameter:DELete:ALL'); % Delete all prior measurements on the VNA
                
                %Check to ensure the error queue is clear. Response is "+0, No Error"
                fprintf(smdata.inst(toolN).data.inst,'SYST:ERR?');
                errIdentifyStart = fscanf(smdata.inst(toolN).data.inst,'%s');
                
                %Set Trigger Mode initially to Continuous ON
                fprintf(smdata.inst(toolN).data.inst, 'INIT:CONT ON');
                
                % Delete all prior measurements on the VNA
                fprintf(smdata.inst(toolN).data.inst, ':CALCulate:PARameter:DELete:ALL');
                
                
                if cntrl.defaultS==4
                    whichS={'S11','S21','S12','S22'};%SParamToMeasure;
                else
                    whichS={'S11'};
                end
                if ~iscell(whichS)
                    whichS = {whichS};
                end
                % wInd=1; %To do: make it compatible with simultaneous measurement of multiple S parameters
                %create new windows
                for wInd=1:length(whichS)
                    fprintf(smdata.inst(toolN).data.inst,sprintf("DISPlay:WINDow%d:STATE ON",wInd));
                    
                end
                %Set 2-port measurement for S parameter
                for wInd=1:length(whichS)
                    fprintf(smdata.inst(toolN).data.inst, sprintf("CALCulate%d:PARameter:DEFine:EXT 'Meas%d','%s'", wInd, wInd,whichS{wInd}));
                end
                % feed the measurement display into trace
                for wInd=1:length(whichS)
                    CalibData=smdata.inst(toolN).data.CalibrationDataSets{ 1 }; %Calibration data set
                    %                     % CalibData='CalSet_Full_2048';
                    fprintf(smdata.inst(toolN).data.inst, sprintf( "SENSe%d:CORR:CSET:ACT '%s', 1",wInd,CalibData)); % load calibration set to channel
                    %
                    fprintf(smdata.inst(toolN).data.inst, sprintf("DISPlay:WINDow%d:TRACe%d:Feed 'Meas%d'",wInd, wInd,wInd ));
                    
                    
                end
                
            end
        otherwise
            warning('Unknown control,doing nothing\n');
            
            
            
            
    end
    
    
end