% test_plotData.m
% Manual regression test for src/utils/plotting/plotData.m
%
% HOW TO RUN (from the repo root):
%   run('tests/manual/test_plotData.m')
%
% BEFORE RUNNING — copy scan .mat files into tests/manual/fixtures/:
%   scan1d.mat  —  a 1-D scan (required)
%   scan2d.mat  —  a 2-D scan (optional)
%
% This file is intentionally excluded from runAllTests (which does not
% recurse into subdirectories). Run it manually after editing plotData.


addpath('tests\manual\');
thisDir=fileparts(which('test_plotData.m'));
repoRoot = fileparts(fileparts(thisDir));
addpath(fullfile(repoRoot, 'src', 'utils', 'plotting'));

fixtureDir = fullfile(thisDir, 'fixtures');

%% --- Test 1: 1-D scan ---

fixture1d = fullfile(fixtureDir, 'scan1d.mat');

if ~isfile(fixture1d)
    fprintf('[SKIP] Test 1 (1-D): copy a 1-D scan .mat to:\n       %s\n\n', fixture1d);
else
    fprintf('=== Test 1: 1-D scan ===\n');
    close all;

    out = plotData(fixture1d);

    % Struct fields
    assert(isfield(out, 'xvals'),    'out.xvals missing');
    assert(isfield(out, 'yvals'),    'out.yvals missing');
    assert(isfield(out, 'filename'), 'out.filename missing');
    assert(~isempty(out(1).xvals),   'xvals is empty');

    % Figure and axes
    f222 = findobj(0, 'Type', 'figure', 'Number', 222);
    assert(~isempty(f222), 'Figure 222 was not created');
    ax = findobj(f222, 'Type', 'axes');
    assert(~isempty(ax), 'No axes found in figure 222');
    assert(~isempty(ax(1).XLabel.String), 'X-axis has no label');
    assert(~isempty(ax(1).YLabel.String), 'Y-axis has no label');

    fprintf('[PASS] Programmatic checks.\n');
    fprintf('[LOOK] Figure 222 — expect:\n');
    fprintf('         line plot, x = sweep channel, y = measured channel\n');
    fprintf('         axis labels match channel names, legend shows filename\n\n');
    fprintf('[LOOK] Figure 1 — expect:\n');
    fprintf('         filename and configvals.\n');
end

%% --- Test 2: 2-D scan ---

fixture2d = fullfile(fixtureDir, 'scan2d.mat');

if ~isfile(fixture2d)
    fprintf('[SKIP] Test 2 (2-D): copy a 2-D scan .mat to:\n       %s\n\n', fixture2d);
else
    fprintf('=== Test 2: 2-D scan ===\n');
    close all;

    out = plotData(fixture2d);

    assert(isfield(out, 'xvals'), 'out.xvals missing');
    assert(isfield(out, 'yvals'), 'out.yvals missing');
    assert(isfield(out, 'data'),  'out.data missing');

    f222 = findobj(0, 'Type', 'figure', 'Number', 222);
    assert(~isempty(f222), 'Figure 222 was not created');
    ax = findobj(f222, 'Type', 'axes');
    assert(~isempty(ax), 'No axes found in figure 222');

    fprintf('[PASS] Programmatic checks.\n');
    fprintf('[LOOK] Figure 222 — expect:\n');
    fprintf('         imagesc color map, x = fast axis, y = slow axis\n');
    fprintf('         colorbar present, title is the filename\n\n');
    fprintf('[LOOK] Figure 1 — expect:\n');
    fprintf('         filename and configvals.\n');
end

%% --- Test 3: filename with periods (e.g. scan1D.ver_period.mat) ---

fixture_period = fullfile(fixtureDir, 'scan1D.ver_period.mat');

if ~isfile(fixture_period)
    fprintf('[SKIP] Test 3 (period in name): copy fixture to:\n       %s\n\n', fixture_period);
else
    fprintf('=== Test 3: filename with periods ===\n');
    close all;

    out = plotData(fixture_period);

    assert(isfield(out, 'xvals'),    'out.xvals missing');
    assert(isfield(out, 'yvals'),    'out.yvals missing');
    assert(isfield(out, 'filename'), 'out.filename missing');
    assert(~isempty(out(1).xvals),   'xvals is empty');

    f222 = findobj(0, 'Type', 'figure', 'Number', 222);
    assert(~isempty(f222), 'Figure 222 was not created');

    fprintf('[PASS] Programmatic checks — period-in-filename loaded correctly.\n');
    fprintf('[LOOK] Figure 222 — expect same output as a normal 1-D scan.\n\n');
end

%% --- Test 4: filename with periods, passed WITHOUT .mat extension ---

if ~isfile(fixture_period)
    fprintf('[SKIP] Test 4 (period, no ext): fixture missing.\n\n');
else
    fprintf('=== Test 4: period in name, extension omitted ===\n');
    close all;

    % Strip the .mat extension so oneNotePrep must re-append it
    fixture_no_ext = erase(fixture_period, '.mat');
    out = plotData(fixture_no_ext);

    assert(isfield(out, 'xvals'),    'out.xvals missing');
    assert(~isempty(out(1).xvals),   'xvals is empty');

    fprintf('[PASS] oneNotePrep correctly appended .mat despite periods in name.\n\n');
end

fprintf('Done. Inspect any open figures, then close when satisfied.\n');
