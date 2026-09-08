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
% Zero the inter-scan delay. This setting persists on the instrument
% across sessions and power cycles, and its value is inserted into every
% gap between cycles of a multi-cycle scan, so a leftover value silently
% pads repeat scans (a stale ~1 s here produced 1.09/1.16 s inter-cycle
% gaps where 0.09/0.12 s was expected). Set it deliberately via the
% SweepDelay channel (21) when timed repeats are actually wanted.
fprintf(tsl, ':WAV:SWE:DEL 0');
% Leave trigger standby OFF. Like the delay above this persists on the
% instrument, and it silently changes what ":WAV:SWE 1" means: with
% standby on, that command ARMS a sweep (SweepState 3, "standing by
% trigger") instead of running it. That would break both a plain
% wavelength smset (channel 1 blocks until the sweep completes, so it
% would wait out its timeout and error) and any smabufconfig2 scan,
% whose trigfn sends op 3 to the setchan expecting the sweep to start.
% Turn it on deliberately via TrigInStandby (channel 25) when the laser
% is meant to be released by an external or soft trigger, and pair it
% with a trigfn aimed at SoftTrigger (channel 27).
fprintf(tsl, ':TRIG:INP:STAN 0');

end
