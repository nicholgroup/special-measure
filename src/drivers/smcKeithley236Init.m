function [] = smcKeithley236Init(ilim,nread)
%function [] = smcKeithley236Init(ilim)
%configures a Keithley236 Source meter for single-point voltage-source
%measurements
% ilim is current compliance
% nread = 0 is no averageing, nread=5 is lots of averaging.
global smdata

ic=smchaninst(smchanlookup('Source'));

inst=smdata.inst(ic(1)).data.inst;
% inst.InputBufferSize = 2^18;
% inst.OutputBufferSize = 2^18;
% inst.Timeout = 3;

smopen(ic(1));

fprintf(inst,'F0,0X'); %source V, (measure I), DC mode, no sweep
fprintf(inst,['P',num2str(nread)]); %0 disables readings, 5 is 32 readings
fprintf(inst,['L' num2str(ilim) ',0X']); %compliance I, auto I meas range

fprintf(inst,'G5,2,0X'); %source and measure value,ASCII format,lines of sweep per data talk
fprintf(inst,['B' num2str(0) ',0,0X']); %set the voltage back to bias
fprintf(inst,'N1X'); %turn on output


end