classdef tSmchanlookup < matlab.unittest.TestCase
% Tests for sm/smchanlookup.m
%
% smchanlookup converts channel names (string, char, cell) or numeric
% indices to a column vector of numeric indices into smdata.channels.

    methods (TestMethodSetup)
        function setup(tc)
            smtest.SmchdataFixture.initWithQdot();
            % smcqdot_setup registers 11 channels:
            %   1:S  2:SQ  3:A1  4:A2  5:T1  6:P  7:T2
            %   8:Vsd  9:I  10:count  11:I_buf
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            smtest.SmchdataFixture.wipe();
        end
    end

    methods (Test)

        function numericScalarPassthrough(tc)
            % A scalar numeric input is returned as a 1x1 column vector.
            result = smchanlookup(3);
            tc.verifyEqual(result, 3);
        end

        function numericRowBecomesColumn(tc)
            % A numeric row vector is transposed to a column vector.
            result = smchanlookup([1 3 5]);
            tc.verifyEqual(result, [1; 3; 5]);
        end

        function numericColumnUnchanged(tc)
            % A numeric column vector is returned as-is.
            result = smchanlookup([2; 4]);
            tc.verifyEqual(result, [2; 4]);
        end

        function charSingleName(tc)
            % A single channel name as a char resolves to its index.
            idx = smchanlookup('S');
            tc.verifyEqual(idx, 1);
        end

        function charAnotherName(tc)
            idx = smchanlookup('I');
            tc.verifyEqual(idx, 9);
        end

        function cellArrayLookup(tc)
            % A cell array of names resolves to a column vector of indices.
            idx = smchanlookup({'S', 'T1', 'I'});
            tc.verifyEqual(idx, [1; 5; 9]);
        end

        function cellSingleElement(tc)
            idx = smchanlookup({'Vsd'});
            tc.verifyEqual(idx, 8);
        end

        function unknownNameThrowsError(tc)
            % An unrecognized channel name must raise an error.
            try
                smchanlookup('does_not_exist');
                tc.verifyFail('Expected an error for unknown channel name.');
            catch e
                tc.verifyTrue(contains(e.message, 'Unable to find'), ...
                    'Error message should mention "Unable to find"');
            end
        end

        function resultIsColumnVector(tc)
            % Output is always a column (n x 1) regardless of input form.
            result = smchanlookup({'S', 'SQ', 'A1'});
            tc.verifySize(result, [3 1]);
        end

    end
end
