function [] = smcKeithley2000Init()
%function [] = smcKeithley2000Init()
%configures a Keithley 2000 multimeter for two terminal resistance measurements.%measurements

global smdata

ic=smchaninst(smchanlookup('DMM'));

smopen(ic(1));
inst=smdata.inst(ic(1)).data.inst;

fprintf(inst,'*RST');
fprintf(inst,'CONF:RES');
fprintf(inst,':SYST:BEEP:STAT OFF');


end