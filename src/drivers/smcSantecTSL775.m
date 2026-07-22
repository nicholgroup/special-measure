function [val] = smcSantecTSL775(ico, val, rate)
% 7/2026 FTL
% Driver for Santec TSL-775 Tunable Semiconductor Laser (GPIB, SCPI mode).
%
% IMPORTANT: this driver assumes the instrument's remote command-set is
% configured for SCPI mode (front-panel setting), not Legacy mode. All
% wavelength-valued commands (Wavelength, SweepStart, SweepStop,
% SweepStep, TrigOutStep) explicitly append an "NM" unit suffix on
% writes and request "NM"-unit responses on reads, because SCPI mode's
% default unit is meters -- a bare unitless number would otherwise be
% silently interpreted as meters instead of nanometers. If the
% instrument is ever switched to Legacy mode, these unit suffixes will
% break (Legacy mode does not accept unit strings at all).
% ico(1): instrument index in smdata
% ico(2): channel / parameter to control
    %   1  - Wavelength (nm)      (get/set, self-ramping: type=1)
    %          set drives a one-shot hardware sweep from the current
    %          wavelength to val (forces continuous one-way sweep mode,
    %          see note below); rate is in nm/s and is snapped to the
    %          nearest instrument-supported sweep speed
    %          {0.5,1,2,5,10,20,50,100,200}. rate<0: program the sweep
    %          but do not start it (trigger separately with ico(3)=3) --
    %          used by smset for buffered/triggered scans.
    %   2  - Power (dBm)          (get/set)
    %   3  - PowerActual (dBm)    (get only, monitored optical power)
    %   4  - Output (0/1)         (get/set: laser output on/off)
    %   5  - SweepStart (nm)      (get/set)
    %   6  - SweepStop (nm)       (get/set)
    %   7  - SweepSpeed (nm/s)    (get/set, snapped to nearest of
    %                              {0.5,1,2,5,10,20,50,100,200})
    %   8  - SweepMode            (get/set: 0=step 1-way, 1=cont 1-way,
    %                              2=step 2-way, 3=cont 2-way)
    %   9  - SweepDwell (s)       (get/set, step-mode wait between steps)
    %   10 - SweepCycles          (get/set: sweep repetition count --
    %                              only takes effect via SweepRepeat,
    %                              channel 13; SweepState always runs a
    %                              single scan regardless of this value)
    %   11 - SweepState           (get: 0=stopped,1=running,3=standby,
    %                              4=preparing; set: 0=stop,1=start
    %                              single scan)
    %   12 - SweepStep (nm)       (get/set, step size for step-mode
    %                              sweeps, SweepMode 0 or 2)
    %   13 - SweepRepeat          (trigger only, ico(3)=3: starts a
    %                              repeat scan running SweepCycles times,
    %                              i.e. :WAV:SWE:REP instead of :WAV:SWE 1)
    %   14 - TrigOutMode          (get/set: 0=none,1=stop,2=start,3=step;
    %                              when/why the laser emits an output
    %                              trigger pulse on :TRIGger:OUTPut)
    %   15 - TrigOutStep (nm)     (get/set, wavelength/time interval
    %                              between output trigger pulses when
    %                              TrigOutMode=3)
    %   16 - TrigOutActive        (get/set: 0=high active/rising edge,
    %                              1=low active/falling edge)
    %   17 - TrigOutSetting       (get/set: 0=output trigger periodic in
    %                              wavelength, 1=periodic in time)
    %   18 - ReadoutWavelength    (get only: the instrument's internal
    %                              wavelength log from the last sweep, as
    %                              a vector in nm. This is MEASURED
    %                              wavelength -- unlike channel 1, whose
    %                              :WAV? query only returns the setpoint
    %                              register and does NOT update during a
    %                              continuous sweep. Logging points are
    %                              recorded at the output-trigger events,
    %                              so TrigOutMode (14) must be 3 (step)
    %                              with TrigOutStep/TrigOutSetting
    %                              configured for the log to fill. Up to
    %                              500000 points.)
    %   19 - ReadoutPower (dBm)   (get only: internal power-monitor log
    %                              from the last sweep, vector, aligned
    %                              point-for-point with channel 18)
    %   20 - ReadoutPoints        (get only: number of logged points)
% ico(3): 0=get, 1=set, 3=trigger (channel 1: start programmed sweep;
%         channel 13: start repeat scan), 2=query remaining ramp time
%         (channel 1 only)
%
% Channels 5-10, 12 configure a hardware sweep independently of channel
% 1; set them, then set SweepState=1 (single scan) or trigger
% SweepRepeat (channel 13, runs SweepCycles times) to run it.

% Channels 14-17 configure the laser's output trigger pulse (:TRIGger:OUTPut),
% e.g. for a DAQ-triggered buffered scan synchronized to an external
% digitizer. Channel 1's own point-to-point ramp always forces
% SweepMode=1 (continuous one-way) so a plain smset never bounces back
% past the target -- it does not touch or restore whatever SweepMode
% you configured on channels 5-10.

global smdata

tsl = smdata.inst(ico(1)).data.inst;

switch ico(2)
    % --- 1: Wavelength (nm), self-ramping ---
    case 1
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, ':WAV? NM'));

            case 1 % set (ramped)
                if nargin < 3 || isempty(rate)
                    rate = 200; % default to fastest, trigger immediately
                end

                % Wait until any previous sweep is fully done. smset only
                % waits the theoretical ramp time, but the instrument's
                % prep/decel tail outlasts it -- a set issued during that
                % tail (typical for back-to-back smsets in a script) is
                % refused with a silent -200 execution error. Command-line
                % use never sees this because typing latency covers the
                % tail.
                waitSweepIdle(tsl, 30);

                curr = str2double(query(tsl, ':WAV? NM'));
                if curr == val
                    val = 0;
                    return
                end
                if rate == 0
                    error('SantecTSL775: Cannot ramp wavelength at zero rate.');
                end

                speed = snapSweepSpeed(min(abs(rate), 200));
                fprintf(tsl, ':WAV:SWE:MOD 1'); % force continuous one-way
                scpiwrite(tsl, ':WAV:SWE:STAR %.4fNM', curr);
                scpiwrite(tsl, ':WAV:SWE:STOP %.4fNM', val);
                scpiwrite(tsl, ':WAV:SWE:SPE %g', speed); % nm/s: no unit suffix accepted

                expt = abs(val - curr) / speed;
                if rate > 0
                    drainErrors(tsl); % so a stale queue entry can't misfire the check below
                    fprintf(tsl, ':WAV:SWE 1'); % program and start now
                    checkSweepStarted(tsl, val, speed);
                end
                val = expt;

            case 2 % query remaining ramp time
                stat = str2double(query(tsl, ':WAV:SWE?'));
                if stat ~= 1
                    val = 0;
                else
                    stop  = str2double(query(tsl, ':WAV:SWE:STOP? NM'));
                    speed = str2double(query(tsl, ':WAV:SWE:SPE?'));
                    curr  = str2double(query(tsl, ':WAV? NM'));
                    val = abs(stop - curr) / speed;
                end

            case 3 % trigger a previously programmed (unstarted) sweep
                drainErrors(tsl);
                fprintf(tsl, ':WAV:SWE 1');
                checkSweepStarted(tsl, NaN, NaN);

            otherwise
                error('SantecTSL775: Operation not supported for Wavelength.');
        end

    % --- 2: Power (dBm) ---
    case 2
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, ':POW?'));
            case 1 % set
                scpiwrite(tsl, ':POW %.2f', val);
            otherwise
                error('SantecTSL775: Operation not supported for Power.');
        end

    % --- 3: PowerActual (dBm), monitored, read-only ---
    case 3
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, ':POW:ACT?'));
            otherwise
                error('SantecTSL775: PowerActual is read-only.');
        end

    % --- 4: Output (0/1) ---
    case 4
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, ':POW:STAT?'));
            case 1 % set
                scpiwrite(tsl, ':POW:STAT %d', val ~= 0);
            otherwise
                error('SantecTSL775: Operation not supported for Output.');
        end

    % --- 5-10: Sweep configuration channels ---
    % (SweepStart/SweepStop carry an explicit NM unit suffix -- see the
    % SCPI-mode note at the top of this file; SweepSpeed/Mode/Dwell/
    % Cycles have no length unit ambiguity and are left bare.)
    case {5, 6, 7, 8, 9, 10}
        cmds    = {':WAV:SWE:STAR %.4fNM', ':WAV:SWE:STOP %.4fNM', ...
                   ':WAV:SWE:SPE %g',      ':WAV:SWE:MOD %d', ...
                   ':WAV:SWE:DWEL %.1f',   ':WAV:SWE:CYCL %d'};
        queries = {':WAV:SWE:STAR? NM', ':WAV:SWE:STOP? NM', ':WAV:SWE:SPE?', ...
                   ':WAV:SWE:MOD?',      ':WAV:SWE:DWEL?',   ':WAV:SWE:CYCL?'};
        idx = ico(2) - 4;
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, queries{idx}));
            case 1 % set
                if idx == 3 % SweepSpeed: snap to nearest supported value
                    val = snapSweepSpeed(val);
                end
                scpiwrite(tsl, cmds{idx}, val);
            otherwise
                error('SantecTSL775: Operation not supported for channel %d.', ico(2));
        end

    % --- 11: SweepState ---
    case 11
        switch ico(3)
            case 0 % get: 0=stopped,1=running,3=standby,4=preparing
                val = str2double(query(tsl, ':WAV:SWE?'));
            case 1 % set: 0=stop, 1=start single scan
                scpiwrite(tsl, ':WAV:SWE %d', val ~= 0);
            otherwise
                error('SantecTSL775: Operation not supported for SweepState.');
        end

    % --- 12: SweepStep (nm), step-mode step size ---
    case 12
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, ':WAV:SWE:STEP? NM'));
            case 1 % set
                scpiwrite(tsl, ':WAV:SWE:STEP %.4fNM', val);
            otherwise
                error('SantecTSL775: Operation not supported for SweepStep.');
        end

    % --- 13: SweepRepeat, trigger-only: starts repeat scan (SweepCycles times) ---
    case 13
        switch ico(3)
            case 3 % trigger
                fprintf(tsl, ':WAV:SWE:REP');
            otherwise
                error('SantecTSL775: SweepRepeat only supports triggering (ico(3)=3).');
        end

    % --- 14-17: Output trigger configuration ---
    % TrigOutStep (idx 2) is the only length-valued one here. Its write
    % accepts an NM unit suffix like the WAVelength-subsystem commands,
    % but -- unlike those -- its query has no unit-override syntax and
    % always responds in meters, so the get path converts manually.
    case {14, 15, 16, 17}
        cmds    = {':TRIG:OUTP %d', ':TRIG:OUTP:STEP %.4fNM', ...
                   ':TRIG:OUTP:ACT %d', ':TRIG:OUTP:SETT %d'};
        queries = {':TRIG:OUTP?', ':TRIG:OUTP:STEP?', ...
                   ':TRIG:OUTP:ACT?', ':TRIG:OUTP:SETT?'};
        idx = ico(2) - 13;
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, queries{idx}));
                if idx == 2 % TrigOutStep: response is always in meters
                    val = val * 1e9;
                end
            case 1 % set
                scpiwrite(tsl, cmds{idx}, val);
            otherwise
                error('SantecTSL775: Operation not supported for channel %d.', ico(2));
        end

    % --- 18: ReadoutWavelength (nm), internal sweep log, read-only ---
    % SCPI mode returns 64-bit IEEE doubles in meters (Intel byte order);
    % converted to nm here. See readBinaryBlock for the block format.
    case 18
        switch ico(3)
            case 0 % get
                % Reading the log during an active sweep stalls the GPIB
                % handshake (write timeouts, wedged connection). Typical
                % cause: a scan whose polling window ended before the
                % hardware sweep did.
                waitSweepIdle(tsl, 120);
                val = readBinaryBlock(tsl, ':READ:DATA?', 'float64');
                if ~isempty(val) && median(val) < 1e-3
                    val = val * 1e9; % meters -> nm
                end
            otherwise
                error('SantecTSL775: ReadoutWavelength is read-only.');
        end

    % --- 19: ReadoutPower (dBm), internal sweep log, read-only ---
    % 32-bit IEEE floats in dBm regardless of command set.
    case 19
        switch ico(3)
            case 0 % get
                waitSweepIdle(tsl, 120); % see channel 18
                val = readBinaryBlock(tsl, ':READ:DATA:POW?', 'float32');
            otherwise
                error('SantecTSL775: ReadoutPower is read-only.');
        end

    % --- 20: ReadoutPoints, read-only ---
    case 20
        switch ico(3)
            case 0 % get
                val = str2double(query(tsl, ':READ:POIN?'));
            otherwise
                error('SantecTSL775: ReadoutPoints is read-only.');
        end

    otherwise
        error('SantecTSL775: Unknown channel ico(2) = %d', ico(2));
end

end

function s = snapSweepSpeed(x)
% Santec TSL-775 only accepts discrete sweep speeds (nm/s).
allowed = [0.5 1 2 5 10 20 50 100 200];
[~, i] = min(abs(allowed - x));
s = allowed(i);
end

function waitSweepIdle(tsl, tmax)
% Poll the sweep state until the engine is fully stopped (0), erroring
% after tmax seconds. Used before wavelength sets (a set issued during a
% running sweep or its prep/decel tail is silently refused) and before
% log readouts (reading the log mid-sweep stalls the GPIB handshake).
t0 = now;
while str2double(query(tsl, ':WAV:SWE?')) ~= 0
    if (now - t0) * 24 * 3600 > tmax
        error(['SantecTSL775: sweep still active after %g s. Stop it ' ...
            '(SweepState = 0), or enlarge the scan''s polling window if ' ...
            'this happened at end-of-scan readout.'], tmax);
    end
    pause(0.05);
end
end

function drainErrors(tsl)
% Empty the instrument error queue so a stale entry from an earlier,
% unrelated command cannot be mistaken for the outcome of the command
% about to be issued.
for k = 1:20
    e = query(tsl, ':SYST:ERR?');
    if isempty(e) || ~isempty(strfind(e, '+0,')) %#ok<STREMP>
        return
    end
end
end

function checkSweepStarted(tsl, target, speed)
% Query the error queue right after :WAV:SWE 1. The TSL-775 reports a
% refused sweep start ONLY here (-200 "Execution error"); the command
% itself gives no other indication, so without this check a refused set
% silently leaves the wavelength unchanged. Known refusal causes: laser
% output off, sweep engine busy, occasionally 200 nm/s over short spans.
e = strtrim(query(tsl, ':SYST:ERR?'));
if isempty(strfind(e, '+0,')) %#ok<STREMP>
    if isnan(target)
        error('SantecTSL775: sweep start refused: %s (laser output off? sweep busy?)', e);
    else
        error(['SantecTSL775: wavelength sweep to %.4f nm at %g nm/s refused: %s ' ...
            '(laser output off? sweep busy?)'], target, speed, e);
    end
end
end

function scpiwrite(tsl, fmt, val)
% icinterface/fprintf does not do printf-style value interpolation like
% base MATLAB's fprintf -- passing a value as a third argument errors
% ("third input argument must be a character vector or string"). Format
% the command ourselves with sprintf and send the resulting literal
% string as the one argument fprintf actually accepts.
fprintf(tsl, sprintf(fmt, val));
end

function data = readBinaryBlock(tsl, cmd, precision)
% Send cmd (a :READout:DATa* query) and read the IEEE-488.2 binary block
% response: '#' <n> <len> <payload>, where <n> is one digit giving the
% length of <len>, and <len> is the payload size in bytes. Requires
% InputBufferSize large enough for the payload and ByteOrder set to
% littleEndian ("Intel byte order") -- both configured in
% smcSantecTSL775Init. Returns a row vector.
switch precision
    case 'float64'
        bpv = 8; casttype = 'double';
    case 'float32'
        bpv = 4; casttype = 'single';
    otherwise
        error('SantecTSL775: unsupported binary precision %s.', precision);
end

% Drain anything left over from a previous (possibly aborted) read: a
% crashed block read leaves unread payload queued, and parsing would
% otherwise start mid-stream on stale binary bytes instead of the fresh
% header. This makes one failed read unable to poison the next.
while tsl.BytesAvailable > 0
    fread(tsl, min(tsl.BytesAvailable, 65536), 'uchar');
end

fprintf(tsl, cmd);

% Read the ENTIRE response message with one oversized fread, then parse
% the byte array in memory. Deliberate: walking the header with several
% small sequential freads proved unreliable on this VISA stack (the
% byte-count field came back as garbage), while a single large read
% returns the full message intact, terminating at EOI with an
% "unsuccessful read" warning that we suppress -- that warning is the
% normal way to take "the whole message, whatever its length". A full
% 500k-point log (4 MB) can take a while to transfer; raise the timeout
% for the duration.
origTimeout = tsl.Timeout;
tsl.Timeout = 120;
ws = warning('off', 'instrument:fread:unsuccessfulRead');
[raw, cnt] = fread(tsl, tsl.InputBufferSize, 'uint8');
warning(ws);
tsl.Timeout = origTimeout;

raw = uint8(raw(1:cnt))';
if cnt < 2 || raw(1) ~= uint8('#')
    error('SantecTSL775: no binary block in response to %s.', cmd);
end
ndig = double(raw(2)) - double('0');
if ndig < 0 || ndig > 9
    error('SantecTSL775: malformed binary block header ''%s''.', char(raw(1:min(8, end))));
end

if ndig == 0
    % '#0': indefinite-length block, payload runs to the end of the message
    payload = raw(3:end);
    payload = payload(1:floor(numel(payload)/bpv)*bpv); % drop delimiter byte(s)
else
    nbytes = str2double(char(raw(3:2+ndig)));
    if isnan(nbytes) || numel(raw) < 2 + ndig + nbytes
        error('SantecTSL775: incomplete binary block (got %d bytes, header promised %s).', ...
            numel(raw) - 2 - ndig, char(raw(3:2+ndig)));
    end
    payload = raw(3+ndig : 2+ndig+nbytes);
end

data = double(typecast(payload, casttype));
end
