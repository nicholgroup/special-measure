function [] = smcKeithley2000Init()
%function [] = smcKeithley2000Init()
%configures a Keithley 2000 multimeter for two terminal resistance measurements.%measurements

global smdata

%EJC 2022/05/19: edited to be able to handle more than 1 DMM on equipment
%rack... just need to add name to dmm_names cell array below.
dmm_names = {'DMM','DMM2'};

for i=1:length(dmm_names)
    
    %QHF 2022/08/10: try-catch loop to make the function compatible with
    %single-DMM stations
    try
        ic = smchanlookup(dmm_names{i});
        ic = smchaninst(ic);
        ic = ic(1);
        inst = smdata.inst(ic(1)).data.inst;
        query(inst,'*IDN?');
    catch
        continue;
    end
        
    
    %JMN 2020/01/02 Why is this next line needed? Shouldn't the instrument
    %already be opened elsewhere
    try
        smopen(ic(1));
    catch
        warning('Trouble opening %s',dmm_names{i});
        continue;
    end
    
    fprintf(inst, '*RST');
    fprintf(inst,'*CLS');
    
    fprintf(inst,'CONF:VOLT');
    fprintf(inst,':SYST:BEEP:STAT OFF');
    fprintf(inst,'SENS:VOLT:DC:RANG 10');
    
    fprintf(inst, 'INIT:CONT ON;:ABORT');
    fprintf(inst, 'VOLT:NPLC 1'); %integrate 1 power line cycle
    fprintf(inst, 'SENS:VOLT:DC:AVER:STAT OFF');
    fprintf(inst, 'SENS:VOLT:DC:AVER:COUN 1');
    
end

end
