classdef tSmscanpar < matlab.unittest.TestCase
% Tests for sm/smscanpar.m
%
% smscanpar adjusts the center, range span, and npoints of scan loop(s).
% The smset call at the end (for scan.consts) is bypassed by setting
% scan.consts = struct([]), so these tests need no smdata or hardware.

    methods (Static)
        function scan = basicScan(rng, npoints)
        % Return a minimal scan struct with one loop and no consts/configfn.
            scan.loops(1).rng     = rng;
            scan.loops(1).npoints = npoints;
            scan.consts           = struct([]);
        end
    end

    methods (Test)

        function centerShiftsMidpoint(tc)
            scan = tSmscanpar.basicScan([-0.5, 0.5], 11);
            scan = smscanpar(scan, 1.0, [], []);
            tc.verifyEqual(mean(scan.loops(1).rng), 1.0, 'AbsTol', 1e-12);
        end

        function centerPreservesSpan(tc)
            % Shifting the center must not change the span.
            span_before = 1.0;
            scan = tSmscanpar.basicScan([0.0, span_before], 5);
            scan = smscanpar(scan, 5.0, [], []);
            span_after = scan.loops(1).rng(2) - scan.loops(1).rng(1);
            tc.verifyEqual(span_after, span_before, 'AbsTol', 1e-12);
        end

        function rangeAdjustsSpan(tc)
            scan = tSmscanpar.basicScan([0, 1], 5);
            scan = smscanpar(scan, [], 2, [],1);
            span = scan.loops(1).rng(2) - scan.loops(1).rng(1);
            tc.verifyEqual(span, 2.0, 'AbsTol', 1e-12);
        end

        function rangePreservesMidpoint(tc)
            % Changing the range must keep the midpoint fixed.
            scan = tSmscanpar.basicScan([0, 1], 5);
            mid_before = mean(scan.loops(1).rng);
            scan = smscanpar(scan, [], 4.0, []);
            tc.verifyEqual(mean(scan.loops(1).rng), mid_before, 'AbsTol', 1e-12);
        end

        function npointsUpdated(tc)
            scan = tSmscanpar.basicScan([0, 1], 5);
            scan = smscanpar(scan, [], [], 20,1);
            tc.verifyEqual(scan.loops(1).npoints, 20);
        end

        function emptyArgsLeaveFieldsUnchanged(tc)
            scan = tSmscanpar.basicScan([-1, 1], 7);
            scan = smscanpar(scan, [], [], []);
            tc.verifyEqual(scan.loops(1).rng,     [-1, 1]);
            tc.verifyEqual(scan.loops(1).npoints, 7);
        end

        function multiLoopCenterShiftsBothLoops(tc)
            scan.loops(1).rng     = [-1, 1];
            scan.loops(1).npoints = 3;
            scan.loops(2).rng     = [-1, 1];
            scan.loops(2).npoints = 3;
            scan.consts           = struct([]);
            scan = smscanpar(scan, [2, 3], [], [1,2]);
            tc.verifyEqual(mean(scan.loops(1).rng), 2.0, 'AbsTol', 1e-12);
            tc.verifyEqual(mean(scan.loops(2).rng), 3.0, 'AbsTol', 1e-12);
        end

        function multiLoopRangeAdjustsBothLoops(tc)
            scan.loops(1).rng     = [0, 1];
            scan.loops(1).npoints = 3;
            scan.loops(2).rng     = [0, 1];
            scan.loops(2).npoints = 3;
            scan.consts           = struct([]);
            scan = smscanpar(scan, [0.5, 0.5], [2, 4], []);
            span1 = scan.loops(1).rng(2) - scan.loops(1).rng(1);
            span2 = scan.loops(2).rng(2) - scan.loops(2).rng(1);
            tc.verifyEqual(span1, 2.0, 'AbsTol', 1e-12);
            tc.verifyEqual(span2, 4.0, 'AbsTol', 1e-12);
        end

    end
end
