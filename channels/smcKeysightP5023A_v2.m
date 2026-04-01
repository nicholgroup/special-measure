function [val] = smcKeysightP5023A_v2(ico, val)
%2022/4/24 YPK: 
% Driver for Keysight P5023A USB VNA
% ico(1) is the instrument number
% ico(2) is the channel number
% ico(3) is the controlling function

% ico(2) (channel) includes:
%{
 1. S11 
 2. S21 
 3. S12
 4. S22
 5. frequencyGrid (Hz)
 6. starting frequency (Hz), 
 7. stop frequency (Hz)
 8. number of points
 9. power output (dBm)
 10. IF bandwidth (Hz)
 11. Number of averaging
12. Electrical delay (S)
%} 


% ico(3) includes:
%{
% 0. get
% 1. set
% TO DO: add the following capability
% 2. get buffered data
% 3. trigger
% 4. arm
% 5. configure
%}

%To do: add trigger, default is internal, put S params on different
%channels and windows
% Updates:
%{
%}

global smdata

% below is equivalent to smdata.inst(4).data.inst
ks=smdata.inst(ico(1)).data.inst;

%check completion of task before passing next command
maxItr=100;
itr=1;
while ~query(ks, '*OPC?')
    pause(0.1)
    itr=itr+1;
    if itr>maxItr
        error('KS-VNA is busy even after %0.2s \n', 0.1*maxItr)
    end
    
end

opc=sscanf(query(ks, '*OPC?'), '%d');

switch ico(2)
    case {1,2, 3, 4} % S11 and S21 params
        sparams={'S11','S21','S12','S22'};
        ind=ico(2);
        switch ico(3)
            case 0 % get
                
                %configure measurement
                configureVNA(ks,sparams{ico(2)}) ;
                
                %trigger
                triggeredSweeps=0; %0 for continuous and 1 for triggered measurement
                %To do: configure the triggered measurement set up
                % is cont is off, either need to have ext trigger or need
                % to soft-trig for averCount times
                % armVNA(ks,triggeredSweeps)
                if smdata.inst(ico(1)).data.useCal>0 %useCal>1 is calSet number
                    CalibData=smdata.inst(ico(1)).data.CalibrationDataSets{ smdata.inst(ico(1)).data.useCal }; %Calibration data set
                    % CalibData='CalSet_Full_2048';
                    fprintf(ks, sprintf( "SENS:CORR:CSET:ACT '%s', 1",CalibData )); % load calibration set to channel 1
                end
                try
                    smset('eDelay_KS',smdata.inst(ico(1)).data.delay);
                end
                cmnd='CALC:DATA? SDATA';%replace SDATA by FDATA to get what is displayed on the screen
                val = readVNA(ks,cmnd);
                val = val(1:2:end) + 1i.*val(2:2:end);%
                % Turn off averaging
                %fprintf(ks,'SENS:AVER OFF');
                %'Turn continuous sweep ON
                %fprintf(ks, "INITiate:CONTinuous ON");
                %fprintf(ks, 'TRIG:SOUR IMM');%
        end
        
    case 5 % frequency grid
        AverVal = str2double(strip(strip(query(ks,'SENS:AVER:COUN?')), '+'));
        if AverVal>1
            %Set group count
            fprintf(ks, 'SENS:SWE:GRO:COUN %d', 1);
            %Set average count, should match group count above
            fprintf(ks,'SENS:AVER:COUN %d',1);
        end
        switch ico(3)
            %first set number of averaging to 1 and re-set it later
            
            %assumes S11 or S21 was measured before calling this
            case 0 % get
               % fprintf('ReadingFreqGrid\n')
                cmnd='SENSE:X?';%replace SDATA by FDATA to get what is displayed on the screen
                val = readVNA(ks, cmnd);
                
                %convert string into floating point
                if  ischar(val)
                    val =str2double(val);
                end
        end
        %set back averaging number
        if AverVal>1
            %Set group count
            fprintf(ks, 'SENS:SWE:GRO:COUN %d', AverVal);
            %Set average count, should match group count above
            fprintf(ks,'SENS:AVER:COUN %d',AverVal);
        end
    case 6 % starting frequency
        switch ico(3)
            case 0 % get
                
                val=query(ks, sprintf('SENSe:FREQuency:STARt?'));
                %convert string into floating point
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                    fprintf(ks, sprintf('SENSe:FREQuency:STARt %2.4f', val) ); % starting frequency
                    %fwrite(ks, "SENS:FREQ:STAR 'val'");
                    
                else
                    error('wrong frequency settings');
                end
                
        end
        
    case 7 % stop frequency
        switch ico(3)
            case 0 % get
                
                val=query(ks, sprintf('SENSe:FREQuency:STOP?'));
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                    fprintf(ks,sprintf('SENSe:FREQuency:STOP %2.4f', val));% STOP frequency
                    %fwrite(ks, "SENS:FREQ:STOP 'val'");
                    
                else
                    error('wrong frequency settings');
                end
                
        end
        
    case 8 % number of points
        
        switch ico(3)
            case 0 % get
                
                val=query(ks, sprintf('SENSe:SWEep:POINts?'));
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                    fprintf(ks, sprintf('SENSe:SWEep:POINts %d',val) ); % set the number of points
                    %fwrite(ks, "SENSe:SWEep:POINts 'val'");
                    
                else
                    error('wrong points settings');
                end
                
        end
    case 9 % output power level
        switch ico(3)
            case 0 % get
                
                val=query(ks, 'SOUR:POW?');
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                fprintf(ks, sprintf('SOUR:POW %d',val));
                   % fprintf(ks, sprintf('OUTP ON')); % Turn on RF power
                %set power slope to 0
                fprintf(ks, 'SOUR:POW:SLOP 0');

        end
        
    case 10 % IF bandwidth in Hz-> controls scan speed and noise level
        
        switch ico(3)
            case 0 % get
                %fprintf(visastr, sprintf('SENSe1:BWIDth:RESolution %g', 100.0)); % IF bandwidth
                val=query(ks, sprintf('SENSe1:BWIDth:RESolution?'));
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                    fprintf(ks, sprintf('SENSe1:BWIDth:RESolution %g', val)); % IF bandwidth
                    
                    
                else
                    error('wrong points settings');
                end
                
        end
        
    case 11 % number of averaging
        switch ico(3)
            case 0 % get
                val = str2double(strip(strip(query(ks,'SENS:AVER:COUN?')), '+'));
            case 1  %set
                %Set group count
                fprintf(ks, 'SENS:SWE:GRO:COUN %d', val);
                %Set average count, should match group count above
                fprintf(ks,'SENS:AVER:COUN %d',val);
                
                %                 %Turn averaging ON
                %                 fprintf(ks,'SENS:AVER ON');
                %                 fprintf(ks, 'TRIG:SOUR IMM');%
                %                 fprintf(ks,'INIT:CONT ON');% continuous trigger on
                
                %Clear and restart averaging
                fprintf(ks, 'SENS:AVER:CLE');
                
                
        end
        
        %check completion of task before returning values
        maxItr=100;
        itr=1;
        while ~query(ks, '*OPC?')
            pause(0.1)
            itr=itr+1;
            if itr>maxItr
                error('KS-VNA is busy even after %0.2s\n', 0.1*maxItr)
            end
            
        end
        % Error Check...
        count = sscanf(query(ks, ':SYSTem:ERRor:COUNt?'), '%d');
    case 12 % Electrical Delay
        %because SPCI could only access corrected data on display
        %with this, one could get raw data and correct the delay 
        switch ico(3)
            case 0 % get
                val = str2double(strip(strip(query(ks,'CALC:MEAS:CORR:EDEL:TIME?')), '+'));
            case 1  %set
                %Set electrical delay
                fprintf(ks, 'CALC:MEAS:CORR:EDEL:TIME %fNS', val*1e9);                  
        end
        
        %check completion of task before returning values
        maxItr=100;
        itr=1;
        while ~query(ks, '*OPC?')
            pause(0.1)
            itr=itr+1;
            if itr>maxItr
                error('KS-VNA is busy even after %0.2s\n', 0.1*maxItr)
            end
            
        end
        % Error Check...
        count = sscanf(query(ks, ':SYSTem:ERRor:COUNt?'), '%d');
      query(ks, '*OPC?');  
end

end
function configureVNA(ks, SParamToMeasure, averCount)
% Prepare VNA for frequency sweep of the S-Parameters
% SParamToMeasure: could be 'S11','S21','S12', 'S22'
% averCount: number of sweep averaging in VNA, sets it only if the input is
% present
% if armVNA is not used in prefn, trigger will be set to internal and data
% is acquired continuously
%ks: object
%Clear the event status registers and all errors which may be in the VNA's
%queue
fprintf(ks,'*CLS');
%fprintf(ks, ':SYSTem:PRESet');
fprintf(ks, ':CALCulate:PARameter:DELete:ALL'); % Delete all prior measurements on the VNA

%Check to ensure the error queue is clear. Response is "+0, No Error"
fprintf(ks,'SYST:ERR?');
errIdentifyStart = fscanf(ks,'%s');
%fprintf(sprintf('%s \n',errIdentifyStart));
%clear error
fprintf(ks,'*CLS');

%Set Trigger Mode initially to Continuous ON
%fprintf(ks, 'INIT:CONT ON');

whichS=SParamToMeasure;
if ~iscell(whichS)
    whichS = {whichS};
end
wInd=1; %To do: make it compatible with simultaneous measurement of multiple S parameters
allS={'S11','S21','S12','S22'};%
%create new windows
%for wInd=1:length(whichS)
fprintf(ks,sprintf("DISPlay:WINDow%d:STATE ON",wInd));
%end

% Set 2-port measurement for S parameter
%for wInd=1:length(whichS)
fprintf(ks, sprintf("CALCulate%d:PARameter:DEFine:EXT 'Meas%d','%s'", wInd, wInd,whichS{wInd}));
%end
% feed the measurement display into trace
%for wInd=1:length(whichS)
fprintf(ks, sprintf("DISPlay:WINDow%d:TRACe%d:Feed 'Meas%d'",wInd, wInd,wInd ));
%end

% % %**** Correct Electrical Delay ********
% % fprintf(ks,sprintf('CALC%d:MEAS%d:CORR ON',wInd,wInd));
% % fprintf(ks,sprintf('CALC%d:MEAS%d:CORR:EDEL:TIME %dNS',wInd,wInd,delay));

% Variable to manage average count and group count and set it

%averCount = 1; %This is just initiation, NAVG is set properly after config
if nargin>2
    %Set group count
    fprintf(ks, 'SENS:SWE:GRO:COUN %d', averCount);
    %Set average count, should match group count above
    fprintf(ks,'SENS:AVER:COUN %d',averCount);
end
%Turn averaging ON; 
%fprintf(ks,'SENS:AVER ON');

%Don't react yet, this is just a preparation.
%armVNA takes care of the rest
%Trigger it
%fprintf(ks, 'TRIG:SOUR IMM');%
%fprintf(ks,'INIT:CONT ON');% continuous trigger on

% Stop and wait for trigger
fprintf(ks,'ABORT;*CLS');

%Clear and restart averaging; 
%fprintf(ks, 'SENS:AVER:CLE');
end
function armVNA(ks,triggeredSweeps)
%Makes VNA ready to accept trigger
% triggeredSweeps: 0/1 is a control to set continuous (0) or triggered
% measurement
if triggeredSweeps %Set continuous off
    fprintf(ks,'INIT:CONT OFF');% continuous trigger of
    
else
    fprintf(ks, 'TRIG:SOUR IMM');% Internal continuous trigger
    fprintf(ks,'INIT:CONT ON');% continuous trigger on
end
%Clear and restart averaging
%fprintf(ks, 'SENS:AVER:CLE');
%Initiate trigger/group/average process AND assert *OPC operation complete

%fprintf(ks,'SENS:AVER ON');
%Don't react yet, this is just a preparation.
%To Do:  Trigger behavior is set by Trigger function.
%Trigger it
%fprintf(ks, 'TRIG:SOUR IMM');%
%fprintf(ks,'INIT:CONT ON');% continuous trigger on
%Could be EXT,
%IMM: internal source sends continuous trigger
%MAN: sends one trig when front panel is triggered or INIT:IMM
end
function [out] = readVNA(ks,cmnd)
%reads data corresponding to cmnd from VNA and returns it.
%cmnd is SCPI string for data acquisition
%Initiate trigger/group/average process AND assert *OPC operation complete

%To do: add a case for triggered measurement
%fprintf(ks,'SENS:SWE:MODE GRO;*OPC');

%{
A loop, querying the EVENT STATUS REGISTER via *ESR?. When bit 1 of the returned *ESR? query results flips from '0' to '1',
the group triggering is complete
%}

%To do: add a case for triggered measurement
%t1=datetime;
fprintf(ks,'SENS:AVER ON');
fprintf(ks, 'TRIG:SOUR IMM');% Internal continuous trigger
%fprintf(ks,'INIT:CONT ON');% continuous trigger on
%Turn averaging ON; 


fprintf(ks,'SENS:SWE:MODE GRO;*OPC');
eventStatusRegLoopDone = 0;
while not(eventStatusRegLoopDone)
    fprintf(ks,'*ESR?');
    eventStatusRegLoopDone = fscanf(ks, '%s');
    eventStatusRegLoopDone = bitget(str2num(eventStatusRegLoopDone),1);
end
 %t2=datetime;
 %fprintf('Averaging time:\n')
 %t1-t2
 
% Swap byte order on data query return.
fprintf(ks, 'FORM:BORD SWAP');

%Set Trace Data read or return format as binary bin block real 64 bit
%values
fprintf(ks, 'FORM:DATA REAL,64');

%cmnd='CALC:DATA? SDATA';
fprintf(ks, cmnd);

%Read return data as binary bin block real 64 bit values.
out = binblockread(ks, 'float64');

%Binblock read as a 'handing line feed that must be read and disposed:
%i.e., read the unread line feed to clear the buffer
fscanf(ks, '%c');

%Return data transfer format back to ASCII string format
fprintf(ks, 'FORM:DATA ASCII');

%put VNA back to continuous trigger
%fprintf(ks,'SENS:SWE:MODE CONT');

% As a last step requery the KS error queue and ensure no errors have
% occured since initiation of program
fprintf(ks, 'SYST:ERR?');
errIdentifyStop = fscanf(ks, '%s');
%t3=datetime;
%fprintf('Data transfer time:\n')
%t2-t3

end