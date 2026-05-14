function results = runAllTests()
% runAllTests  Run the full special-measure test suite, print a summary,
%   and write a JSON failure report to tests/test_report.json.
%
% Usage (from the repo root):
%   addpath('sm'); addpath('channels'); addpath('examples');
%   cd tests
%   results = runAllTests();
%
% Or from any directory:
%   cd special-measure
%   addpath('sm'); addpath('channels'); addpath('examples'); addpath('tests');
%   results = runAllTests();

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.DiagnosticsRecordingPlugin;

testDir = fileparts(mfilename('fullpath'));
addpath(testDir);

suite = TestSuite.fromFolder(testDir, 'IncludingSubfolders', false);

runner = TestRunner.withTextOutput;
runner.addPlugin(DiagnosticsRecordingPlugin);
results = runner.run(suite);

fprintf('\n--- Summary ---\n');
fprintf('Passed:  %d\n', sum([results.Passed]));
fprintf('Failed:  %d\n', sum([results.Failed]));
fprintf('Skipped: %d\n', sum([results.Incomplete]));

% --- Generate failure report for agent consumption ---
reportPath = fullfile(testDir, 'test_report.json');
failures = results([results.Failed]);
report = struct();
report.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));
report.total = numel(results);
report.passed = sum([results.Passed]);
report.failed = sum([results.Failed]);
report.skipped = sum([results.Incomplete]);
report.failures = cell(1, numel(failures));

for k = 1:numel(failures)
    entry = struct();
    entry.name = failures(k).Name;
    entry.duration = failures(k).Duration;

    diagInfo = {};

    % --- Source 1: DiagnosticRecord from the recording plugin ---
    try
        details = failures(k).Details;
        if isstruct(details) && isfield(details, 'DiagnosticRecord')
            recs = details.DiagnosticRecord;
            for r = 1:numel(recs)
                rec = recs(r);
                evtStr = char(string(rec.Event));
                if contains(evtStr, 'Failed', 'IgnoreCase', true)
                    d = struct();
                    d.event = evtStr;
                    d.report = char(string(rec.Report));
                    diagInfo{end+1} = d; %#ok<AGROW>
                end
            end
        end
    catch
        % Details/DiagnosticRecord not available — fall through
    end

    % --- Source 2: re-run the single failed test, capture text output ---
    if isempty(diagInfo)
        try
            % Reconstruct a suite element from the test name
            testName = failures(k).Name;
            parts = split(testName, '/');
            rerunSuite = matlab.unittest.TestSuite.fromClass( ... %#ok<NASGU>
                meta.class.fromName(parts{1}), ...
                'ProcedureName', parts{2});
            captureRunner = matlab.unittest.TestRunner.withTextOutput; %#ok<NASGU>
            str = evalc('captureRunner.run(rerunSuite);');
            if ~isempty(str)
                d = struct();
                d.event = 'capturedOutput';
                d.report = strtrim(str);
                diagInfo{end+1} = d; %#ok<AGROW>
            end
        catch me
            d = struct();
            d.event = 'rerunError';
            d.identifier = char(me.identifier);
            d.message = char(me.message);
            stackLines = {};
            for s = 1:numel(me.stack)
                stackLines{end+1} = sprintf('%s (line %d)', ...
                    me.stack(s).name, me.stack(s).line); %#ok<AGROW>
            end
            d.stack = strjoin(stackLines, ' -> ');
            diagInfo{end+1} = d; %#ok<AGROW>
        end
    end

    entry.diagnostics = diagInfo;
    report.failures{k} = entry;
end

json = jsonencode(report, 'PrettyPrint', true);
fid = fopen(reportPath, 'w');
fwrite(fid, json);
fclose(fid);
fprintf('Report written to %s\n', reportPath);
end
