function [val] = smcKeysightP9375A(ico, val)

% Conditions script for Keysight P937-5A network analyzer

% ico(1) is the instrument number
% ico(2) is the channel number
% ico(3) is the controlling function

% ico(2) includes:
% 1. S11 log magnitude
% 2. S11 phase
% 3. S21 log magnitude
% 4. S21 phase
% 5. starting frequency
% 6. stop frequency
% 7. number of points
% 8. power level
% 9. RF power ON/OFF

% ico(3) includes:
% 0. get
% 1. set
% 2. get buffered data
% 3. trigger
% 4. arm
% 5. configure

%To do: add trigger, default is internal 

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
    

switch ico(2)
    case 1 % S11 log magnitude
        switch ico(3)
            case 0 % get
               
                val=[];
                
                fwrite(ks, 'FORMat REAL, 64'); % return data into binblock format
                
                fwrite(ks, "CALC:DATA:SNP:PORTs? '1,2'"); % request 2-port measurement data
                
                data=binblockread(ks, 'double'); % read returned data
                fread(ks, 1);
                
                numofpts=str2double(query(ks, 'SENSe:SWEep:POINts?'));
                
                % convert returned data into 2D array
                
                data=reshape(data, numofpts, 9);
                
                % compute the magnitude and phase
                
                val=data(:,1); % frequency range of the measurement, in Hz*1e9
                
                valdB=data(:,2:2:8);
                
                val=squeeze(reshape(valdB(:,1),1,1,numofpts));

        end
        
    case 2 % S11 phase
        switch ico(3)
            case 0 % get
                
                val=[];
                
                fwrite(ks, 'FORMat REAL, 64'); % return data into binblock format
               % fwrite(ks, sprintf(':MMEM:STOR:TRAC:FORM:SNP %s', 'RI'));%data format
                fwrite(ks, "CALC:DATA:SNP:PORTs? '1,2'"); % request 2-port measurement data
                
                data=binblockread(ks, 'double'); % read returned data
                fread(ks, 1);
                
                numofpts=str2double(query(ks, 'SENSe:SWEep:POINts?'));
                
                % convert returned data into 2D array
                
                data=reshape(data, numofpts, 9);
                
                % compute the magnitude and phase
                
                val=data(:,1); % frequency range of the measurement, in Hz*1e9
                
                dataPhase=20*(data(:,3:2:9)/20);
                
                val=dataPhase(:,1);
                
                smdata.inst(ico(1)).data.phase=dataPhase;
                
        end
        
    case 3 % S21 log magnitude
        switch ico(3)
            case 0 % get
               
                val=[];
                
                % define calibration data set to be used                
                CalibData=smdata.inst(4).data.CalibrationDataSets{ smdata.inst(4).data.useCal }; %Calibration data set
                % CalibData='CalSet_Full_2048';
                fprintf(ks, sprintf( "SENS:CORR:CSET:ACT '%s', 1",CalibData )); % load calibration set to channel 1
                
                %
                fwrite(ks, 'FORMat REAL, 64'); % return data into binblock format
                
                fwrite(ks, "CALC:DATA:SNP:PORTs? '1,2'"); % request 2-port measurement data
                
                data=binblockread(ks, 'double'); % read returned data
                fread(ks, 1);
                
                numofpts=str2double(query(ks, 'SENSe:SWEep:POINts?'));
                
                % convert returned data into 2D array
                
                data=reshape(data, numofpts, 9);
                
                % compute the magnitude and phase
                
                val=data(:,1); % frequency range of the measurement, in Hz*1e9
                
                valdB=data(:,2:2:8);
                
                val=squeeze(reshape(valdB(:,2),1,1,numofpts));

        end
        
    case 4 % S21 phase
        switch ico(3)
            case 0 % get
                
                val=[];
                
                fwrite(ks, 'FORMat REAL, 64'); % return data into binblock format
                
                fwrite(ks, "CALC:DATA:SNP:PORTs? '1,2'"); % request 2-port measurement data
                
                data=binblockread(ks, 'double'); % read returned data
                fread(ks, 1);
                
                numofpts=str2double(query(ks, 'SENSe:SWEep:POINts?'));
                
                % convert returned data into 2D array
                
                data=reshape(data, numofpts, 9);
                
                % compute the magnitude and phase
                
                val=data(:,1); % frequency range of the measurement, in Hz*1e9
                
                dataPhase=20*(data(:,3:2:9)/20);
                
                val=dataPhase(:,2);
                
                smdata.inst(ico(1)).data.phase=dataPhase;
                
        end
        
    case 5 % starting frequency
        switch ico(3)
            case 0 % get
                
                val=query(ks, 'SENS:FREQ:STAR?');
                %convert string into floating point
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                 if val > 0
                     
                     fwrite(ks, "SENS:FREQ:STAR 'val'");
                     
                 else
                     error('wrong frequency settings');
                 end
                
        end
        
    case 6 % stop frequency
        switch ico(3)
            case 0 % get
                
                val=query(ks, 'SENS:FREQ:STOP?');
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                     
                    fwrite(ks, "SENS:FREQ:STOP 'val'");
                    
                 else
                     error('wrong frequency settings');
                 end
                
        end
        
    case 7 % number of points
        
        switch ico(3)
            case 0 % get
                
                val=query(ks, 'SENSe:SWEep:POINts?');
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                    
                    fwrite(ks, "SENSe:SWEep:POINts 'val'");
                     
                 else
                     error('wrong points settings');
                 end
                
        end
        
    case 8 % power level
        switch ico(3)
             case 0 % get
                
                val=query(ks, 'SOUR:POW1?');
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val > 0
                    
                    fwrite(ks, "SOUR:POW1 '-10'"); % in dB
                     
                 else
                     error('wrong power input (-dB) settings');
                 end
        end
        
    case 9 % power output
        switch ico(3)
            case 0 % get
                
                val=query(ks, 'OUTPut?');
                
                if  ischar(val)
                    val =str2double(val);
                end
                
            case 1 % set
                
                if val < 1
                    
                    fwrite(ks, "OUTPut ON"); % in dB
                     
                 else
                     error('RF power is not turned on properly');
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

end