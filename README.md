# Special Measure

A MATLAB framework for automated laboratory instrument control and data acquisition. Special Measure lets you define multi-dimensional parameter scans, control real instruments over GPIB/VISA/Serial, acquire data in real-time, and save results as `.mat` files — all from a structured scan definition.

Originally developed by Hendrik Bluhm and Vivek Venkatachalam. Licensed under the [GNU General Public License v3](https://www.gnu.org/licenses/gpl-3.0.html).

---

## Prerequisites

- MATLAB R2014b or later
- [Instrument Control Toolbox](https://www.mathworks.com/products/instrument.html) — required for VISA, GPIB, and Serial communication

---

## Repository Structure

```
special-measure/
├── src/
    ├── sm/          # Core framework: smrun, smset, smget, and ~41 supporting functions
    ├── drivers/    # Instrument drivers (~123 files, named smc*.m, one per instrument model)
    ├── utils
        ├── plotting/        # plotting utilities
        ├── toolbox/        # sma utilities
        └── analysis/       # Analysis utilities
├── tests/
├── examples/
└── gui/      # Optional GUIDE-based GUI (smgui.m) 
```

---

## Overview

The core workflow is:

1. **Configure instruments** — register instruments and their channels in the global `smdata` struct
2. **Define a scan** — build a `scan` struct describing loops, channels to set/read, ramp timing, and display preferences
3. **Run the scan** — call `smrun(scan, filename)`, which steps through all loop points, sets output channels, reads input channels, and saves data incrementally

---

## Quick Start

```matlab
% Load instrument configuration
smloadinst('my_instruments.mat');
smopen;  % open all hardware connections

% Define a 1D scan: sweep gate voltage, read lock-in X
scan.loops(1).setchan  = {'Gate'};
scan.loops(1).getchan  = {'LockInX'};
scan.loops(1).rng      = [-0.5, 0.5];
scan.loops(1).npoints  = 101;
scan.loops(1).ramptime = 0.05;  % 50 ms per point

scan.disp(1).channel = 1;
scan.disp(1).dim     = 1;

data = smrun(scan, smnext('gate_sweep'));
```

---

## Core Functions

| Function                                       | Description                                                            |
| ---------------------------------------------- | ---------------------------------------------------------------------- |
| `smrun(scan, filename)`                      | Execute a scan. Loops over all points, sets/reads channels, saves data |
| `smset(channels, vals)`                      | Set one or more channels to target values (with optional ramp rate)    |
| `smget(channels)`                            | Read current values from one or more channels                          |
| `smopen(inst)`                               | Open hardware connections for instruments                              |
| `smclose(inst)`                              | Close hardware connections                                             |
| `smloadinst(file)`                           | Load instrument configuration from a `.mat` file                     |
| `smsaveinst(file)`                           | Save current instrument configuration                                  |
| `smnext(name)`                               | Return the next auto-incremented filename (e.g.`myscan_0042`)        |
| `smchanlookup(name)`                         | Resolve channel name string to numeric index                           |
| `smscanpar(scan, cntr, rng, npoints, loops)` | Adjust scan loop center, range, and point count                        |
| `smprintscan(scan)`                          | Print a human-readable summary of scan parameters                      |

---

## Scan Struct Reference

`smrun` takes a `scan` struct with the following fields:

```
scan.loops      — array of loop structs (index 1 = fastest/innermost loop)
scan.disp       — display configuration (which channels to plot live)
scan.saveloop   — [loop_index, stride] controlling when data is saved to disk
scan.trafofn    — global coordinate transformation functions
scan.configfn   — function(s) called before the scan starts
scan.cleanupfn  — function(s) called after the scan ends
scan.consts     — channels to set to fixed values before scanning
scan.figure     — figure number for live display (NaN = auto)
```

Each `scan.loops(i)` entry has:

```
.setchan    — channel(s) to sweep (names or indices)
.getchan    — channel(s) to read at each point
.rng        — [start, stop] or explicit vector of values
.npoints    — number of points (if rng is [start, stop])
.ramptime   — seconds per step; negative = initialize-only (ramp to end at first point)
.trafofn    — transform function(s) mapping loop coordinate to channel value
.prefn      — function(s) called before setting channels each step
.postfn     — function(s) called after reading channels
.procfn     — per-channel data processing functions
.trigfn     — hardware trigger function (called after programming ramps)
.waittime   — additional wait time after ramping
.settle     — settle time after setting channels at first loop point
```

---

## Instrument Drivers

The `channels/` directory contains 126+ instrument-specific driver files (`smc*.m`). Each driver implements a control function called by `smset`/`smget` via `smdata.inst(i).cntrlfn`.

Supported hardware includes:

- **Lock-in amplifiers**: SR810, SR830, SR715, SR760, ZIMFIA
- **Signal generators**: TSG4106A, N5183A, RSSMb100a
- **Oscilloscopes**: TDS5104, LeCroy
- **DACs / ADCs**: Yokogawa, Decada, NI DAQ cards
- **Magnet controllers**: AMI420
- **RF sources and mixers**: various custom configurations
- **Multiplexers / custom lab hardware**: Keithley 7001, and others

---

## Data Files

Scan data is saved as MATLAB `.mat` files with the prefix `sm_`:

```
sm_gate_sweep_0042.mat
```

Each file contains:

- `data` — cell array of acquired data arrays (one per read channel per loop)
- `scan` — the full scan definition used
- `configvals` / `configch` — snapshot of configuration channel values at scan start
- `smdata_novisa` — instrument registry (with VISA objects replaced by property structs)

Use `smnext('label')` to get the next available filename and copy it to the clipboard.

---

## Plotting and Analysis

The `plot/` directory contains standalone utilities for visualizing and post-processing scan data:

| Function                              | Description                                                                                       |
| ------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `plotData(file)`                    | Primary plotting utility; auto-detects 1D vs 2D data and opens a file picker if no argument given |
| `fitwrap(ctrl, x, y, beta0, model)` | Wrapper around `nlinfit` for nonlinear curve fitting with optional plot output                  |
| `ana_avg(filename, opts)`           | Load, average, and summarize data from one or more scan files                                     |
| `pptplot`                           | GUI dialog for exporting figures directly to a PowerPoint file                                    |

---

## GUI

`sm GUI/smgui.m` provides a graphical interface for configuring instruments, building scans, and launching runs without writing scan structs by hand. Launch it with:

```matlab
smgui
```

The GUI initializes the `smaux` global variable on startup and provides interactive channel editing via `smguichannels`.

---

## Logging

```matlab
logentry(filename);          % create a log entry for a scan file
logadd('some note');         % append text to the current log entry
lognote('freeform note');    % add a standalone note
logsetfile('mylog.txt');     % set the active log file
```

---

## Keyboard Shortcuts During a Scan

| Key        | Action                                                                             |
| ---------- | ---------------------------------------------------------------------------------- |
| `Escape` | Abort scan, save partial data, run cleanup function                                |
| `Space`  | Pause scan and drop into MATLAB debugger (`keyboard`); type `return` to resume |

---

## Global State

Special Measure uses three MATLAB global variables:

- `smdata` — instrument registry, channel definitions, current values, display handles
- `smscan` — scan struct used as a fallback when `smrun` is called with only a filename; set by the GUI, not by `smrun` itself
- `smaux` — auxiliary GUI state (data directory, PPT output file, run counter); populated by `smgui` on startup

### `smdata` Fields

| Field          | Description                                                                                          |
| -------------- | ---------------------------------------------------------------------------------------------------- |
| `inst`         | Struct array of registered instruments. See [Instrument Struct](#instrument-struct) below.           |
| `channels`     | Struct array of logical channels. Each entry has `.name`, `.instchan` ([inst_idx, chan_idx]), and `.rangeramp` ([min, max, ramprate, divider]). |
| `chandisph`    | Handle to the uicontrol text object in figure 999 that displays live channel values (set by `sminitdisp`). |
| `chanvals`     | Cached numeric values of all channels; updated by `smset`/`smget` and used to refresh the display.  |
| `configch`     | Indices of channels whose values are snapshotted at scan start and saved in each data file.          |
| `configfn`     | Function handle (or struct with `.fn`/`.args`) executed when `smrun` is called, before the scan starts. Also saved in each data file. |
| `name`         | Human-readable label for the current experimental setup or session.                                  |
| `file`         | Path to the currently loaded smdata configuration file; used by `smload` and `smcopy` to track the active config. |

#### Instrument Struct

Each `smdata.inst(i)` entry has:

```
.name       — human-readable instrument name
.device     — device type string (used by smabufconfig2 and similar helpers)
.cntrlfn    — function handle: cntrlfn([inst, chan, op], val, rate)
.channels   — cell array of channel name strings for this instrument
.data       — arbitrary instrument state (VISA object, calibration, buffer state, etc.)
.datadim    — vector of output sizes per channel (1 = scalar; N = buffered array of length N)
```


# Installation
1. Download and install git.
2. First clone the repository.  Open the git command line. Use the "cd" command to navigate to the place you want to download the repo. Then type 
`git clone https://github.com/nicholgroup/special-measure.git`
3. You need an instrument control toolbox. (i.e., the National Instruments or Tektronix drivers). This will typically be achieved in you install NI 488.2, for example.
4. Open matlab, and add the repo directory with all subfolders to your path.
5. Make sure the sm and sm/channels directories are in the path.
6. Make smdata accessible from the workspace by typing `global smdata;` This is necessary only once per Matlab session, or after a `clear global` command.

# Basic Github 
Github allows us to work on the software as a team and keep track of changes made. First, open the git shell. To tell the git shell who you are, type 

`git config --global user.name` or `git config --global  user.email`

where you should replace `user.name` or `user.email` with your github name or email address.

If you want to make sure your local clone is up to date, pull in changes from the repository. Type

`git pull`

Suppose you made some changes and want to commit these changes to the repo. To stage all changes, type

`git add -A`

To commit all of these changes, type

`git commit -m "message describing changes"`

Finally, to upload your changes to the server, type

`git push origin master`

Ordinarily, if you are making big changes, you should work in a separate branch, which can later be merged with the master branch in a pull request. In this case, before you commit, you should make and commit to a new branch using `git checkout`. That way, you can safely make changes without affecting the master. Once you are happy that all changes do not break any code, you can open a pull request.

If working on a shared computer, you can remove your profile from the git shell by typing

`git config --global --unset user.name` or `git config --global --unset user.email`

See http://dont-be-afraid-to-commit.readthedocs.io/en/latest/git/commandlinegit.html, and many other github tutorials for more details.

# Contributing

We use the matlab style guide, found here: https://www.mathworks.com/matlabcentral/fileexchange/46056-matlab-style-guidelines-2-0?requestedDomain=www.mathworks.com

All changes should be documented.
