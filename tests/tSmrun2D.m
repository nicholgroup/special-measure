classdef tSmrun2D < matlab.unittest.TestCase
% Integration tests for sm/smrun.m — 2D scan with the smcqdot mock.
%
% Geometry (matching dot_examples.m "Channel scan" pattern):
%   Loop 1 (inner/fast): setchan=S,  getchan=I
%   Loop 2 (outer/slow): setchan=SQ, getchan=[]
%
% Output shape:
%   smrun allocates data{1} as  dim = [npoints(end:-1:1), datadim]
%   For 2 loops, npoints = [n_inner, n_outer]:
%     npoints(end:-1:1) = [n_outer, n_inner]
%   So data{1} is [n_outer x n_inner].

    properties
        ScanFigure = 2;
    end

    methods (TestMethodSetup)
        function setup(tc)
            smtest.SmchdataFixture.initWithQdot();
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            if ishandle(tc.ScanFigure)
                try; close(tc.ScanFigure); catch; end
            end
            smtest.SmchdataFixture.wipe();
        end
    end

    methods

        function scan = makeScan2D(tc, n_inner, n_outer)
        % Minimal valid 2D scan: inner loop sweeps S and reads I,
        % outer loop steps SQ without reading.
            scan.loops(1).rng      = linspace(0, 1, n_inner);
            scan.loops(1).npoints  = n_inner;
            scan.loops(1).setchan  = smchanlookup('S');
            scan.loops(1).getchan  = smchanlookup('I');
            scan.loops(1).ramptime = 0;

            scan.loops(2).rng      = linspace(0, 1, n_outer);
            scan.loops(2).npoints  = n_outer;
            scan.loops(2).setchan  = smchanlookup('SQ');
            scan.loops(2).getchan  = [];
            scan.loops(2).ramptime = 0;

            scan.figure   = tc.ScanFigure;
            scan.saveloop = 1;
        end

    end

    methods (Test)

        % --- Basic return value checks ---

        function returnsNonEmptyCell(tc)
            scan = tc.makeScan2D(4, 3);
            data = smrun(scan);
            tc.verifyNotEmpty(data);
            tc.verifyClass(data, 'cell');
        end

        function outputShapeIsOuterByInner(tc)
            n_inner = 5;
            n_outer = 4;
            scan = tc.makeScan2D(n_inner, n_outer);
            data = smrun(scan);
            tc.verifySize(data{1}, [n_outer, n_inner]);
        end

        function allValuesAreFinite(tc)
            scan = tc.makeScan2D(4, 3);
            data = smrun(scan);
            tc.verifyTrue(all(isfinite(data{1}(:))));
        end

        function outputIsNotAllNaN(tc)
            scan = tc.makeScan2D(4, 3);
            data = smrun(scan);
            tc.verifyFalse(all(isnan(data{1}(:))), ...
                'Output should not be all NaN — smrun must have filled data array');
        end

        % --- Data content checks ---

        function currentIncreasesAlongInnerAxis(tc)
            % For each fixed SQ (outer loop row), I should increase as S
            % sweeps from below to above threshold.
            smset('A1', 1.0); smset('A2', 1.0);
            smset('T1', 1.0); smset('P',  1.0); smset('T2', 1.0);
            smset('Vsd', 1e-3);
            % SQ held above threshold by outer loop sweeping 0.5->1.0
            scan = tc.makeScan2D(6, 3);
            scan.loops(2).rng = linspace(0.7, 1.0, 3);  % SQ above threshold

            data = smrun(scan);
            I = data{1};   % [n_outer x n_inner]

            % Check each row: current at rightmost S point >= current at leftmost
            for row = 1:size(I, 1)
                tc.verifyTrue(I(row, end) >= I(row, 1), ...
                    sprintf('Row %d: I should be non-decreasing as S increases', row));
            end
        end

        function currentIncreasesAlongOuterAxis(tc)
            % For each fixed S column, I should increase as SQ increases
            % from below to above threshold.
            smset('A1', 1.0); smset('A2', 1.0);
            smset('T1', 1.0); smset('P',  1.0); smset('T2', 1.0);
            smset('Vsd', 1e-3);
            % S held above threshold by inner loop sweeping 0.7->1.0
            scan = tc.makeScan2D(4, 5);
            scan.loops(1).rng = linspace(0.7, 1.0, 4);  % S above threshold
            scan.loops(2).rng = linspace(0, 1, 5);       % SQ sweeps through threshold

            data = smrun(scan);
            I = data{1};   % [n_outer x n_inner]

            % Check each column: last row (high SQ) >= first row (low SQ)
            for col = 1:size(I, 2)
                tc.verifyTrue(I(end, col) >= I(1, col), ...
                    sprintf('Col %d: I should be non-decreasing as SQ increases', col));
            end
        end

        % --- Asymmetric dimensions ---

        function nonSquareScanShape(tc)
            n_inner = 7;
            n_outer = 3;
            scan = tc.makeScan2D(n_inner, n_outer);
            data = smrun(scan);
            tc.verifySize(data{1}, [n_outer, n_inner]);
        end

        function singleOuterPointGivesOneRow(tc)
            scan = tc.makeScan2D(5, 1);
            data = smrun(scan);
            tc.verifySize(data{1}, [1, 5]);
        end

        function singleInnerPointGivesOneColumn(tc)
            scan = tc.makeScan2D(1, 4);
            data = smrun(scan);
            tc.verifySize(data{1}, [4, 1]);
        end

    end
end
