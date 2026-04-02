classdef tSmgetSmset < matlab.unittest.TestCase
% Integration tests for sm/smset.m and sm/smget.m using the smcqdot mock.
%
% smcqdot_setup registers 11 channels:
%   1:S  2:SQ  3:A1  4:A2  5:T1  6:P  7:T2  8:Vsd  9:I  10:count  11:I_buf
%
% Note: 'I' and 'count' are read-only channels in the qdot model — their
% values are computed from gate voltages.  S, SQ, A1, A2, T1, P, T2, Vsd
% are writable gate/bias channels that support set+get round-trips.

    methods (TestMethodSetup)
        function setup(tc)
            smtest.SmchdataFixture.initWithQdot();
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            smtest.SmchdataFixture.wipe();
        end
    end

    methods (Test)

        % --- smget basic behaviour ---

        function getReturnsCell(tc)
            result = smget('S');
            tc.verifyClass(result, 'cell');
        end

        function getCellHasCorrectLength(tc)
            result = smget({'S', 'SQ', 'Vsd'});
            tc.verifyLength(result, 3);
        end

        function getByIndexMatchesByName(tc)
            v_name  = smget('S');
            v_index = smget(1);
            tc.verifyEqual(v_name{1}, v_index{1});
        end

        % --- smset + smget round-trips ---

        function setAndGetRoundTrip(tc)
            smset('S', 0.5);
            val = smget('S');
            tc.verifyEqual(val{1}, 0.5, 'AbsTol', 1e-10);
        end

        function setNegativeValue(tc)
            smset('SQ', -0.3);
            val = smget('SQ');
            tc.verifyEqual(val{1}, -0.3, 'AbsTol', 1e-10);
        end

        function setZero(tc)
            smset('Vsd', 0.0);
            val = smget('Vsd');
            tc.verifyEqual(val{1}, 0.0, 'AbsTol', 1e-10);
        end

        function multipleChannelsRetainValues(tc)
            smset('S',   0.7);
            smset('SQ',  0.8);
            smset('Vsd', 1e-3);
            s   = smget('S');
            sq  = smget('SQ');
            vsd = smget('Vsd');
            tc.verifyEqual(s{1},   0.7,  'AbsTol', 1e-10);
            tc.verifyEqual(sq{1},  0.8,  'AbsTol', 1e-10);
            tc.verifyEqual(vsd{1}, 1e-3, 'AbsTol', 1e-12);
        end

        function setByIndexRoundTrip(tc)
            smset(2, 0.4);           % channel 2 = SQ
            val = smget(2);
            tc.verifyEqual(val{1}, 0.4, 'AbsTol', 1e-10);
        end

        function secondSetOverwritesFirst(tc)
            smset('A1', 0.2);
            smset('A1', 0.9);
            val = smget('A1');
            tc.verifyEqual(val{1}, 0.9, 'AbsTol', 1e-10);
        end

        function setCellArrayChannels(tc)
            % smset accepts a cell array of channel names.
            smset({'T1', 'T2'}, [0.3, 0.6]);
            t1 = smget('T1');
            t2 = smget('T2');
            tc.verifyEqual(t1{1}, 0.3, 'AbsTol', 1e-10);
            tc.verifyEqual(t2{1}, 0.6, 'AbsTol', 1e-10);
        end

        % --- cross-channel isolation ---

        function settingOneChannelDoesNotAffectAnother(tc)
            smset('S',  0.5);
            smset('P',  0.1);
            smset('S',  0.9);        % change S again
            p = smget('P');
            tc.verifyEqual(p{1}, 0.1, 'AbsTol', 1e-10, ...
                'P should be unchanged after re-setting S');
        end

    end
end
