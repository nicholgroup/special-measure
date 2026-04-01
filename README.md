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
├── sm/          # Core framework: smrun, smset, smget, and ~41 supporting functions
├── channels/    # Instrument drivers (~123 files, named smc*.m, one per instrument model)
├── plot/        # Analysis and visualization utilities
└── sm GUI/      # Optional GUIDE-based GUI (smgui.m)
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
