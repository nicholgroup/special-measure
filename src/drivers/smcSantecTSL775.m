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
    %          {0.5,1,2,5,10,20,50,100,200}.
    %          rate>0: start the sweep and BLOCK until it has fully
    %          settled, then return 0 (so smset adds no further wait).
    %          rate<0: program the sweep but do not start it (trigger
    %          separately with ico(3)=3) and return the expected ramp
    %          time without waiting -- used by smset for buffered/
    %          triggered scans.
    %   2  - Power (dBm)          (get/set)
    %   3  - PowerActual (dBm)    (get only, monitored optical power)
    %   4  - Output (0/1)         (get/set: laser output on/off)
    %   5  - SweepStart (nm)      (get/set)
    %   6  - SweepStop (nm)       (get/set)
    %   7  - SweepSpeed (nm/s)    (get/set, snapped to nearest of
    %                              {0.5,1,2,5,10,20,50,100,200})
    %   8  - SweepMode            (get/set: 0=step 1-way, 1=cont 1-way,
    %                              2=step 2-way, 3=cont 2-way. In the
    %                              TWO-WAY modes a "cycle" is one
    %                              traversal, alternating direction --
    %                              so N round trips means SweepCycles =
    %                              2N, and an odd count finishes at
    %                              SweepStop rather than back at
    %                              SweepStart. Verified on hardware.)
    %   9  - SweepDwell (s)       (get/set, step-mode wait between steps)
    %   10 - SweepCycles          (get/set: sweep repetition count.
    %                              Applies to BOTH SweepRepeat (13) and
    %                              a plain SweepState=1 (11) -- contrary
    %                              to the manual; see the note at case 1.
    %                              A channel-1 move forces this to 1 and
    %                              does not restore it.)
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
    %                              point-for-point with channel 18. Sent
    %                              as 0.001 dB integer counts, not IEEE
    %                              floats -- see the note at case 19.)
    %   20 - ReadoutPoints        (get only: number of logged points)
    %   21 - SweepDelay (s)       (get/set: wait between consecutive
    %                              scans of a multi-cycle run. Persistent
    %                              on the instrument and a silent source
    %                              of dead time -- see the note at case
    %                              21; Init zeroes it on connect.)
    %   22 - SweepCount           (get only: scans completed in the
    %                              current run; counts each leg in the
    %                              two-way modes)
    %   23 - TrigInExternal       (get/set: 0=disable, 1=enable external
    %                              trigger input on the rear BNC)
    %   24 - TrigInActive         (get/set: 0=rising edge, 1=falling)
    %   25 - TrigInStandby        (get/set: 0=normal, 1=trigger standby
    %                              -- the laser parks in SweepState 3
    %                              waiting to be triggered instead of
    %                              sweeping on command)
    %   26 - TrigThrough          (get/set: 0=off, 1=replicate the input
    %                              trigger on the output port. Leave off
    %                              when the laser is the trigger source.)
    %   27 - SoftTrigger          (trigger only, ico(3)=3: releases a
    %                              sweep parked in trigger standby, via
    %                              :TRIG:INP:SOFT. NOT the same as
    %                              channel 1's ico(3)=3 -- see case 27.)
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
% past the target, and SweepCycles=1 so it traverses exactly once -- it
% does not restore whatever SweepMode/SweepCycles you configured on
% channels 5-10, so re-set those before running a sweep of your own.

global smdata

tsl = smdata.inst(ico(1)).data.inst;

switch ico(2)
    % --- 1: Wavelength (nm), self-ramping ---
    case 1
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':WAV? NM'));

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

                curr = parseNumericResponse(query(tsl, ':WAV? NM'));
                if curr == val
                    val = 0;
                    return
                end
                if rate == 0
                    error('SantecTSL775: Cannot ramp wavelength at zero rate.');
                end

                speed = snapSweepSpeed(min(abs(rate), 200));
                fprintf(tsl, ':WAV:SWE:MOD 1'); % force continuous one-way
                % Force a SINGLE traversal. Both the TSL-775 manual and
                % santec's own sample code state that ":WAV:SWE 1" always
                % executes one scan and that :WAV:SWE:CYCLes applies only
                % to ":WAV:SWE:REP" -- that is WRONG on this firmware
                % (0045.0040.0016). Verified against hardware: with
                % CYCL=3, ":WAV:SWE 1" ran three sweep phases (9.90 s for
                % a 2 nm span at 1 nm/s) where CYCL=1 ran one (2.71 s).
                % Left unforced, a point-to-point move silently inherits
                % whatever CYCL channel 10 was last set to and takes CYCL
                % times longer than the expt returned below -- so smset,
                % which just pauses for expt and returns, would resume
                % while the laser is still sweeping.
                fprintf(tsl, ':WAV:SWE:CYCL 1');
                scpiwrite(tsl, ':WAV:SWE:STAR %.4fNM', curr);
                scpiwrite(tsl, ':WAV:SWE:STOP %.4fNM', val);
                scpiwrite(tsl, ':WAV:SWE:SPE %g', speed); % nm/s: no unit suffix accepted

                expt = abs(val - curr) / speed;
                % Record the ramp duration so ico(3)=2 can report the
                % time remaining (see the note there). rampEnd is NaN
                % until the sweep actually starts.
                smdata.inst(ico(1)).data.rampTime = expt;
                smdata.inst(ico(1)).data.rampEnd  = NaN;
                if rate > 0
                    drainErrors(tsl); % so a stale queue entry can't misfire the check below
                    fprintf(tsl, ':WAV:SWE 1'); % program and start now
                    checkSweepStarted(tsl, val, speed);
                    smdata.inst(ico(1)).data.rampEnd = now + expt / (24*3600);
                    % Block until the sweep has genuinely finished, then
                    % report 0 so smset adds no further wait of its own.
                    % The instrument needs a settling tail beyond the pure
                    % travel time: measured at ~0.33 + 0.41/speed seconds
                    % (0.75 s at 1 nm/s, 0.42 s at 5 nm/s, 0.37 s at
                    % 10 nm/s), consistent with a fixed ~0.4 nm run-up/
                    % decel margin traversed at the sweep rate plus fixed
                    % command overhead. Returning expt instead would hand
                    % control back mid-tail, so a scan that set a
                    % wavelength and immediately read a detector would
                    % sample at the wrong wavelength. Polling for the
                    % actual state is exact, where a predicted pad would
                    % silently undershoot at speeds or wavelength ranges
                    % other than the ones measured here.
                    waitSweepComplete(tsl, 30 + 3 * expt);
                    expt = 0;
                end
                val = expt;

            case 2 % query remaining ramp time
                % Computed from the ramp start time recorded at set/trigger,
                % NOT from the instrument's live position: ":WAV?" returns
                % only the wavelength setpoint register and does NOT track
                % during a continuous sweep. Verified against hardware --
                % throughout a 1552->1557 nm sweep ":WAV? NM" stayed pinned
                % at the pre-sweep value of 1554 and only jumped to 1557 at
                % the end, so the previous abs(stop-curr)/speed form here
                % returned a constant that never counted down.
                % Note nothing in SM currently calls this: smset pauses for
                % the ramp time returned by ico(3)=1 and returns, with its
                % op=2 polling loop commented out.
                stat = parseNumericResponse(query(tsl, ':WAV:SWE?'));
                if stat == 0 || ~isfield(smdata.inst(ico(1)).data, 'rampEnd') ...
                        || isnan(smdata.inst(ico(1)).data.rampEnd)
                    % Idle, or running a sweep this driver did not start
                    % (e.g. armed through channel 11 or 13) so there is no
                    % reference start time to count down from.
                    val = 0;
                else
                    val = max(0, (smdata.inst(ico(1)).data.rampEnd - now) * 24 * 3600);
                end

            case 3 % trigger a previously programmed (unstarted) sweep
                % Deliberately does NOT re-force SweepCycles: triggering
                % a multi-cycle (e.g. continuous two-way) sweep from a
                % scan is a supported use, and forcing 1 here would
                % silently reduce it to a single traversal.
                %
                % The consequence is that if SweepCycles is changed
                % between the ico(3)=1 program and this trigger, the
                % sweep runs CYCL times while rampTime still describes
                % one traversal, so ico(3)=2 under-reports (measured:
                % 9.94 s actual against 2.00 s predicted at CYCL=3).
                % Harmless in SM: smset excludes negative-ramprate
                % channels from its wait entirely (see smset.m, where
                % rampchan is filtered to ramprate > 0), so nothing
                % consumes that estimate on this path.
                drainErrors(tsl);
                fprintf(tsl, ':WAV:SWE 1');
                checkSweepStarted(tsl, NaN, NaN);
                if isfield(smdata.inst(ico(1)).data, 'rampTime')
                    smdata.inst(ico(1)).data.rampEnd = ...
                        now + smdata.inst(ico(1)).data.rampTime / (24*3600);
                end

            otherwise
                error('SantecTSL775: Operation not supported for Wavelength.');
        end

    % --- 2: Power (dBm) ---
    case 2
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':POW?'));
            case 1 % set
                scpiwrite(tsl, ':POW %.2f', val);
            otherwise
                error('SantecTSL775: Operation not supported for Power.');
        end

    % --- 3: PowerActual (dBm), monitored, read-only ---
    case 3
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':POW:ACT?'));
            otherwise
                error('SantecTSL775: PowerActual is read-only.');
        end

    % --- 4: Output (0/1) ---
    case 4
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':POW:STAT?'));
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
                val = parseNumericResponse(query(tsl, queries{idx}));
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
                val = parseNumericResponse(query(tsl, ':WAV:SWE?'));
            case 1 % set: 0=stop, 1=start single scan
                if val ~= 0
                    % A refused start is reported ONLY in the error queue
                    % (see checkSweepStarted). Without this check the
                    % command appears to succeed while the engine stays
                    % stopped -- observed on hardware: a start was
                    % refused here and this path returned silently, so
                    % the sweep never ran and only a stray SweepState
                    % read revealed it. A scan would have collected data
                    % for a sweep that never happened.
                    drainErrors(tsl);
                    fprintf(tsl, ':WAV:SWE 1');
                    checkSweepStarted(tsl, NaN, NaN);
                else
                    fprintf(tsl, ':WAV:SWE 0');
                end
            otherwise
                error('SantecTSL775: Operation not supported for SweepState.');
        end

    % --- 12: SweepStep (nm), step-mode step size ---
    case 12
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':WAV:SWE:STEP? NM'));
            case 1 % set
                scpiwrite(tsl, ':WAV:SWE:STEP %.4fNM', val);
            otherwise
                error('SantecTSL775: Operation not supported for SweepStep.');
        end

    % --- 13: SweepRepeat, trigger-only: starts repeat scan (SweepCycles times) ---
    case 13
        switch ico(3)
            case 3 % trigger
                drainErrors(tsl);
                fprintf(tsl, ':WAV:SWE:REP');
                checkSweepStarted(tsl, NaN, NaN);
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
                val = parseNumericResponse(query(tsl, queries{idx}));
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
    % The TSL-775 manual claims this data is "32 bit IEEE Standard
    % format", but that is WRONG for this instrument (TSL-775, firmware
    % 0045.0040.0016, SCPI mode): the payload is little-endian SIGNED
    % 32-BIT INTEGERS in units of 0.001 dB. Verified against hardware --
    % a -5 dBm setpoint logged counts of -4997 +/- 7, and a 0 dBm
    % setpoint logged counts of -3..+6 (matching :POW:ACT? = 0.003 dBm).
    % Decoding the same bytes as float32 yields denormals and NaNs,
    % because the words are small integers like 0x00000001 / 0xFFFFFFFD.
    % Note channel 18 is genuinely IEEE float64, so the two logs do NOT
    % share an encoding despite being aligned point-for-point.
    case 19
        switch ico(3)
            case 0 % get
                waitSweepIdle(tsl, 120); % see channel 18
                val = readBinaryBlock(tsl, ':READ:DATA:POW?', 'int32') / 1000;
            otherwise
                error('SantecTSL775: ReadoutPower is read-only.');
        end

    % --- 20: ReadoutPoints, read-only ---
    case 20
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':READ:POIN?'));
            otherwise
                error('SantecTSL775: ReadoutPoints is read-only.');
        end

    % --- 21: SweepDelay (s), wait between consecutive scans ---
    % A persistent instrument setting and a silent source of dead time:
    % its value is inserted into EVERY gap between cycles of a
    % multi-cycle scan. Measured on hardware: DEL=0 gives ~0.1 s gaps,
    % DEL=1 gives 1.12 s, DEL=2 gives 2.17 s. It survives power cycles
    % and is invisible unless queried, so a value left over from an
    % earlier session silently pads every repeat scan -- which is exactly
    % what made an earlier 3-cycle run here show 1.09/1.16 s gaps where
    % the same configuration later showed 0.09/0.12 s.
    % smcSantecTSL775Init zeroes it on connect for this reason.
    case 21
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':WAV:SWE:DEL?'));
            case 1 % set
                scpiwrite(tsl, ':WAV:SWE:DEL %.1f', val);
            otherwise
                error('SantecTSL775: Operation not supported for SweepDelay.');
        end

    % --- 22: SweepCount, scans completed in the current run, read-only ---
    % Increments once per traversal, so in the two-way modes it counts
    % each leg separately (see the note at channel 8). Useful for
    % monitoring the progress of a long repeat scan.
    case 22
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, ':WAV:SWE:COUN?'));
            otherwise
                error('SantecTSL775: SweepCount is read-only.');
        end

    % --- 23-26: Input trigger configuration ---
    % These arm the laser to be STARTED by something else, as opposed to
    % channels 14-17 which make the laser emit sync pulses. The standby
    % flow for synchronising with an external instrument is:
    %   1. configure the sweep (channels 5-10) and the output trigger
    %      (14-17) so the partner instrument gets its clock;
    %   2. arm the partner instrument;
    %   3. TrigInStandby (25) = 1 -- the laser parks in SweepState 3,
    %      "standing by trigger", instead of sweeping;
    %   4. fire it with SoftTrigger (27) or an external edge on the rear
    %      BNC (enable that with TrigInExternal, 23).
    % Note TrigThrough (26) replicates an incoming trigger on the output
    % port, for chaining a third instrument; the manual says to leave it
    % OFF when the laser itself is the trigger source, as in sweep mode.
    case {23, 24, 25, 26}
        cmds    = {':TRIG:INP:EXT %d',  ':TRIG:INP:ACT %d', ...
                   ':TRIG:INP:STAN %d', ':TRIG:THR %d'};
        queries = {':TRIG:INP:EXT?',  ':TRIG:INP:ACT?', ...
                   ':TRIG:INP:STAN?', ':TRIG:THR?'};
        idx = ico(2) - 22;
        switch ico(3)
            case 0 % get
                val = parseNumericResponse(query(tsl, queries{idx}));
            case 1 % set
                scpiwrite(tsl, cmds{idx}, val);
            otherwise
                error('SantecTSL775: Operation not supported for channel %d.', ico(2));
        end

    % --- 27: SoftTrigger, trigger-only: start a sweep from standby ---
    % Deliberately SEPARATE from channel 1's ico(3)=3. That one sends
    % ":WAV:SWE 1" to start a sweep by command; this sends the soft
    % trigger that releases a sweep already parked in trigger standby
    % (TrigInStandby, channel 25). They are different instrument paths
    % and must not be conflated -- ":WAV:SWE 1" on a standing-by sweep
    % is not the same operation.
    %
    % The command is ":TRIG:INP:SOFT" per the TSL-775 manual. Note that
    % santec's own Python sample sends ":WAV:SWE:SOFT" instead, which
    % does not appear in this manual's command list.
    case 27
        switch ico(3)
            case 3 % trigger
                drainErrors(tsl);
                fprintf(tsl, ':TRIG:INP:SOFT');
                checkSweepStarted(tsl, NaN, NaN);
            otherwise
                error('SantecTSL775: SoftTrigger only supports triggering (ico(3)=3).');
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

function val = parseNumericResponse(response)
% Parse a numeric SCPI response with an optional trailing unit suffix.
tokens = regexp(strtrim(response), ...
    '^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?', 'match', 'once');
if isempty(tokens)
    error('SantecTSL775: invalid numeric response: %s', strtrim(response));
end
val = str2double(tokens);
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

function waitSweepComplete(tsl, tmax)
% Wait for a just-started sweep to run to completion.
%
% Polls first for the engine to LEAVE the stopped state, then for it to
% come back to stopped. The first poll matters: immediately after
% ":WAV:SWE 1" the instrument can still report state 0 for a few
% milliseconds, and waiting only for "state == 0" would then return
% instantly, before the ramp had begun. In practice checkSweepStarted's
% ":SYST:ERR?" round trip is enough for the state to already read 4
% (preparing), but that is timing-dependent and not worth relying on.
%
% The wait-for-start poll is capped at 0.5 s so that a very short sweep
% which finishes before it is ever observed running cannot stall here.
t0 = now;
while parseNumericResponse(query(tsl, ':WAV:SWE?')) == 0
    if (now - t0) * 24 * 3600 > 0.5
        break
    end
    pause(0.01);
end
waitSweepIdle(tsl, tmax);
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
% Query the error queue right after a sweep start. The TSL-775 reports a
% refused start ONLY here (-200 "Execution error"); the command itself
% gives no other indication, so without this check a refused start
% silently leaves the laser where it was.
%
% The trigger condition is NOT currently understood. Observed on this
% firmware (0045.0040.0016): a cluster of -200 refusals occurred while
% the laser output was off, and once the instrument started refusing it
% kept refusing across several attempts -- including configurations that
% had worked minutes earlier, and including one attempt after the output
% was switched back on. It then cleared on its own and did not recur.
%
% Explicitly ruled out by experiment, so do not re-add these as causes:
%   - wavelength out of range (limits are 1490-1630 nm; the refused
%     endpoints were 1559/1560 nm, well inside)
%   - "sweep start must equal the current wavelength when the output is
%     off" (a refused start had STAR exactly equal to the current
%     wavelength, with the output ON)
%   - settling time after enabling the output (starts succeeded 0.9 s
%     after output-on)
%   - sweep span, speed, cycles, mode (all identical between a refused
%     start and a successful repeat of the same configuration)
%
% Keep this check regardless of the cause: a refused start is reported
% ONLY in the error queue, so without it the caller sees success while
% the laser never moves, and a scan collects data for a sweep that never
% happened.
e = strtrim(query(tsl, ':SYST:ERR?'));
if isempty(strfind(e, '+0,')) %#ok<STREMP>
    if isnan(target)
        error(['SantecTSL775: sweep start refused: %s. Retrying usually clears ' ...
            'it; if it persists, check the sweep range against 1490-1630 nm ' ...
            'and that the output is on.'], e);
    else
        error(['SantecTSL775: wavelength sweep to %.4f nm at %g nm/s refused: %s. ' ...
            'Retrying usually clears it; if it persists, check the target ' ...
            'against the 1490-1630 nm range and that the output is on.'], ...
            target, speed, e);
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
    case 'int32'
        bpv = 4; casttype = 'int32';
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
