function [val]=smcDSI22000PRO(ic,val)
%ic(1): instrument number in smdata
%ic(2): channel of the instrument
%ic(3): action: 0=get, 1=set

%channel1: freq-Hz, df 2Hz  ,
%calibrated freq range: 0.05:22 GHz, extended: 0.01:24.5 GHz
%channel2: amplitude-dBm: 
%Calibrated power range: -35:15dBm<13Ghz,  -15:15dBm>13GHz ( uncalibrated:-40:16 dBm)
%output accuracy: +/- 1dB at 0dBm
%Attenuator's step: 0.25dB <6GHz, 0.5dB>6GHz

%Vpp~2.8284*Vrms, PdBm = 10 log(1000*Vrms^2/R); Vrms in V and R in Ohm
% for 50 Ohm input: Vrms = (10^(PdBm/20))/sqrt(20); maxOutput: 15dBm=1.257V

%2121/5 YPK

global smdata;
cmd={'FREQ:CW','POWER'};%same as smdata.inst(ic(1)).channels but with no white spaces
chanUnits={'MHZ','',''}; %power is in dBm

try
    query(smdata.inst(ic(1)).data.inst,'*IDN?');

    %2025_02_25 STM/JMN commented out the line below because it was turning
    %off the output. 
    %fprintf(smdata.inst(ic(1)).data.inst,'*CLS');%clear any previous code
    %error 
    
catch
    error('dsi22000PRO communication failed!');
end

switch ic(3) % action
    case 0 %get
        tryInd=0; %limit query number
        validReturn=0; %break if the query returns a number
        %while is used because DSI sometime returns IDN instead of the value of a asked channel
        while tryInd<20 && ~validReturn           
            val=query(smdata.inst(ic(1)).data.inst,[cmd{ic(2)} '?']);
            %because DSI returns string with units 2025_02_25: STM/MRS =
            %algorithm below returns an order of magnitude lower
            % ind=regexp(val,'\d\S');
            % if ischar(val)
            %     val=str2double(val(1:ind(end)));
            % end
            %Use the following hardcoded ones insted
            if ischar(val)
                if length(val) ==11 %power
                    val = str2double(val(1:length(val)-5));
                else %freq
                val = str2double(val(1:length(val)-4));
                end
            end
            if ~isnan(val)
                validReturn=1;
            end
            tryInd=tryInd+1;            
        end
        
    case 1 %set
        try
            %Write frequency in MHZ to make dsi happy
            if ic(2)==1
                val=val/1e6;
            end
            %fprintf(smdata.inst(ic(1)).data.inst,[cmd{ic(2)} sprintf('%f ',val) chanUnits{ic(2)}]);
            fprintf(smdata.inst(ic(1)).data.inst,[cmd{ic(2)} sprintf(' %f%s',val,chanUnits{ic(2)})]);
        catch
             error('dsi22000PRO chan set failed!');
        end
end

% make sure dsi is still happy
try
    query(smdata.inst(ic(1)).data.inst,'*IDN?');
catch
    error('dsi22000PRO communication failed!');
end
end
