function [val]=smcTSG4106A(ic,val)
%ic(1): instrument number in smdata
%ic(2): channel of the instrument
%ic(3): action: 0=get, 1=set
%channels: 
%1. freq-Hz, 
%2. phase-deg, 
%3. amplitude-dBm 
%4. amplitude-Vpp
%5. offset (not implemented yet)
%Vpp~2.8284*Vrms, PdBm = 10 log(1000*Vrms^2/R); Vrms in V and R in Ohm
% for 50 Ohm input: Vrms = (10^(PdBm/20))/sqrt(20); maxOutput: 16dBm=1.41V
%2021/2 YPK
%YPK: 2021/4/22:  using commands saved in smdata.inst.channels
%YPK: 2021/6/12: added fourth channel to set output in Vrms unit, query returns in dBm unit
global smdata;
 %cmd={'FREQ', 'PHAS','AMPR'};
cmd=smdata.inst(ic(1)).channels; % Feedback from JHD: why not just use the cmd above? 2025/3/14
chanUnits={'Hz','','dBm','RMS'};
% try
%     query(smdata.inst(ic(1)).data.inst,'*IDN?');
% catch
%     error('TSG4106 communication failed!');
% end

switch ic(3) % action
    case 0 %get
        try
            %chan=smchanlookup(ic(2));
        val=query(smdata.inst(ic(1)).data.inst,sprintf('%s?', cmd(ic(2),:)));
        if ischar(val)
            val=str2double(val);
        end
        catch
            error('TSG data read failed!');
        end
        
    case 1 %set
        try
            fprintf(smdata.inst(ic(1)).data.inst,[cmd(ic(2),:) sprintf('%f ',val) chanUnits{ic(2)}]);
        catch
             error('TSG chan set failed!');
        end
end

% counter=1;
% while ~query(smdata.inst(ic(1)).data.inst,'*OPC?')
%     pause(1/1e5);%wait 10 us
%     counter=counter+1;
%     if counter>=1e5
%         error('OPC error \n ');
%     end
% end
end