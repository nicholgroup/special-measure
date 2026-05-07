function [val] = smcKeysightP5023A(ico, val)
% Driver for Keysight P937-4A network analyzer
%get RI values and calculate mag(dB) and phase (degree)

% ico(1) is the instrument number
% ico(2) is the channel number
% ico(3) is the controlling function

% ico(2) includes:
% 1. S11 mag
% 2. S11 Phase
% 3. S21 mag
% 4. S21 Phase
% 5. frequencyGrid (Hz)
% 6. starting frequency (Hz)
% 7. stop frequency (Hz)
% 8. number of points
% 9. power output (dBm?)
% 10. IF bandwidth (Hz)


% ico(3) includes:
% 0. get
% 1. set
% 2. get buffered data
% 3. trigger
% 4. arm
% 5. configure

%To do: add trigger, default is internal 
%Notes:
%YPK 2021/9/1:  driver_v0- first save as .s2p , read and calculate mag and phase
%YPK 2021/10/9: added channel 10 to set IF bandwidth

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
    case {1,2,3,4,5} % S11 and S21 params        
        ind=ico(2);
        switch ico(3)
            case 0 % get
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
                    
                    %'Take a sweep
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
                 %'Turn continuous sweep ON
                    fprintf(ks, "INITiate:CONTinuous ON");
                 end
                
                S11=squeeze( S.Parameters(1,1,:) );
                S21 =squeeze( S.Parameters(2,2,:));               
%                 S11mag = 20.*log10(abs(S11));
%                 S21mag = 20.*log10(abs(S21));
%                 S11Phase = angle(S11);
%                 S21Phase = angle(S21);
                %                data=str2num( cell2mat(split( strip( query( ks, sprintf("CALC:DATA:SNP:PORTs? '1,2'")) ),',' )) );
                %
                %                 numofpts =str2num(query(ks, sprintf('SENSe:SWEep:POINts?')));
                %
%                 % convert returned data into 2D array
%                 
%                 data=reshape(data, numofpts, 9);
                
%                 freq = data{1:nPoints};
%                 
%                 S11=data(:,2) + 1j.*data(:,3); %S11 real + imag
%                 S21=data(:,6) + 1j.*data(:,7); %S21 real + imag
%                 figure(123);hold on;plot(data(:,1), 20.*log10( abs(S11)) );
                %return only the requested data
                
                switch ind
                    case 1 %S11mag
                        val = 20.*log10(abs( squeeze( S.Parameters(1,1,:) ) ));
%                         figure(123);clf
%                         plot(data(:,1),val ); grid on;
                    case 2 %S11 Phase
                        val =angle( squeeze( S.Parameters(1,1,:) ) ).*180./pi;
%                         figure(123);clf
%                         plot(data(:,1),val ); grid on;
                    case 3 %S21 mag
                        val = 20.*log10(abs( squeeze( S.Parameters(2,1,:)) ));
%                         figure(124);clf
%                         plot(data(:,1),val );
                     case 4 %S21 phase
                        val = angle( squeeze( S.Parameters(2,1,:)) ).*180./pi; 
%                         figure(124);clf;
%                         plot(data(:,1),val );
                    case 5 %frequency grid used in measurement
                        val = S.Frequencies;%Hz   
%                         figure(125);plot(data(:,1), val);
                        
                end
                
               

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
    case 9 % power output
        switch ico(3)
            case 0 % get
                
                val=query(ks, sprintf('OUTPut?'));
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val == 1
                    fprintf(ks, sprintf('OUTP ON')); % Turn on RF power
                    
                else
                    error('RF power is not turned on properly');
                end
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

end