classdef tSmvalidateFilename < matlab.unittest.TestCase
% Tests for smavalidateFilename and its integration with smrun.
%
% Part 1 (TestTags: 'Unit'): Pure validator tests — no SM globals needed.
% Part 2 (TestTags: 'Integration'): Pass filenames into smrun with the
%         smcqdot mock and verify bad names error while a clean name
%         completes the scan.

    properties
        ScanFigure   = 1;
        CleanupFiles = {};   % files to delete in teardown
    end

    methods (TestMethodSetup)
        function setup(tc)
            % Ensure the toolbox (smavalidateFilename) is on the path
            repoRoot = fullfile(fileparts(mfilename('fullpath')), '..');
            addpath(fullfile(repoRoot, 'src', 'utils', 'toolbox'));
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            if ishandle(tc.ScanFigure)
                try; close(tc.ScanFigure); catch; end
            end
            for k = 1:numel(tc.CleanupFiles)
                if isfile(tc.CleanupFiles{k})
                    delete(tc.CleanupFiles{k});
                end
            end
        end
    end

    methods
        function scan = makeScan(tc, setchan, getchan, npoints, rng)
            if nargin < 5
                rng = [0, 1];
            end
            scan.loops(1).rng      = rng;
            scan.loops(1).npoints  = npoints;
            scan.loops(1).setchan  = smchanlookup(setchan);
            scan.loops(1).getchan  = smchanlookup(getchan);
            scan.loops(1).ramptime = 0;
            scan.figure            = tc.ScanFigure;
            scan.saveloop          = 1;
        end

        function setupSmdata(~)
        % Initialize SM globals — called only by integration tests.
            smtest.SmchdataFixture.initWithQdot();
        end

        function teardownSmdata(~)
            smtest.SmchdataFixture.wipe();
        end
    end

    % =====================================================================
    %  Part 1: Unit tests for smavalidateFilename  (no SM globals needed)
    % =====================================================================
    methods (Test, TestTags = {'Unit'})

        % --- Valid names (should pass without error) ---

        function acceptsSimpleName(tc)
            out = smavalidateFilename('my_scan_001');
            tc.verifyEqual(out, 'my_scan_001');
        end

        function acceptsHyphen(tc)
            out = smavalidateFilename('scan-2024-05-14');
            tc.verifyEqual(out, 'scan-2024-05-14');
        end

        function acceptsWithMatExtension(tc)
            out = smavalidateFilename('sm_scan01.mat');
            tc.verifyEqual(out, 'sm_scan01.mat');
        end

        function acceptsPathPrefixWithCleanName(tc)
            name = fullfile('C:', 'data', 'scans', 'sm_test01.mat');
            out = smavalidateFilename(name);
            tc.verifyEqual(out, name);
        end

        function acceptsEmpty(tc)
            out = smavalidateFilename('');
            tc.verifyEqual(out, '');
        end

        % --- Forbidden: period in the bare name ---

        function rejectsPeriodInName(tc)
            tc.verifyError(@() smavalidateFilename('scan.v2'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsPeriodBeforeMat(tc)
            tc.verifyError(@() smavalidateFilename('scan.v2.mat'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsMultiplePeriods(tc)
            tc.verifyError(@() smavalidateFilename('a.b.c.d'), ...
                'smavalidateFilename:badChars');
        end

        % --- Forbidden: shell / OS meta-characters ---

        function rejectsAmpersand(tc)
            tc.verifyError(@() smavalidateFilename('scan&data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsAsterisk(tc)
            tc.verifyError(@() smavalidateFilename('scan*data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsQuestionMark(tc)
            tc.verifyError(@() smavalidateFilename('scan?data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsSpace(tc)
            tc.verifyError(@() smavalidateFilename('scan data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsSingleQuote(tc)
            tc.verifyError(@() smavalidateFilename("scan'data"), ...
                'smavalidateFilename:badChars');
        end

        function rejectsDoubleQuote(tc)
            tc.verifyError(@() smavalidateFilename('scan"data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsAngleBrackets(tc)
            tc.verifyError(@() smavalidateFilename('scan<data>'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsPipe(tc)
            tc.verifyError(@() smavalidateFilename('scan|data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsSemicolon(tc)
            tc.verifyError(@() smavalidateFilename('scan;data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsHash(tc)
            tc.verifyError(@() smavalidateFilename('scan#1'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsPercent(tc)
            tc.verifyError(@() smavalidateFilename('scan%d'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsParentheses(tc)
            tc.verifyError(@() smavalidateFilename('scan(1)'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsBraces(tc)
            tc.verifyError(@() smavalidateFilename('scan{1}'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsBrackets(tc)
            tc.verifyError(@() smavalidateFilename('scan[1]'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsExclamation(tc)
            tc.verifyError(@() smavalidateFilename('scan!data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsAtSign(tc)
            tc.verifyError(@() smavalidateFilename('scan@data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsComma(tc)
            tc.verifyError(@() smavalidateFilename('scan,data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsPlus(tc)
            tc.verifyError(@() smavalidateFilename('scan+data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsEquals(tc)
            tc.verifyError(@() smavalidateFilename('scan=data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsBacktick(tc)
            tc.verifyError(@() smavalidateFilename('scan`data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsTilde(tc)
            tc.verifyError(@() smavalidateFilename('scan~data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsCaret(tc)
            tc.verifyError(@() smavalidateFilename('scan^data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsDollar(tc)
            tc.verifyError(@() smavalidateFilename('scan$data'), ...
                'smavalidateFilename:badChars');
        end

        function rejectsMultipleForbiddenChars(tc)
            tc.verifyError(@() smavalidateFilename('sc&n*.v2'), ...
                'smavalidateFilename:badChars');
        end

    end

    % =====================================================================
    %  Part 2: Integration with smrun  (needs smdata + smcqdot mock)
    % =====================================================================
    methods (Test, TestTags = {'Integration'})

        function smrunRejectsPeriodFilename(tc)
            tc.setupSmdata();
            cleanup = onCleanup(@() tc.teardownSmdata());
            scan = tc.makeScan('S', 'I', 5);
            tc.verifyError(@() smrun(scan, 'scan.v2'), ...
                'smavalidateFilename:badChars');
        end

        function smrunRejectsAmpersandFilename(tc)
            tc.setupSmdata();
            cleanup = onCleanup(@() tc.teardownSmdata());
            scan = tc.makeScan('S', 'I', 5);
            tc.verifyError(@() smrun(scan, 'scan&test'), ...
                'smavalidateFilename:badChars');
        end

        function smrunRejectsSpaceFilename(tc)
            tc.setupSmdata();
            cleanup = onCleanup(@() tc.teardownSmdata());
            scan = tc.makeScan('S', 'I', 5);
            tc.verifyError(@() smrun(scan, 'scan test'), ...
                'smavalidateFilename:badChars');
        end

        function smrunAcceptsCleanFilenameAndRuns(tc)
            tc.setupSmdata();
            cleanup = onCleanup(@() tc.teardownSmdata());

            cleanName = 'test_clean_scan_001';
            expectedFile = sprintf('sm_%s.mat', cleanName);
            tc.CleanupFiles{end+1} = expectedFile;

            scan = tc.makeScan('S', 'I', 5);
            data = smrun(scan, cleanName);

            % Scan should complete and return valid data
            tc.verifyNotEmpty(data);
            tc.verifyClass(data, 'cell');
            tc.verifySize(data{1}, [5 1]);
            tc.verifyTrue(all(isfinite(data{1}(:))));

            % Output file should exist with the expected name
            tc.verifyTrue(isfile(expectedFile), ...
                sprintf('Expected output file %s was not created', expectedFile));
        end

    end
end
