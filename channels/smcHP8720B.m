function [val, rate] = smcHP8720b(ico, val, rate)
% driver for HP 8720B spectrum analyzer
% channels for this instrument are 
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% Available channels are
% 1: magnitude squared spectrum
% 2: min frequency
% 3: max freq
% 4: number of points
% 5: magnitude squared spectrum with memory divided out.
% 6: phase with memory divided out. 
% 7: phase from channel 5, which was stored in smdata.inst.data.
% 8: current trace (whatever it is)
% 9: Averaging (in VNA before acquiring data)
% 10: Power
% 11: IF
% 12: Complex S-param 
% 13: Frequency Sweep Center (Hz)
% 14: Frequency Sweep Span (Hz)
% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
%It is essential that this driver uses fwrite and fscanf, not fprintf and
%query.
%update log-
% YPK: 2021/9/26 added averaging channel-- ch9, and Output power (dBm) channel -- ch 10
%Navg=0 turns off averaging
%YPK: 2021/10/19 added IF Bandwidth (Hz) channel -- ch11
%YPK: 2022/1/9 added case for complex S parameter--  ch12
%YPK: 2022_1_14 added VNA timeout set section in channel 9.
%YPK: 2022/1/14 added channel 13: frequency sweep center and channel 14:
%frequency sweep range. They are equivalent to setting corresponding Fmin
%and Fmax but are more handy in some situations.

global smdata;


sa=smdata.inst(ico(1)).data.inst;

pause(.1); %Needed so the SA doesn't trip over itself. A better solution would involve *OPC, but this doesn't work well with the SA in continuous mode.

switch ico(2) %
    case 1 %spectrum (OUTPDATA)
        switch ico(3)
            case 0 %get
                
                %                 fwrite(sa,'*IDN?');
                %                 q=fscanf(sa);
                %
                %                 fwrite(sa,'POWE?');
                %                 pow=str2num(fscanf(sa));
                
                
                fwrite(sa,'POIN?');
                npoints=str2num(fscanf(sa));
                
                %                 fwrite(sa,'STAR?');
                %                 fstart=str2num(fscanf(sa));
                %
                %                 fwrite(sa,'SPAN?');
                %                 span=str2num(fscanf(sa));
                %
                %                 df=span/(npoints-1);
                
                % %                 %read single scan
                if 0
                    fwrite(sa, 'FORM4; OPC?; SING');
                    opc_comp=fscanf(sa);
                    % Read data back from analyzer
                    %fwrite(sa, 'OUTPDATAF');
                    %STM: 2022/05/27 OUTPDATAF triggers a syntax error in
                    %VNA display. OUTPDATA works. OUTPDATF triggers a VISA
                    %timeout error. Once triggered, if the VNA is preset,
                    %any subsequent Matlab - VNA communication triggers a
                    %VISA timeout error. To solve this:
                    %refer to Docs/VNA/VISA Timeout error
                    fwrite(sa,'OUTPDATA');
                end
                
                % YPK: 2021/10/20 group trigger if averaging is on, both single and group trigger restart averaging
                navg=cell2mat(smget('NAvgVNA'));
                if navg>0
                    cmdStr = sprintf('NUMG%d;',navg);%group averaging
                    %make sure  Visa TimeOut is long enough to wait until averaging is complete.
                else
                    cmdStr='SING';%single sweep
                    %fwrite(sa, 'FORM4; OPC?; SING;');%single sweep
                end
                % cmdStr=sprintf('AVERREST;');
                %query(sa,sprintf('OPC?;'));
                fprintf(sa,sprintf('FORM4; OPC?; WAIT; %s;',cmdStr));
                opc_comp=fscanf(sa);
                %fprintf(sa,sprintf('OPC?;WAIT;'));
                % Read data back from analyzer
                %fwrite(sa, 'OUTPDATAF;');
                %STM: 2022/05/27 OUTPDATAF triggers a syntax error in
                %VNA display. OUTPDATF triggers a VISA timeout error.
                %OUTPDATA and OUTPDATA; don't trigger any error. Maybe VNA
                %just ignores the ';' ?
                %fwrite(sa, 'OUTPDATA;');
                fwrite(sa, 'OUTPDATA');
                %fwrite(sa,'OUTPDATA');
                data1=scanstr(sa);
                
                %npoints=str2num(query(sa,'POIN?'));
                
                val=zeros(npoints,1);
                
                %Allocate space for data array
                data=zeros(npoints,2);
                
                %Convert output cell array into a standard two dimensional array
                for i=1:1:npoints
                    data(i,1)=data1{(2*i)-1};
                    data(i,2)=data1{2*i};
                end
                
                %Calculate Magnitude
                p=[];
                
                for i=1:1:npoints
                    %val(i)=data(i,1)+1i.*data(i,2);
                    %val(i)=20*log10(sqrt(data(i,1)^2+data(i,2)^2));
                    val(i)=(data(i,1)^2+data(i,2)^2);
                    p(i)=atan2(data(i,2),data(i,1));
                end
                
                %store it in case we want it later.
                phase=(p).*180/pi;
                
                smdata.inst(ico(1)).data.phase=phase;
                
                %%Return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
                
                %                % restart averaging
                cmdStr=sprintf('AVERREST;');
                fprintf(sa,cmdStr);
                
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 2 %min freq
        switch ico(3)
            case 0
                fwrite(sa,'STAR?');
                val=str2num(fscanf(sa));
                
                %                 fwrite(sa, 'OPC?');
                %                 opc_comp=fscanf(sa);
                
            case 1
                cmdStr=sprintf('STAR %d GHZ;',val/1e9);
                fwrite(sa,cmdStr);
                
                cmdStr='AUTO;';
                fwrite(sa,cmdStr);
              %  fwrite(sa,'CLS');
            otherwise
                error('Operation not supported');
        end
        
    case 3 %max freq
        switch ico(3)
            case 0
                fwrite(sa,'STOP?');
                val=str2num(fscanf(sa));
            case 1
                cmdStr=sprintf('STOP %d GHZ;',val/1e9);
                fwrite(sa,cmdStr);
                cmdStr='AUTO;';
                fwrite(sa,cmdStr);
                     % fwrite(sa,'CLS');
            otherwise
                error('Operation not supported');
        end
        
    case 4 %npoints
        switch ico(3)
            case 0
                fwrite(sa,'POIN?');
                val=str2num(fscanf(sa));
            case 1
                cmdStr=sprintf('POIN %d;',val);
                fprintf(sa,cmdStr);
                cmdStr='AUTO;';
                fprintf(sa,cmdStr);
            otherwise
                error('Operation not supported');
                
        end
        
    case 5 %spectrum (OUTPDATA) with memory divided out
        switch ico(3)
            case 0 %get
                
                fwrite(sa,'POIN?');
                npoints=str2num(fscanf(sa));
                
                fwrite(sa, 'FORM4; OPC?; SING');
                opc_comp=fscanf(sa);
                % Read data back from analyzer
                fwrite(sa, 'OUTPDATA');
                data1=scanstr(sa);
                
                fwrite(sa, 'OUTPMEMO');
                data2=scanstr(sa);
                
                val=zeros(npoints,1);
                val2=zeros(npoints,1);
                
                %Allocate space for data array
                data=zeros(npoints,2);
                dataM=zeros(npoints,2);
                
                %Convert output cell array into a standard two dimensional array
                for i=1:1:npoints
                    data(i,1)=data1{(2*i)-1};
                    data(i,2)=data1{2*i};
                    dataM(i,1)=data2{(2*i)-1};
                    dataM(i,2)=data2{2*i};
                end
                
                %Calculate Magnitude
                p=[];
                pM=[];
                for i=1:1:npoints
                    %val(i)=20*log10(sqrt(data(i,1)^2+data(i,2)^2));
                    val(i)=(data(i,1)^2+data(i,2)^2);
                    val2(i)=(dataM(i,1)^2+dataM(i,2)^2);
                    p(i)=atan2(data(i,2),data(i,1));
                    pM(i)=atan2(dataM(i,2),dataM(i,1));
                end
                
                val=val./val2;
                
                %store it in case we want it later.
                phase=(p-pM).*180/pi;
                %future versions of matlab could use rmoutliers.
                %                 phase(phase==360)=NaN;
                %                 phase(phase==-360)=NaN;
                %phase(TF)=NaN;
                
                smdata.inst(ico(1)).data.phaseD=phase;
                
                %Return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
                
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 6 %phase (OUTPDATA) with memory divided out. Too bad we need an extra channel for this. I don't think special measure handles complex values.
        switch ico(3)
            case 0 %get
                
                fwrite(sa,'POIN?');
                npoints=str2num(fscanf(sa));
                
                fwrite(sa, 'FORM4; OPC?; SING');
                opc_comp=fscanf(sa);
                % Read data back from analyzer
                fwrite(sa, 'OUTPDATA');
                data1=scanstr(sa);
                
                fwrite(sa, 'OUTPMEMO');
                data2=scanstr(sa);
                
                val=zeros(npoints,1);
                val2=zeros(npoints,1);
                
                %Allocate space for data array
                data=zeros(npoints,2);
                dataM=zeros(npoints,2);
                
                %Convert output cell array into a standard two dimensional array
                for i=1:1:npoints
                    data(i,1)=data1{(2*i)-1};
                    data(i,2)=data1{2*i};
                    dataM(i,1)=data2{(2*i)-1};
                    dataM(i,2)=data2{2*i};
                end
                
                %Calculate Magnitude
                for i=1:1:npoints
                    val(i)=atan2(data(i,2),data(i,1));
                    val2(i)=atan2(dataM(i,2),dataM(i,1));
                end
                
                val=(val-val2).*180/pi;
                
                %Return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
                
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 7 %phase (OUTPDATA) with, from smdata.inst.data. Should only be used when getting the spectrum too.
        switch ico(3)
            case 0 %get
                
                val=smdata.inst(ico(1)).data.phase;
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 8 %spectrum (OUTPFORM) (whatever the screen is displaying) NOT FULLY IMPLEMENTED
        switch ico(3)
            case 0 %get
                
                fwrite(sa,'POIN?');
                npoints=str2num(fscanf(sa));
                
                fwrite(sa, 'FORM4; OPC?; SING');
                opc_comp=fscanf(sa);
                % Read data back from analyzer
                fwrite(sa, 'OUTPFORM');
                data1=scanstr(sa);
                
                val=data1;
                
                %Return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
        end
        
    case 9 %Averaging YPK: 2021/9/26
        
        switch ico(3)
            case 0
                fwrite(sa,'AVERFACT?;');
                val=str2num(fscanf(sa));
            case 1
                if val==0
                    %turn on averaging:
                    cmdStr='AVEROFF;';
                    fprintf(sa,cmdStr);
                    %Return it to continuous averaging.
                    fwrite(sa, 'FORM4; OPC?; CONT');
                    
                else
                    %turn on averaging:
                    cmdStr='AVERON;';
                    fprintf(sa,cmdStr);
                    
                    %Return it to continuous averaging.
                    %fwrite(sa, 'FORM4; OPC?; CONT');
                    
                    %set/get averaging factor
                    cmdStr=sprintf('AVERFACT%d;',val);
                    fprintf(sa,cmdStr);
                    
                    %restart averaging
                    cmdStr=sprintf('AVERREST;');
                    fprintf(sa,cmdStr);
                end
                
                %YPK: 2022_1_14
                %take care of sweep time, longer averaging takes more time
                %if averaging time is longer than Timeout, VNA will crash
                %and will need to be restarted
                
                %first get Navg
                fwrite(sa,'AVERFACT?;');
                val=str2num(fscanf(sa));
                
                %now take care of matlab object time out
                
                if 1
                    dt = str2double(query(sa,'SWET?'));
                    %you have to close matlab object to change it's property
                    smclose(ico(1));
                    %max Timeout is 1000
                    %timeOut = min(1000, 30+ceil(dt*val));%min sweep time required + 30 S
                    %06/02/2022: STM ^ was the original timeOut assignment,
                    %I suspect this was responsible for setting timeOut to
                    %33 s, which might not be enough. Trying 1000 and see.
                    timeOut = 1000;
                    try
                        set(sa,'Timeout',timeOut);%update this for larger number of averaging
                        %disp(sprintf('VNA Timeout set to %d S.',timeOut));
                    catch
                        warning("Couldn't set Timeout. VNA could crash during data acquisition. \n Sad !!! \n");
                    end
                    try
                        smopen(ico(1))
                    catch
                        error('Can not open VNA communication \n');
                    end
                end
                
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 10 %Power YPK: 2021/9/26
        switch ico(3)
            case 0
                fwrite(sa,'POWE?;');
                val=str2num(fscanf(sa));
            case 1
                %  cntrlStr= input('Are you sure you want to set up VNA power level to: %g dBm?\n Enter Y (y) to proceed\n','s');
                
                %set/get power dBm
                %   if strcmp(cntrlStr, 'Y') ||  strcmp(cntrlStr, 'y')
                cmdStr=sprintf('POWE %d DB;',val);
                fprintf(sa,cmdStr);
                %                 else
                %                     fprintf('Make up your mind and ask me later!!! \n ' )
                %                     fwrite(sa,'POWE?;');
                %                     val=str2num(fscanf(sa));
                %                     fprintf('Current VNA output is %g.\n',val);
                %                 end
                
                %return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
                %restart averaging
                cmdStr=sprintf('AVERREST;');
                fprintf(sa,cmdStr);
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 11 %IF YPK: 2021/10/19
        switch ico(3)
            case 0
                fwrite(sa,'IFBW?;'); %returns in Hz
                val=str2num(fscanf(sa));
            case 1
                cmdStr=sprintf('IFBW%d;',val);
                fprintf(sa,cmdStr);
                
                %return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 12 %Complex S-param YPK: 2022/1/9
        switch ico(3)
            case 0 %get
                
                fwrite(sa,'POIN?');
                npoints=str2num(fscanf(sa));
                
                if 0
                    fwrite(sa, 'FORM4; OPC?; SING');
                    opc_comp=fscanf(sa);
                    % Read data back from analyzer
                    %fwrite(sa, 'OUTPDATAF');
                    %STM: 05/27/2022 refer to case 1, OUTPDATA comments
                    fwrite(sa, 'OUTPDATA');
                end
                
                % YPK: 2021/10/20 group trigger if averaging is on, both single and group trigger restart averaging
                navg=cell2mat(smget('NAvgVNA'));
                if navg>0
                    cmdStr = sprintf('NUMG%d;',navg);%group averaging
                    %make sure  Visa TimeOut is long enough to wait until averaging is complete.
                else
                    cmdStr='SING';%single sweep
                    %fwrite(sa, 'FORM4; OPC?; SING;');%single sweep
                end
                % cmdStr=sprintf('AVERREST;');
                %query(sa,sprintf('OPC?;'));
                fprintf(sa,sprintf('FORM4; OPC?; WAIT; %s;',cmdStr));
                opc_comp=fscanf(sa);
                %fprintf(sa,sprintf('OPC?;WAIT;'));
                % Read data back from analyzer
                %fwrite(sa, 'OUTPDATAF;');
                %STM: 05/27/2022 refer to case 1, OUTPDATA comments
                fwrite(sa, 'OUTPDATA;');
                data1=scanstr(sa);
                
                %npoints=str2num(query(sa,'POIN?'));
                
                val=zeros(npoints,1);
                
                %Allocate space for data array
                data=zeros(npoints,2);
                
                %Convert output cell array into a standard two dimensional array
                for i=1:1:npoints
                    data(i,1)=data1{(2*i)-1};
                    data(i,2)=data1{2*i};
                end
                
                %Calculate Magnitude
                p=[];
                
                for i=1:1:npoints
                    val(i)=data(i,1)+1i.*data(i,2);
                    
                    p(i)=atan2(data(i,2),data(i,1));
                end
                %store it in case we want it later.
                phase=(p).*180/pi;
                
                smdata.inst(ico(1)).data.phase=phase;
                
                %%Return it to continuous averaging.
                fwrite(sa, 'FORM4; OPC?; CONT');
                
                %                % restart averaging
                cmdStr=sprintf('AVERREST;');
                fprintf(sa,cmdStr);
                
                
            otherwise
                error('Operation not supported');
                
        end
        
    case 13 % frequency sweep center- val should be in HZ YPK: 2022/1/14
        switch ico(3)
            case 0
                fwrite(sa,'CENT?');
                val=str2num(fscanf(sa));
            case 1
                cmdStr=sprintf('CENT %d GHZ;',val/1e9);
                fwrite(sa,cmdStr);
                
                %cmdStr='AUTO;';
                %fwrite(sa,cmdStr);
                
            otherwise
                error('Operation not supported');
        end
        
    case 14 % frequency sweep SPAN in - val should be in HZ YPK: 2022/1/14
        %To do: add case to check spance out of frequency range
        switch ico(3)
            case 0
                fwrite(sa,'SPAN?');
                val=str2num(fscanf(sa));
            case 1
                cmdStr=sprintf('SPAN %d GHZ;',val/1e9);
                fwrite(sa,cmdStr);
                
                %cmdStr='AUTO;';
                %fwrite(sa,cmdStr);
                
            otherwise
                error('Operation not supported');
        end
        
end

fwrite(sa,'CLS');
end