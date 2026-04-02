classdef tSmrunBuf < matlab.unittest.TestCase
% Integration tests for buffered acquisition via smrun + smabufconfig2.
%
% Geometry (matching dot_examples.m "Buffered channel scan" pattern):
%   Loop 1 (inner/fast): setchan=S,     getchan=[]      (no read — buffer collects)
%   Loop 2 (outer/slow): setchan=SQ,    getchan=I_buf   (read full buffer per outer step)
%   configfn: smabufconfig2(scan, 'trig arm', [], [], 2)
%
% What smabufconfig2 does with 'trig arm':
%   1. Calls op=5 on I_buf  → sets datadim(I_buf) = n_inner
%   2. Sets loop-1 trigfn   → op=3 trigger at first inner point (clears/resets ibuf)
%   3. Sets loop-2 prefn    → op=4 arm at each outer point (clears ibuf)
%
% What smcqdot op=1 (SET) does:
%   Each smset call on any gate appends the current I to ibuf, so after
%   n_inner steps of S the buffer holds n_inner samples.
%
% Output shape:
%   I_buf is read in loop 2, with datadim = n_inner after configure.
%   dim = [npoints(end:-1:2), datadim] = [n_outer, n_inner]
%   So data{1} is [n_outer x n_inner].

    properties
        ScanFigure = 3;
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

        function scan = makeBufScan(tc, n_inner, n_outer)
        % Build a minimal buffered 2D scan.
        % ramptime = 0 on both loops: no pause between points, but still
        % calls smset (op=1) on S each inner step, appending to ibuf.
            scan.loops(1).rng      = linspace(0, 1, n_inner);
            scan.loops(1).npoints  = n_inner;
            scan.loops(1).setchan  = smchanlookup('S');
            scan.loops(1).getchan  = [];
            scan.loops(1).ramptime = 0.001;
            scan.loops(1).prefn    = struct([]);

            scan.loops(2).rng      = linspace(0, 1, n_outer);
            scan.loops(2).npoints  = n_outer;
            scan.loops(2).setchan  = smchanlookup('SQ');
            scan.loops(2).getchan  = smchanlookup('I_buf');
            scan.loops(2).ramptime = 0.001;

            scan.configfn.fn   = @smabufconfig2;
            scan.configfn.args = {'trig arm', [], [], 2};

            scan.figure   = tc.ScanFigure;
            scan.saveloop = 2;
        end

    end

    methods (Test)

        % --- Basic return value checks ---

        function returnsNonEmptyCell(tc)
            scan = tc.makeBufScan(4, 3);
            data = smrun(scan);
            tc.verifyNotEmpty(data);
            tc.verifyClass(data, 'cell');
        end

        function outputShapeIsOuterByInner(tc)
            n_inner = 5;
            n_outer = 4;
            scan = tc.makeBufScan(n_inner, n_outer);
            data = smrun(scan);
            tc.verifySize(data{1}, [n_outer, n_inner]);
        end

        function allValuesAreFinite(tc)
            scan = tc.makeBufScan(4, 3);
            data = smrun(scan);
            tc.verifyTrue(all(isfinite(data{1}(:))));
        end

        function outputIsNotAllNaN(tc)
            scan = tc.makeBufScan(4, 3);
            data = smrun(scan);
            tc.verifyFalse(all(isnan(data{1}(:))));
        end

        % --- Buffer configuration checks ---

        function configureUpdatesDatadim(tc)
            % After smabufconfig2 runs (inside smrun via configfn),
            % datadim for I_buf should equal n_inner.
            n_inner = 6;
            global smdata;
            ibuf_chan_idx = smchanlookup('I_buf');
            ic = smdata.channels(ibuf_chan_idx).instchan;  % [inst, chan]
            inst_n = ic(1);

            scan = tc.makeBufScan(n_inner, 3);
            smrun(scan);

            tc.verifyEqual(smdata.inst(inst_n).datadim(ic(2)), n_inner);
        end

        function bufferSizeMatchesInnerNpoints(tc)
            % ibuf_npts on the instrument should equal n_inner after a scan.
            n_inner = 8;
            global smdata;
            ibuf_chan_idx = smchanlookup('I_buf');
            inst_n = smdata.channels(ibuf_chan_idx).instchan(1);

            scan = tc.makeBufScan(n_inner, 3);
            smrun(scan);

            tc.verifyEqual(smdata.inst(inst_n).data.ibuf_npts, n_inner);
        end

        % --- Data content checks ---

        function bufferedMatchesPointwiseScan(tc)
            % For each outer point (fixed SQ), the buffered I_buf row should
            % be numerically identical to what a pointwise scan returns for I.
            % Both use the same smcqdot model so values must match exactly.
            smset('A1', 1.0); smset('A2', 1.0);
            smset('T1', 1.0); smset('P',  1.0); smset('T2', 1.0);
            smset('Vsd', 1e-3);

            n_inner = 5;
            n_outer = 3;
            rng_inner = linspace(0.4, 0.9, n_inner);
            rng_outer = linspace(0.6, 0.9, n_outer);

            % --- Buffered scan ---
            scanBuf = tc.makeBufScan(n_inner, n_outer);
            scanBuf.loops(1).rng = rng_inner;
            scanBuf.loops(2).rng = rng_outer;
            dataBuf = smrun(scanBuf);

            % --- Pointwise 2D scan (same geometry) ---
            smtest.SmchdataFixture.wipe();
            smtest.SmchdataFixture.initWithQdot();

            smset('A1', 1.0); smset('A2', 1.0);
            smset('T1', 1.0); smset('P',  1.0); smset('T2', 1.0);
            smset('Vsd', 1e-3);

            scanPt.loops(1).rng      = rng_inner;
            scanPt.loops(1).npoints  = n_inner;
            scanPt.loops(1).setchan  = smchanlookup('S');
            scanPt.loops(1).getchan  = smchanlookup('I');
            scanPt.loops(1).ramptime = 0;
            scanPt.loops(2).rng      = rng_outer;
            scanPt.loops(2).npoints  = n_outer;
            scanPt.loops(2).setchan  = smchanlookup('SQ');
            scanPt.loops(2).getchan  = [];
            scanPt.loops(2).ramptime = 0;
            scanPt.figure   = tc.ScanFigure;
            scanPt.saveloop = 1;
            dataPt = smrun(scanPt);

            tc.verifyEqual(dataBuf{1}, dataPt{1}, 'AbsTol', 1e-12, ...
                'Buffered and pointwise scans should give identical I values');
        end

        function currentIncreasesWithGateVoltage(tc)
            % Sanity check: I increases as both S and SQ sweep above threshold.
            smset('A1', 1.0); smset('A2', 1.0);
            smset('T1', 1.0); smset('P',  1.0); smset('T2', 1.0);
            smset('Vsd', 1e-3);

            scan = tc.makeBufScan(6, 4);
            scan.loops(1).rng = linspace(0.4, 1.0, 6);   % S: below → above threshold
            scan.loops(2).rng = linspace(0.7, 1.0, 4);   % SQ: above threshold

            data = smrun(scan);
            I = data{1};

            % Last inner column should be higher than first for every outer row
            for row = 1:size(I, 1)
                tc.verifyTrue(I(row, end) >= I(row, 1));
            end
        end

        % --- Asymmetric sizes ---

        function nonSquareBufScanShape(tc)
            n_inner = 7;
            n_outer = 3;
            scan = tc.makeBufScan(n_inner, n_outer);
            data = smrun(scan);
            tc.verifySize(data{1}, [n_outer, n_inner]);
        end

    end
end
