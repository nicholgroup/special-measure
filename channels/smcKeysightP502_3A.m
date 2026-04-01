% function[] = smcKeysightP502_3A
% % new smc script for Keysight P5023A
% 
% 
% end
if 0 %Create a VISA object and query IDN
VISAADDR = 'TCPIP0::localhost::hislip0::INSTR';
%Create a VISA object using Agilent VISA.
ks = visa('agilent',VISAADDR);
%Set buffer size
set(ks, 'InputBufferSize',2097152)
set(ks, 'OutputBufferSize',2097152)

%Open a connection to the instrument using the new VISA object
fopen(ks);
%Send a *IDN? to the instrument
fprintf(ks, '*IDN?');

%Read back a character array with the results.
[IDNSTR, IDNSTRLEN]= fscanf(ks, '%c');

%Display the identification string
disp(['Instrument identified as: ' IDNSTR])

% %Close the connection to the instrument.
% fclose(ks);
% %Free the resources related to VISA object.
% delete(ks);
% 
% %Remove the instrument object variable and the address constant from the
% %workspace.
% clear ks IDNSTRLEN VISAADDR;
end

%% 
%Clear the event status registers and all errors which may be in the VNA's
%queue
fprintf(ks,'*CLS');

%Check to ensure the error queue is clear. Response is "+0, No Error"
fprintf(ks,'SYST:ERR?');
errIdentifyStart = fscanf(ks,'%s');

%Query instrument identification string
fprintf(ks,'*IDN?');
idn = fscanf(ks,'%s');

%Set Trigger Mode initially to Continuous ON
fprintf(ks, 'INIT:CONT ON');

%Query IF bandwidth and set it to desired value
cmd = 'SENS:BWID:RES';
query(ks,[cmd,'?']);

% Set Sweep Time
cmd = 'SENS:SWE:TIME';
query(ks,[cmd,'?']);
%fprintf(ks,[cmd,'2.0'])

% Delete all prior measurements on the VNA
fprintf(ks, ':CALCulate:PARameter:DELete:ALL'); 
%create new windows
fprintf(ks, sprintf("DISPlay:WINDow1:STATE ON"));

% Set 2-port measurement for S21
fprintf(ks, sprintf("CALCulate1:PARameter:DEFine:EXT '%s','%s'", 'Meas2','S11'));
% feed the measurement display into trace
fprintf(ks, sprintf("DISPlay:WINDow1:TRACe1:Feed '%s'", 'Meas2'));
%%
% Variable to manage average count and group count and set it
averCount = 64;
%Set group count
fprintf(ks, 'SENS:SWE:GRO:COUN %d', averCount);
%Set average count, should match group count above
fprintf(ks,'SENS:AVER:COUN %d',averCount);
%%
%Turn averaging ON
fprintf(ks,'SENS:AVER ON');
fprintf(ks, 'TRIG:SOUR IMM');% 
fprintf(ks,'INIT:CONT ON');% continuous trigger on

% Abort measurement
fprintf(ks,'ABORT;*CLS');

%A little insurance clearning the average queue
fprintf(ks, 'SENS:AVER:CLE');

%Initiate trigger/group/average process AND assert *OPC operation complete
fprintf(ks,'SENS:SWE:MODE GRO;*OPC');

%{
A loop, querying the EVENT STATUS REGISTER via *ESR?. When bit 1 of the returned *ESR? query results flips from '0' to '1',
the group triggering is complete
%}
eventStatusRegLoopDone = 0;
while not(eventStatusRegLoopDone)
    fprintf(ks,'*ESR?');
    eventStatusRegLoopDone = fscanf(ks, '%s');
    eventStatusRegLoopDone = bitget(str2num(eventStatusRegLoopDone),1);
end

% Swap byte order on data query return.
fprintf(ks, 'FORM:BORD SWAP');

%Set Trace Data read or return format as binary bin block real 64 bit
%values
fprintf(ks, 'FORM:DATA REAL,64');

%Select a trace to be read
%fprintf(ks, 'CALC:PAR:SEL "CH1_S11_1"');

%%
%{
To select the "FORMATTED DATA" which matches the display use the
'CALC:DATA? FDATA query. Alternatively, to select the underlying real and
imaginary pairs which the formatted data is based upon use
'CALC:DATA? SDATA query. Select or uncomment one of the following
%}
dataQueryType = 'CALC:DATA? FDATA'
%dataQueryType = 'CALC:DATA? SDATA'
fprintf(ks, dataQueryType);

%Read return data as binary bin block real 64 bit values.
cData = binblockread(ks, 'float64');

%Binblock read as a 'handing line feed that must be read and disposed:
%i.e., read the unread line feed to clear the buffer
fscanf(ks, '%c')


%Read the stimulus values
fprintf(ks, 'SENSE:X?');
frequency = binblockread(ks, 'float64');
%read the unread line feed  to clear the buffer
fscanf(ks, '%c');


%Return data transfer format back to ASCII string format
fprintf(ks, 'FORM:DATA ASCII');

% As a last step requery the KS error queue and ensure no errors have
% occured since initiation of program
fprintf(ks, 'SYST:ERR?');

errIdentifyStop = fscanf(ks, '%s');

%%% unused
  %Initiate trigger/group/average process AND assert *OPC operation complete
                fprintf(ks,'SENS:SWE:MODE GRO;*OPC');
                %'Take a sweep and wait
                fprintf(ks, "INITiate:IMMediate;");
                
                %{
A loop, querying the EVENT STATUS REGISTER via *ESR?. When bit 1 of the returned *ESR? query results flips from '0' to '1',
the group triggering is complete
                %}
                eventStatusRegLoopDone = 0;
                while not(eventStatusRegLoopDone)
                    fprintf(ks,'*ESR?');
                    eventStatusRegLoopDone = fscanf(ks, '%s');
                    eventStatusRegLoopDone = bitget(str2num(eventStatusRegLoopDone),1);
                end
                
                % Swap byte order on data query return.
                fprintf(ks, 'FORM:BORD SWAP');
                
                %Set Trace Data read or return format as binary bin block real 64 bit
                %values
                fprintf(ks, 'FORM:DATA REAL,64');
                
                %{
To select the "FORMATTED DATA" which matches the display use the
'CALC:DATA? FDATA query. Alternatively, to select the underlying real and
imaginary pairs which the formatted data is based upon use
'CALC:DATA? SDATA query. Select or uncomment one of the following
                %}
                dataQueryType = 'CALC:DATA? FDATA';
                %dataQueryType = 'CALC:DATA? SDATA'
                fprintf(ks, dataQueryType);
                
                %Read return data as binary bin block real 64 bit values.
                cData = binblockread(ks, 'float64');
                
                %Binblock read as a 'handing line feed that must be read and disposed:
                %i.e., read the unread line feed to clear the buffer
                fscanf(ks, '%c')
                
                
                %Read the stimulus values
                fprintf(ks, 'SENSE:X?');
                frequency = binblockread(ks, 'float64');
                %read the unread line feed  to clear the buffer
                fscanf(ks, '%c');
                
                
                %Return data transfer format back to ASCII string format
                fprintf(ks, 'FORM:DATA ASCII');
                
                % As a last step requery the KS error queue and ensure no errors have
                % occured since initiation of program
                fprintf(ks, 'SYST:ERR?');
                
                errIdentifyStop = fscanf(ks, '%s');

%%

                
                
                
                
                
                
                
                
                
                val=[];
                %check if data is saved in recent call, if not measure
                 try
                     S=sparameters('C:\Users\NICHOL7\Box\Nichol Group\Fab_Laptop1\data_P9374A\dataForSMrun1.s2p');
                 catch
                    fprintf(ks, '*CLS');
                    fprintf(ks, ':SYSTem:PRESet');
                    fprintf(ks, ':CALCulate:PARameter:DELete:ALL'); % Delete all prior measurements on the VNA
                    %create new windows
                    fprintf(ks, sprintf("DISPlay:WINDow1:STATE ON"));
                    fprintf(ks, sprintf("DISPlay:WINDow2:STATE ON"));
                    
                    %measure
                    fprintf(ks, sprintf("CALCulate1:PARameter:DEFine:EXT '%s','%s'", 'Meas1','S11')); % Set 2-port measurement for S11, S12, S21, S22
                    fprintf(ks, sprintf("CALCulate1:PARameter:DEFine:EXT '%s','%s'", 'Meas2','S21'));
                    
                    fprintf(ks, sprintf("DISPlay:WINDow1:TRACe1:Feed '%s'", 'Meas1')); % feed the measurement display into trace
                    fprintf(ks, sprintf("DISPlay:WINDow2:TRACe1:Feed '%s'", 'Meas2'));
                    
%      
                    CalibData=smdata.inst(ico(1)).data.CalibrationDataSets{ smdata.inst(ico(1)).data.useCal }; %Calibration data set
                   % CalibData='CalSet_Full_2048';
                    fprintf(ks, sprintf( "SENS:CORR:CSET:ACT '%s', 1",CalibData )); % load calibration set to channel 1
                    
                    % LTY @ 2021/10/7: Change initial trigger to continuous
                    %fprintf(ks, sprintf(':INITiate1:CONTinuous %d', 0));
                    %                     fprintf(ks, sprintf('SENS:SWE:MODE CONT'));
                    %                     fprintf(ks, ':INITiate1:IMMediate');
                    %                     fprintf(ks, ':DISPlay:WINDow1:TRACe1:Y:SCALe:AUTO');
                   
                    
                    
                
                    %YPK 2021/10/9: Stop sweep, take one sweep and wait for further instructions 
                    %'Turn continuous sweep off
                    fprintf(ks, "INITiate:CONTinuous OFF");
                    
                    %'Take a sweep and wait
                    fprintf(ks, "INITiate:IMMediate;*wai");
                    
                    %check completion of task before returning values
                    maxItr=50;
                    itr=1;
                    while ~query(ks, '*OPC?')
                        pause(2)
                        itr=itr+1;
                        if itr>maxItr
                            error('KS-VNA is busy even after %g s\n', 2*maxItr)
                        end
                        
                    end
                    
                    fprintf(ks, sprintf(':MMEM:STOR:TRAC:FORM:SNP %s', 'RI'));%data format
                    fprintf(ks, sprintf('CALC:DATA:SNP:PORT:SAVE "%s","%s"', '1,2', 'C:\Users\NICHOL7\Box\Nichol Group\Fab_Laptop1\data_P9374A\dataForSMrun1.s2p'));%dataSave
                    
                    
                    
                    
                    
                
                
                %check completion of task before returning values
                maxItr=50;
                itr=1;
                while ~query(ks, '*OPC?')
                    pause(0.5)
                    itr=itr+1;
                    if itr>maxItr
                        error('KS-VNA is busy even after %0.2s\n', 0.1*maxItr)
                    end
                    
                end
                         S=sparameters('C:\Users\NICHOL7\Box\Nichol Group\Fab_Laptop1\data_P9374A\dataForSMrun1.s2p');
