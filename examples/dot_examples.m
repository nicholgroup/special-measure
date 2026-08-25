%% Setup paths and smdata
% Run this cell first. Assumes special-measure root is on the MATLAB path,
% or adjust the addpath calls below.

%addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'sm'));
%addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'channels'));
%addpath(fileparts(mfilename('fullpath')));   % examples/ folder

addpath('src\sm\');
addpath('src\drivers\');
addpath('examples\');
addpath('src\utils\plotting\');

rehash path;
global smdata;
smdata.inst     = struct([]);
smdata.channels = struct([]);
smdata.configch=[1:10];
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
scan1D.loops(1).rng      = [0 1];
scan1D.loops(1).npoints  = npts;
scan1D.loops(1).setchan  = {'S','SQ','A1','A2','T1','P','T2'};
scan1D.loops(1).getchan  = 'I';
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
scan2D.loops(1).rng      = [0 1];
scan2D.loops(1).npoints  = 64;
scan2D.loops(1).setchan  = 'S';
scan2D.loops(1).getchan  = 'I';
scan2D.loops(1).ramptime = 0.1;
scan2D.loops(1).prefn    = struct([]);

scan2D.loops(2).rng      = linspace(0, 1, 32);
scan2D.loops(2).npoints  = 32;
scan2D.loops(2).setchan  = 'SQ';
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

npts=16;
scan2Dbuf = struct();
scan2Dbuf.loops(1).rng      = [0 1];
scan2Dbuf.loops(1).npoints  = npts;
scan2Dbuf.loops(1).setchan  = 'S';
scan2Dbuf.loops(1).getchan  = [];
scan2Dbuf.loops(1).ramptime = 0.001; %keep this short for this example to make the buffer work
scan2Dbuf.loops(1).prefn    = struct([]);

scan2Dbuf.loops(2).rng      = [0 1];
scan2Dbuf.loops(2).npoints  = npts;
scan2Dbuf.loops(2).setchan  = 'SQ';
scan2Dbuf.loops(2).getchan  = 'I_buf';
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

%% 2D scan with prefn
% prefn is a struct array with fields fn and args.  smrun calls
%   prefn(k).fn(xt, prefn(k).args{:})
% at the start of each step of the loop on which it is defined,
% where xt is the current scan position vector.
%
% Here the outer (SQ) loop resets the count channel to the value of SQ,
% just as an example

scan2Dpre = struct();
scan2Dpre.loops(1).rng      = [0 1];
scan2Dpre.loops(1).npoints  = 32;
scan2Dpre.loops(1).setchan  = 'S';
scan2Dpre.loops(1).getchan  = {'I', 'count'};
scan2Dpre.loops(1).ramptime = 0.1;
scan2Dpre.loops(1).prefn    = struct([]);

scan2Dpre.loops(2).rng      = [0 1];
scan2Dpre.loops(2).npoints  = 16;
scan2Dpre.loops(2).setchan  = 'SQ';
scan2Dpre.loops(2).getchan  = [];
scan2Dpre.loops(2).ramptime = 0.1;
scan2Dpre.loops(2).prefn(1).fn   = @(xt, ch) smset(ch, xt(2));
scan2Dpre.loops(2).prefn(1).args = {smchanlookup('count')};

scan2Dpre.disp(1).channel = 1;
scan2Dpre.disp(1).dim     = 2;
scan2Dpre.disp(1).loop    = 1;
scan2Dpre.disp(2).channel = 1;
scan2Dpre.disp(2).dim     = 1;
scan2Dpre.disp(2).loop    = 1;

smprintscan(scan2Dpre);
data = smrun(scan2Dpre, smnext('channel_scan_prefn'));

%% Define the channel (park screening gates at threshold)
smset(smchanlookup('S'),  0.575);
smset(smchanlookup('SQ'), 0.575);

%% Finger gate shutoff scans
% Sweep each tunnel/plunger gate from 1 -> 0 V one at a time.
% Measures I to find the pinch-off voltage of each gate.
%
% This is also an example of how to use a cleanupfn.

npts = 32;
scan1Dshut = struct();
scan1Dshut.loops(1).rng      = [1 0];
scan1Dshut.loops(1).npoints  = npts;
scan1Dshut.loops(1).setchan  = [];   % filled per gate in loop below
scan1Dshut.loops(1).getchan  = 'I';
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

%% 3D scan (S x SQ x T1)
% Adds a third (slowest) loop over the T1 plunger gate.
% data{1} shape: [nfast, nmid, nslow] = [11, 5, 3].

nfast = 11; nmid = 5; nslow = 3;

scan3D = struct();
scan3D.loops(1).rng      = [0.4 0.8];
scan3D.loops(1).npoints  = nfast;
scan3D.loops(1).setchan  = 'S';
scan3D.loops(1).getchan  = 'I';
scan3D.loops(1).ramptime = 0.1;
scan3D.loops(1).prefn    = struct([]);

scan3D.loops(2).rng      = [0.4 0.8];
scan3D.loops(2).npoints  = nmid;
scan3D.loops(2).setchan  = 'SQ';
scan3D.loops(2).getchan  = [];
scan3D.loops(2).ramptime = 0.1;

scan3D.loops(3).rng      = [0.5 0.7];
scan3D.loops(3).npoints  = nslow;
scan3D.loops(3).setchan  = 'T1';
scan3D.loops(3).getchan  = [];
scan3D.loops(3).ramptime = 0.5;

scan3D.disp(1).channel = 1;
scan3D.disp(1).dim     = 2;
scan3D.disp(1).loop    = 1;
scan3D.disp(2).channel = 1;
scan3D.disp(2).dim     = 1;
scan3D.disp(2).loop    = 1;

smprintscan(scan3D);
data = smrun(scan3D, smnext('channel_scan_3d'));

%% Diagonal sweep using trafofn
% Sweep S and SQ simultaneously along a 45-degree diagonal in gate space.
% scan.loops(i).trafofn is a cell array with one function per setchan.
% Each function receives the full scan position vector x (x(i) = current
% value of loop i) and smdata.chanvals as y.

center_S  = 0.575;
center_SQ = 0.575;
theta     = pi/4;   % 45 degrees: equal steps in both S and SQ

scanDiag = struct();
scanDiag.loops(1).rng      = [-0.2, 0.2];
scanDiag.loops(1).npoints  = 41;
scanDiag.loops(1).setchan  = {'S', 'SQ'};
scanDiag.loops(1).getchan  = 'I';
scanDiag.loops(1).ramptime = 0.05;
scanDiag.loops(1).prefn    = struct([]);
% one trafofn per setchan: x(1) is the current t along the diagonal
scanDiag.loops(1).trafofn  = { @(x, y) center_S  + x(1)*cos(theta), ...
                                @(x, y) center_SQ + x(1)*sin(theta) };

scanDiag.disp(1).channel = 1;
scanDiag.disp(1).dim     = 1;
scanDiag.disp(1).loop    = 1;

smprintscan(scanDiag);
data = smrun(scanDiag, smnext('diagonal_sweep'));


%% procfn — process acquired data on the fly
% scan.loops(i).procfn(k) specifies processing for the k-th getchan.
% procfn(k).fn is a struct with fields:
%   .fn      function handle (or [] for passthrough)
%   .args    extra args passed after the channel value
%   .inchan  index into temporary channel buffer (defaults to k)
%   .outchan index to write result into (defaults to inchan)
%
% Here we subtract a known offset and convert A -> nA before saving.

offset = 2e-9;   % estimated background current (A)

scanProc = struct();
scanProc.loops(1).rng      = [0.4, 0.8];
scanProc.loops(1).npoints  = 41;
scanProc.loops(1).setchan  = 'P';
scanProc.loops(1).getchan  = 'I';
scanProc.loops(1).ramptime = 0.05;
scanProc.loops(1).prefn    = struct([]);

% fn is called as fn.fn(newdata{inchan}, fn.args{:})
scanProc.loops(1).procfn(1).fn.fn   = @(val, bg) (val - bg) * 1e9;
scanProc.loops(1).procfn(1).fn.args = {offset};

scanProc.disp(1).channel = 1;
scanProc.disp(1).dim     = 1;
scanProc.disp(1).loop    = 1;

smprintscan(scanProc);
data = smrun(scanProc, smnext('procfn_scan'));
% data{1} = background-subtracted I in nA

%% procfn with inchan/outchan — combine two channels
% Read I (slot 1) and count (slot 2) at each point.  procfn(1) reads both
% via inchan=[1 2] and writes normalised conductance G=I/count to slot 1.
% procfn(2) passes count through unchanged.
% data{1} = G (A per count),  data{2} = raw count.

scanNorm = struct();
scanNorm.loops(1).rng      = [0.4, 0.8];
scanNorm.loops(1).npoints  = 41;
scanNorm.loops(1).setchan  = 'P';
scanNorm.loops(1).getchan  = {'I', 'Vsd'};
scanNorm.loops(1).ramptime = 0.05;
scanNorm.loops(1).prefn    = struct([]);

% procfn(1): fn called as fn.fn(newdata{1}, newdata{2}) when inchan=[1 2]
scanNorm.loops(1).procfn(1).fn.fn     = @(ids, vsd) ids./(vsd );
scanNorm.loops(1).procfn(1).fn.args   = {};
scanNorm.loops(1).procfn(1).fn.inchan  = [1, 2];
scanNorm.loops(1).procfn(1).fn.outchan = 1;

% procfn(2): passthrough — fn=[] copies newdata{inchan} to newdata{outchan}
scanNorm.loops(1).procfn(2).fn.fn     = [];
scanNorm.loops(1).procfn(2).fn.args   = {};
scanNorm.loops(1).procfn(2).fn.inchan  = 2;
scanNorm.loops(1).procfn(2).fn.outchan = 2;

scanNorm.disp(1).channel = 1;
scanNorm.disp(1).dim     = 1;
scanNorm.disp(1).loop    = 1;

smprintscan(scanNorm);
data = smrun(scanNorm, smnext('procfn_norm_scan'));
% data{1} = I/count (normalised conductance);  data{2} = raw count



%%
plotData()
