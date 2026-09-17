% Buffered scan examples
%
% Examples 1 and 2 are real buffered-acquisition scans, annotated. Both are
% struct dumps from working setups, so the channel names ('1a', 'QPCbuf',
% 'SD1top', 'DAQ1', ...) and the instrument index in the AWG trigger are
% specific to those fridges -- substitute your own before running.
%
% Example 3 is the same idiom against the mock quantum dot, and runs as-is
% with no hardware. Start there if you just want to watch the mechanism work.
%
% WHAT A BUFFERED SCAN IS
%
% In an ordinary scan, smrun sets the inner-loop channel, waits, reads a
% scalar, and repeats. That is one round-trip per point. In a buffered scan the
% inner loop instead ramps *continuously* while a fast digitizer fills its own
% memory, and the outer loop reads the entire inner-loop record back in one
% transfer. The inner loop never actually iterates point by point.
%
% Three things have to line up for that to work:
%
%   1. scan.loops(1).ramptime must be NEGATIVE. The sign is a flag meaning
%      "program the ramp and return immediately, don't block" -- see the
%      "Autoramp and Negative Ramp Rates" section of README.md. Without it the
%      inner loop would step and settle at every point and the digitizer would
%      capture nothing coherent.
%
%   2. scan.configfn = @smabufconfig2, which negotiates the record with the
%      readout driver via control op 5, then installs the arm/trigger hooks.
%      Note it also REWRITES loops(1).npoints and loops(1).ramptime with
%      whatever the hardware could actually deliver -- your requested values
%      are a starting point, not a guarantee. It preserves the negative sign
%      when it does so.
%
%   3. The readout channel lives on loop 2, not loop 1, and its driver must
%      implement ops 5 (configure), 4 (arm), and 3 (trigger), with
%      smdata.inst(i).datadim set to the record length.
%
% The argument list is
%   smabufconfig2(scan, ctrl, getchanInd, config, loop)
% where ctrl is a space-separated option string, getchanInd selects which of
% loops(2).getchan are buffered, config selects which inner-loop setchans get
% triggered, and loop defaults to 2. See `help smabufconfig2` for the options.
%
% Numeric literals below have been shortened (-0.55000000000000004 -> -0.55).
% These parse to bit-identical doubles; only the printed digits changed.


%% Example 1 -- buffered scan sweeping two voltages in each loop
% A 2D charge-stability-style map. Both loops sweep a *pair* of gates
% together, so each loop coordinate maps onto two channels that move in
% lockstep. Readout is a buffered lock-in channel ('QPCbuf').
clear s

% Inner loop: 100 points, ramped continuously from -0.55 to -0.25.
s.loops(1).npoints = 100;
s.loops(1).rng = [-0.55 -0.25];
s.loops(1).getchan = [];              % nothing read here; readout is on loop 2
s.loops(1).setchan{1} = '1a';
s.loops(1).setchan{2} = '1b';         % both gates sweep over the same rng
s.loops(1).ramptime = -0.1;           % NEGATIVE = autoramp. 100 ms/point requested;
                                      % smabufconfig2 will overwrite this with the
                                      % rate the digitizer actually supports.
s.loops(1).trafofn = [];
s.loops(1).trigfn = [];               % left empty on purpose -- 'trig' below installs
                                      % smatrigfn here, overwriting whatever is set
s.loops(1).waittime = 0;

% Outer loop: 32 rows. This is the loop that actually iterates, and the loop
% whose getchan pulls back one full inner-loop record per point.
s.loops(2).npoints = 32;
s.loops(2).rng = [-0.15 -0.1];
s.loops(2).getchan = 'QPCbuf';        % buffered channel; datadim must equal loops(1).npoints
s.loops(2).setchan{1} = '2a';
s.loops(2).setchan{2} = '2b';
s.loops(2).ramptime = [];             % stepped normally -- only the inner loop is ramped
s.loops(2).trafofn = [];
s.loops(2).trigfn = [];
s.loops(2).waittime = [];

s.saveloop = [2 1];                   % write to disk after every outer-loop point
s.consts = [];
s.trafofn = {};

% Display the one getchan twice: as a live 1D trace and as the accumulating 2D map.
s.disp(1).loop = 2; s.disp(1).channel = 1; s.disp(1).dim = 1;
s.disp(2).loop = 2; s.disp(2).channel = 1; s.disp(2).dim = 2;

% 'trig' -> install smatrigfn as loops(1).trigfn, firing both the inner-loop
%           setchans and the buffered getchan together at the first inner point.
% 'arm'  -> install smatrigfn (op 4) as loops(2).prefn(1), re-arming the
%           digitizer at the start of every row.
% Software-triggered: MATLAB itself starts the ramp and the acquisition.
s.configfn.fn = @smabufconfig2;
s.configfn.args{1} = 'trig arm';

% smrun(s, 'qpc_stability_map')       % uncomment to run


%% Example 2 -- buffered scan sweeping one voltage, reading the DAQ
% Same skeleton, but hardware-triggered: an AWG marker line starts the ramp and
% the digitizer, instead of MATLAB doing it. This is the pattern you want when
% the ramp has to be synchronous with a pulse sequence.
clear s

s.loops(1).npoints = 64;
s.loops(1).rng = [-0.15 -0.05];
s.loops(1).setchan{1} = 'SD1top';
s.loops(1).ramptime = -0.005;         % NEGATIVE, as always for buffered acquisition
s.loops(1).getchan = [];

% Because trigfn is non-empty here, two things do NOT happen that would
% otherwise: smrun skips its automatic smatrigfn install (it only fills in a
% trigfn when loops(1).ramptime < 0 and trigfn is empty or .autoset is true),
% and smabufconfig2 leaves it alone since 'trig' is absent from ctrl below.
% The AWG marker is physically wired to the DAC's trigger input, so the DAC
% must be registered with a data.trigmode that waits for that edge rather than
% self-starting -- see the DecaDAC row in README.md's autoramp table.
s.loops(1).trigfn.fn = @smatrigAWG;
s.loops(1).trigfn.args{1} = 12;       % instrument index of the AWG in smdata.inst
                                      % NOTE: this was {[12]} in the original. fncall
                                      % expands args{:} directly into smatrigAWG(inst),
                                      % so a wrapping cell reaches smdata.inst(inst) as
                                      % a cell and errors. Please confirm 12 is right
                                      % for your smdata.

s.loops(2).npoints = 64;
s.loops(2).rng = [-0.2 -0.1];
s.loops(2).setchan{1} = 'SD1bot';
s.loops(2).ramptime = [];
s.loops(2).getchan{1} = 'DAQ1';
s.loops(2).trigfn = [];

% 'arm' only -- no 'trig', because the AWG provides the trigger in hardware.
% The second argument is getchanInd: which entries of loops(2).getchan are
% buffered and therefore need arming. Here that is getchan{1} = 'DAQ1'.
s.configfn.fn = @smabufconfig2;
s.configfn.args{1} = 'arm';
s.configfn.args{2} = 1;

s.disp(1).loop = 2; s.disp(1).channel = 1; s.disp(1).dim = 1;
s.disp(2).loop = 2; s.disp(2).channel = 1; s.disp(2).dim = 2;
s.cleanupfn = [];

% Constants applied once, before the scan starts.
s.consts(1).setchan = 'PulseLine';
s.consts(1).val = 1;                  % which AWG sequence line to run
s.consts(2).setchan = 'samprate';
s.consts(2).val = 10e6;               % DAQ sample rate, 10 MS/s

% smrun(s, 'sd1_daq_map')             % uncomment to run


%% Example 3 -- the same idiom against the mock quantum dot (runs with no hardware)
% Identical structure to example 1: inner loop autoramps, outer loop reads one
% full record per point. The mock implements the same driver contract the real
% instruments do -- op 5 configure, op 4 arm, op 3 trigger -- so this is not a
% simplified stand-in, it is the same code path with a simulated device.
%
% smcqdot arms the ramp on a negative rate and sweeps it on the trigger,
% mirroring a DecaDAC held in its trigmode. Run this and the resulting map is
% bit-identical to the equivalent pointwise scan.
clear s

% Put the repo on the path. mfilename is empty when you run a single cell
% rather than the whole file, in which case fall back to the current folder.
R = fileparts(fileparts(mfilename('fullpath')));
if isempty(R), R = pwd; end
addpath(fullfile(R, 'src', 'sm'), fullfile(R, 'src', 'drivers'), ...
        fullfile(R, 'src', 'utils', 'toolbox'), fullfile(R, 'examples'));
if isempty(which('smcqdot_setup'))
    error('special-measure not found; cd to the repo root and rerun this cell.');
end

global smdata
smdata.inst     = struct([]);
smdata.channels = struct([]);
smdata.configch = 1:10;
smdata.configfn = [];
smcqdot_setup();

% Open the dot so there is a current to measure.
smset('A1', 1.0); smset('A2', 1.0);
smset('T1', 1.0); smset('P', 1.0); smset('T2', 1.0);
smset('Vsd', 1e-3);

npts = 16;
s.loops(1).npoints  = npts;
s.loops(1).rng      = [0 1];
s.loops(1).setchan  = 'S';
s.loops(1).getchan  = [];
s.loops(1).ramptime = -0.001;         % NEGATIVE -- the whole point
s.loops(1).prefn    = struct([]);

s.loops(2).npoints  = npts;
s.loops(2).rng      = [0 1];
s.loops(2).setchan  = 'SQ';
s.loops(2).getchan  = 'I_buf';        % datadim set to npts by op 5
s.loops(2).ramptime = 0.001;

s.configfn.fn   = @smabufconfig2;
s.configfn.args = {'trig arm', [], [], 2};

s.disp(1).loop = 2; s.disp(1).channel = 1; s.disp(1).dim = 1;
s.disp(2).loop = 2; s.disp(2).channel = 1; s.disp(2).dim = 2;

data = smrun(s);                      % no filename -> nothing written to disk
fprintf('I_buf map is %d x %d, all finite: %d\n', ...
        size(data{1}, 1), size(data{1}, 2), all(isfinite(data{1}(:))));
