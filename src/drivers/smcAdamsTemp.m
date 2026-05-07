function val = smcAdamsTemp(ic, val, rate)

% driver for BlueFors BFLD-400 
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% channels for this instrument:
% 1: MC temp
% 2: MC setpoint

% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
% ramping not yet configured for this device.

global smdata;

switch ic(2)
    case 1 %MC temp
        switch ic(3)
            case 0 %get
                %f=fopen('\\NICHOL4-PC\Users\Nichol 4\Box Sync\Nichol Group\Adams\sync\MCTemp.txt'); %update Adams Laptop to Box Drive
                %f=fopen('\\NICHOL-4\sync\MCTemp.txt');
          
                % f = fopen('C:\Users\Nichol\Box\Nichol Group\Adams\sync\MCTemp.txt');
                % ******************************%
%                       f=fopen('\\NICHOL-4\Users\sync\MCTemp.txt');
%                 nt=fscanf(f,'%f');
%                 fclose(f);
%                 val = nt;
                % ******************************** %
                %TODO: read the time when this was last written to see if
                %stale
                
                
                %MC temp readout doesn't work occasionally, hack to make it
                %YPK 2022/11/21
                %to revert to original, uncomment the section between *******
                maxTry=100;
                readMCTemp=1;
                tryInd=1;
                while readMCTemp
                    try
                        %ST = round(cell2mat(smget('MCtemp'))*1e3);
                        %f=fopen('\\NICHOL-4\Users\sync\MCTemp.txt');
                        f=fopen('\\NICHOL18\Users\Nichol\sync\MCTemp.txt'); %updated on 10/29/2023 XXC

                        nt=fscanf(f,'%f');
                        fclose(f);
                        val = nt;
                        readMCTemp=0;
                    catch
                        tryInd=tryInd+1;
                        pause(5);
                    end
                    if tryInd>maxTry
                        readMCTemp=0;
                        error("Couldn't read MC temperature\n");
                    end
                    
                end
                
                
                
                
            otherwise
                error('Operation not supported');
        end
        
    case 2 %MC setpoint
        switch ic(3)
            case 1 %set               
                %fname='\\NICHOL4-PC\Users\Nichol 4\Box Sync\Nichol Group\Adams\sync\MCSetPt.txt'; %update Adams Laptop to Box Drive            
                %fname='\\NICHOL-4\sync\MCSetPt.txt';  
                %fname ='\\NICHOL-4\Users\sync\MCSetPt.txt';
                fname ='\\NICHOL18\Users\Nichol\sync\MCSetPt.txt';  %updated on 10/29/2023 XXC
               % fname = 'C:\Users\Nichol\Box\Nichol Group\Adams\sync\MCSetPt.txt';
                f=fopen(fname,'w');
                fprintf(f,'%f\n',val);
                fclose(f);
            case 0 %get
                %f=fopen('\\NICHOL4-PC\Users\Nichol 4\Box Sync\Nichol Group\Adams\sync\MCSetPt.txt'); %update Adams Laptop to Box Drive
                %f=fopen('\\NICHOL-4\sync\MCSetPt.txt');%
                %f=fopen('\\NICHOL-4\Users\sync\MCSetPt.txt');%local network
                f=fopen('\\NICHOL18\Users\Nichol\sync\MCSetPt.txt');%local network, updated on 10/29/2023 XXC
               % f = fopen('C:\Users\Nichol\Box\Nichol Group\Adams\sync\MCSetPt.txt');
                nt=fscanf(f,'%f');
                fclose(f);
                val = nt;
            otherwise
                error('Operation not supported')
        end
        
    otherwise
        error('Channel not defined');
end
end
