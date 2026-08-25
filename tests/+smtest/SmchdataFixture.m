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

        function addSrcPaths()
        % Put every src/ directory the test suite needs on the MATLAB path.
        %
        % This is the single place source paths are registered — individual
        % test files must not add their own. Tests that need no SM globals
        % (pure numerics, e.g. the fitting wrappers) can call this directly
        % instead of initWithQdot.
            repoRoot = fullfile(fileparts(mfilename('fullpath')), '..', '..');
            addpath(fullfile(repoRoot, 'examples'));
            addpath(fullfile(repoRoot, 'src', 'sm'));
            addpath(fullfile(repoRoot, 'src', 'drivers'));
            addpath(fullfile(repoRoot, 'src', 'utils', 'toolbox'));
            addpath(fullfile(repoRoot, 'src', 'utils', 'analysis'));
        end

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

            smtest.SmchdataFixture.addSrcPaths();

            smcqdot_setup();
            sminitdisp();

            % Close the channel-display figure so smdispchan's drawnow
            % does not block during automated tests.
            if ishandle(999)
                close(999);
            end
        end

        function wipe()
        % Remove smdata entirely so no state bleeds between tests.
            global smdata;
            smdata = [];
            clear global smdata;
        end

    end
end
