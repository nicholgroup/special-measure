function pm = smcThorlabsPM61CInit(visa_address)
% smcThorlabsPM61CInit_old  Open a visa() connection to the PM61C.
% Uses the old MATLAB VISA API (visa/fopen/fprintf/query) so smopen can
% reopen it after loading smdata from disk.
%
% Returns the visa object to be stored in smdata.inst(n).data.inst.
%
% Example:
%   smdata.inst(n).data.inst = smcThorlabsPM61CInit('USB0::0x1313::0x80B4::260424202::INSTR');

pm = visa('ni', visa_address);
pm.Timeout = 5;
fopen(pm);

idn = query(pm, '*IDN?');
fprintf('PM61C connected: %s\n', strtrim(idn));

% Default configuration
fprintf(pm, 'SENS1:CORR:WAV 1533');   % wavelength 1533 nm
fprintf(pm, 'SENS:POW:UNIT W');       % unit = Watts
fprintf(pm, 'SENS1:AVER 1');          % averaging = 1 (1 kHz)
fprintf(pm, 'INP1:FILT 0');           % full bandwidth
fprintf(pm, 'SENS:POW:RANG:AUTO 1');  % auto-range on

end
