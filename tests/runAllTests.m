function results = runAllTests()
% runAllTests  Run the full special-measure test suite and print a summary.
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

testDir = fileparts(mfilename('fullpath'));
addpath(testDir);

suite = TestSuite.fromFolder(testDir, 'IncludingSubfolders', false);

runner = TestRunner.withTextOutput;
results = runner.run(suite);

fprintf('\n--- Summary ---\n');
fprintf('Passed:  %d\n', sum([results.Passed]));
fprintf('Failed:  %d\n', sum([results.Failed]));
fprintf('Skipped: %d\n', sum([results.Incomplete]));
end
