%% Setup paths and smdata
% Run this cell first. Assumes special-measure root is on the MATLAB path,
% or adjust the addpath calls below.

%addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'sm'));
%addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'channels'));
%addpath(fileparts(mfilename('fullpath')));   % examples/ folder

addpath('sm\');
addpath('channels');
addpath('examples');
addpath('plot');

rehash path;
global smdata;
smdata.inst     = struct([]);
smdata.channels = struct([]);
smdata.configch=[];
smdata.configfn=[];
%smdata.datadir  = 'C:/data/my_experiment';   % data files saved here
%smdata.logfile  = 'C:/data/my_experiment/log.txt';

smcqdot_setup();
sminitdisp();

screeningGates = {'S', 'SQ'};
fingerGates    = {'T1', 'P', 'T2'};

%% Global turn-on
% Sweep all 7 gates from 0 -> 1 V simultaneously while reading I.
% Verifies that the device turns on and all gate channels respond.

npts = 32;
smset('Vsd', 1e-3);

scan1D = struct();
scan1D.loops(1).rng      = linspace(0, 1, npts);
scan1D.loops(1).npoints  = npts;
scan1D.loops(1).setchan  = smchanlookup({'S','SQ','A1','A2','T1','P','T2'});
scan1D.loops(1).getchan  = smchanlookup('I');
scan1D.loops(1).ramptime = 0.5;
scan1D.loops(1).prefn    = struct([]);
scan1D.saveloop          = 1;
scan1D.disp(1).channel   = 1;   % first getchan = I
scan1D.disp(1).dim       = 1;
scan1D.disp(1).channel   = 1;   % first getchan = I
scan1D.disp(1).loop       = 1;

data = smrun(scan1D, smnext('global_turnon'));

%% Set above threshold
% Park all gates just above turn-on, then close screening gates for
% subsequent scans.

vthresh = 0.65;
smset(smchanlookup({'S','SQ','A1','A2','T1','P','T2'}), vthresh);
smset(smchanlookup('S'),  0);
smset(smchanlookup('SQ'), 0);
smget(smchanlookup('I'))

%% Channel scan (2D)
% Sweep S gate (fast / inner loop) vs SQ gate (slow / outer loop).
% Reads I at each outer-loop point after the inner sweep completes.

scan2D = struct();
scan2D.loops(1).rng      = linspace(0, 1, 64);
scan2D.loops(1).npoints  = 64;
scan2D.loops(1).setchan  = smchanlookup('S');
scan2D.loops(1).getchan  = smchanlookup('I');
scan2D.loops(1).ramptime = 0.1;
scan2D.loops(1).prefn    = struct([]);

scan2D.loops(2).rng      = linspace(0, 1, 32);
scan2D.loops(2).npoints  = 32;
scan2D.loops(2).setchan  = smchanlookup('SQ');
scan2D.loops(2).getchan  = [];
scan2D.loops(2).ramptime = 0.1;

scan2D.disp(1).channel = 1;
scan2D.disp(1).dim     = 2;
scan2D.disp(1).loop     = 1;

scan2D.disp(2).channel = 1;
scan2D.disp(2).dim     = 1;
scan2D.disp(2).loop     = 1;

smprintscan(scan2D);
data = smrun(scan2D, smnext('channel_scan'));

%% Buffered channel scan (2D)
% Same geometry as above but uses I_buf channel for faster acquisition.
% smabufconfig2 calls smcqdot op=5 to set buffer size, wires up trigger
% (op=3 per inner step) and arm (op=4 per outer step) automatically.

npts=64;
scan2Dbuf = struct();
scan2Dbuf.loops(1).rng      = linspace(0, 1, npts);
scan2Dbuf.loops(1).npoints  = npts;
scan2Dbuf.loops(1).setchan  = smchanlookup('S');
scan2Dbuf.loops(1).getchan  = [];
scan2Dbuf.loops(1).ramptime = 0.001; %keep this short for this example to make the buffer work
scan2Dbuf.loops(1).prefn    = struct([]);

scan2Dbuf.loops(2).rng      = linspace(0, 1, npts);
scan2Dbuf.loops(2).npoints  = npts;
scan2Dbuf.loops(2).setchan  = smchanlookup('SQ');
scan2Dbuf.loops(2).getchan  = smchanlookup('I_buf');
scan2Dbuf.loops(2).ramptime = 0.001; 

scan2Dbuf.configfn.fn   = @smabufconfig2;
scan2Dbuf.configfn.args = {'trig arm', [], [], 2};

scan2Dbuf.disp(1).channel = 1;
scan2Dbuf.disp(1).dim     = 2;
scan2Dbuf.disp(1).loop     = 1;

scan2Dbuf.disp(2).channel = 1;
scan2Dbuf.disp(2).dim     = 1;
scan2Dbuf.disp(2).loop     = 2;

smprintscan(scan2Dbuf);
data = smrun(scan2Dbuf, smnext('channel_scan_buf'));

%% Define the channel (park screening gates at threshold)
smset(smchanlookup('S'),  0.575);
smset(smchanlookup('SQ'), 0.575);

%% Finger gate shutoff scans
% Sweep each tunnel/plunger gate from 1 -> 0 V one at a time.
% Measures I to find the pinch-off voltage of each gate.

npts = 32;
scan1Dshut = struct();
scan1Dshut.loops(1).rng      = linspace(1, 0, npts);
scan1Dshut.loops(1).npoints  = npts;
scan1Dshut.loops(1).setchan  = [];   % filled per gate in loop below
scan1Dshut.loops(1).getchan  = smchanlookup('I');
scan1Dshut.loops(1).ramptime = 0.1;
scan1Dshut.loops(1).prefn    = struct([]);
scan1Dshut.saveloop          = 1;
scan1Dshut.disp(1).channel   = 1;
scan1Dshut.disp(1).dim       = 1;
scan1Dshut.disp(1).loop       = 1;

scan1Dshut.cleanupfn.args = {};

for i = 1:length(fingerGates)
    scan1Dshut.loops(1).setchan = smchanlookup(fingerGates{i});
    scan1Dshut.cleanupfn.fn  = @smaconfigwrap;
    scan1Dshut.cleanupfn.args={@smset,scan1Dshut.loops(1).setchan, scan1Dshut.loops(1).rng(1)};
    smrun(scan1Dshut, smnext(['finger_' fingerGates{i} '_shutoff']));
end

%%
plotData()
