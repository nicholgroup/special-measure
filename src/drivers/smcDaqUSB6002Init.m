function [] = smcDaqUSB6002Init()
% National Instrument DAQ USB-6002 start up

global smdata

daqreset;

ic=smchaninst(smchanlookup('daqSpec1'));

s = daq.createSession('ni');
s.Rate = 50000;

smdata.inst(ic(1)).data.device = daq.getDevices;
smdata.inst(ic(1)).data.session = s;
smdata.inst(ic(1)).data.srate = s.Rate;

try
    a=smdata.inst(ic(1)).data.device.ID;
catch
    warning('DAQ device cannot be found.')
end
