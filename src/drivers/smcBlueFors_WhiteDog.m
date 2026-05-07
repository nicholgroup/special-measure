function val = smcBlueFors_WhiteDog(ic, val, rate)

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
                f=fopen('C:\Users\Nichol\Box\Nichol Group\Docs\Fridge\White Dog\sync\MCTemp.txt');
                nt=fscanf(f,'%f');
                fclose(f);
                val = nt;
                %TODO: read the time when this was last written to see if
                %stale
            otherwise
                error('Operation not supported');
        end
        
    % case 2 %MC setpoint
    %     switch ic(3)
    %         case 1 %set               
    %             fname='C:\Users\Nichol\Box\Nichol Group\Docs\Fridge\White Dog\sync\MCSP.txt';
    %             f=fopen(fname,'w');
    %             fprintf(f,'%f\n',val);
    %             fclose(f);
    %         case 0 %get
    %             f=fopen('C:\Users\Nichol\Box\Nichol Group\Docs\Fridge\White Dog\sync\MCSP.txt');
    %             nt=fscanf(f,'%f');
    %             fclose(f);
    %             val = nt;
    %         otherwise
    %             error('Operation not supported')
    %     end
        
    otherwise
        error('Channel not defined');
end
end