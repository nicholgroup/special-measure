classdef SmchdataFixture
% SmchdataFixture  Shared helper for initializing and wiping global smdata.
%
% All test files that touch smdata should call these static methods in their
% TestMethodSetup and TestMethodTeardown blocks to prevent state leakage
% between tests.
%
% Usage:
%   methods (TestMethodSetup)
%       function setup(tc)
%           smtest.SmchdataFixture.initWithQdot();
%       end
%   end
%   methods (TestMethodTeardown)
%       function teardown(tc)
%           smtest.SmchdataFixture.wipe();
%       end
%   end

    methods (Static)

        function initWithQdot()
        % Initialize smdata and register the smcqdot mock instrument.
        % smcqdot_setup() correctly populates datadim, type, and channels.
            global smdata;
            smdata          = struct();
            smdata.inst     = struct([]);
            smdata.channels = struct([]);
            smdata.configch = [];
            smdata.configfn = [];
            smdata.chanvals = [];

            % Make sure src/sm/ and examples/ are on the path.
            repoRoot = fullfile(fileparts(mfilename('fullpath')), '..', '..');
            addpath(fullfile(repoRoot, 'examples'));
            addpath(fullfile(repoRoot, 'src', 'sm'));
            addpath(fullfile(repoRoot, 'src', 'utils', 'toolbox'));

            smcqdot_setup();
            sminitdisp();
        end

        function wipe()
        % Remove smdata entirely so no state bleeds between tests.
            global smdata;
            smdata = [];
            clear global smdata;
        end

    end
end
