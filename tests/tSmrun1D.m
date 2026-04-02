classdef tSmrun1D < matlab.unittest.TestCase
% Integration tests for sm/smrun.m — 1D scan with the smcqdot mock.
%
% These tests verify that smrun executes without error and returns data with
% the expected shape and content.  They do NOT require physical instruments.
%
% Key setup choices:
%   ramptime = 0   — disables all pause() calls, keeping tests fast
%   scan.figure    — uses a specific figure number so teardown can close it
%   smrun(scan)    — no filename arg, so no file I/O or logentry calls
%   scan.disp omitted — no live plot channels, figure opened but empty

    properties
        ScanFigure = 1;   % figure number used in all tests
    end

    methods (TestMethodSetup)
        function setup(tc)
            smtest.SmchdataFixture.initWithQdot();
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            % Close any figures smrun opened.
            if ishandle(tc.ScanFigure)
                try; close(tc.ScanFigure); catch; end
            end
            smtest.SmchdataFixture.wipe();
        end
    end

    methods

        function scan = makeScan(tc, setchan, getchan, npoints, rng)
        % Build a minimal valid scan struct for a 1D sweep.
        %
        % smrun only requires rng, setchan, and getchan per loop.
        % All other loop fields have safe defaults inside smrun.
            if nargin < 5
                rng = [0, 1];
            end
            scan.loops(1).rng      = rng;
            scan.loops(1).npoints  = npoints;
            scan.loops(1).setchan  = smchanlookup(setchan);
            scan.loops(1).getchan  = smchanlookup(getchan);
            scan.loops(1).ramptime = 0;     % no pause between points
            scan.figure            = tc.ScanFigure;
            scan.saveloop          = 1;     % save every point of loop 1
        end

    end

    methods (Test)

        % --- Basic return value checks ---

        function returnsNonEmptyCell(tc)
            scan = tc.makeScan('S', 'I', 5);
            data = smrun(scan);
            tc.verifyNotEmpty(data);
            tc.verifyClass(data, 'cell');
        end

        function outputShapeMatchesNpoints(tc)
            npoints = 7;
            scan = tc.makeScan('S', 'I', npoints);
            data = smrun(scan);
            tc.verifySize(data{1}, [npoints 1]);
        end

        function allValuesAreFinite(tc)
            scan = tc.makeScan('S', 'I', 5);
            data = smrun(scan);
            tc.verifyTrue(all(isfinite(data{1}(:))), ...
                'All returned data values should be finite numbers');
        end

        % --- Different channel combinations ---

        function sweepSQReadI(tc)
            scan = tc.makeScan('SQ', 'I', 4);
            data = smrun(scan);
            tc.verifySize(data{1}, [4 1]);
        end

        function sweepVsdReadI(tc)
            % Bias voltage sweep — I should scale with Vsd.
            scan = tc.makeScan('Vsd', 'I', 5, [-1e-3, 1e-3]);
            data = smrun(scan);
            tc.verifySize(data{1}, [5 1]);
            tc.verifyTrue(all(isfinite(data{1}(:))));
        end

        % --- Data content checks ---

        function currentIncreasesWithGateVoltage(tc)
            % Physical sanity check: as S sweeps above threshold, I increases.
            % Open all other gates so S is the only limiting channel.
            smset('SQ', 1.0); smset('A1', 1.0); smset('A2', 1.0);
            smset('T1', 1.0); smset('P',  1.0); smset('T2', 1.0);
            smset('Vsd', 1e-3);

            scan = tc.makeScan('S', 'I', 8, [0.2, 1.0]);
            data = smrun(scan);

            I = data{1}(:);
            tc.verifyTrue(I(end) >= I(1), ...
                'Current should be non-decreasing as S sweeps through threshold');
        end

        function currentIsZeroWhenGateBelowThreshold(tc)
            % With S well below threshold, I should be zero.
            smset('Vsd', 1e-3);
            % Set all gates to 0 (below typical threshold ~0.6 V).
            smset({'SQ','A1','A2','T1','P','T2'}, zeros(1,6));

            scan = tc.makeScan('S', 'I', 3, [0.0, 0.1]);
            data = smrun(scan);

            tc.verifyTrue(all(data{1}(:) < 1e-12), ...
                'Current should be zero when all gates are below threshold');
        end

        % --- Scan parameter variations ---

        function singlePointScan(tc)
            scan = tc.makeScan('S', 'I', 1);
            data = smrun(scan);
            tc.verifySize(data{1}, [1 1]);
        end

        function largerNpointsGivesCorrectShape(tc)
            npoints = 20;
            scan = tc.makeScan('S', 'I', npoints);
            data = smrun(scan);
            tc.verifySize(data{1}, [npoints 1]);
        end

    end
end
