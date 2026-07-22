function tsl = smcSantecTSL775Init(visa_address)
% smcSantecTSL775Init  Open a visa() GPIB connection to the Santec TSL-775.
% Uses the old MATLAB VISA API (visa/fopen/fprintf/query) so smopen can
% reopen it after loading smdata from disk.
%
% Returns the visa object to be stored in smdata.inst(n).data.inst.
%
% Example (GPIB address 10, board 0):
%   smdata.inst(n).data.inst = smcSantecTSL775Init('GPIB0::1::INSTR');

tsl = visa('ni', visa_address);
tsl.Timeout = 5;
% Binary sweep-log readout (:READ:DATA?, channels 18/19) can return up to
% 500k points x 8 bytes = 4 MB in one block; InputBufferSize must cover
% that and can only be set while the connection is closed. ByteOrder
% matches the instrument's "Intel byte order" (little-endian) binary data.
tsl.InputBufferSize = 8*1024*1024;
tsl.ByteOrder = 'littleEndian';
fopen(tsl);

idn = query(tsl, '*IDN?');
fprintf('TSL-775 connected: %s\n', strtrim(idn));

% Default configuration. Laser output is deliberately left OFF -- turn
% it on explicitly via the Output channel (smset('..._Output', 1)).
fprintf(tsl, ':WAV:UNIT 0');    % display units = nm
fprintf(tsl, ':POW:UNIT 0');    % power units = dBm
fprintf(tsl, ':WAV:SWE:MOD 1'); % default sweep mode = continuous one-way

end
