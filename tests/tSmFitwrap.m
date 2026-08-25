classdef tSmFitwrap < matlab.unittest.TestCase
% Tests for src/utils/analysis/mfitwrap.m and mfitwrapcon.m
%
% Both wrappers fit several datasets simultaneously against one shared
% parameter vector. These are pure numerics tests: no smdata, no hardware,
% no figures.
%
% IMPORTANT: every call must pass an explicit opts string containing none
% of 'plinit', 'plfit', or 'optimplot'. Both wrappers default opts to
% 'plfit plinit optimplot' when it is omitted, which opens figures 60-63
% and calls drawnow -- that blocks an automated run.

    properties (Constant)
        % Opts string with no plotting flags of any kind.
        NoPlot = '';

        % Tolerance for comparing fitted parameters against truth. Loose
        % enough to survive the solver's stopping criteria, far tighter
        % than the O(1) errors an orientation bug produces.
        FitTol = 1e-5;
    end

    methods (TestClassSetup)
        function addPaths(~)
            smtest.SmchdataFixture.addSrcPaths();
        end
    end

    methods (TestMethodSetup)
        function requireOptim(tc)
        % lsqnonlin ships with the Optimization Toolbox. Skip rather than
        % fail where it is not installed.
            tc.assumeTrue(exist('lsqnonlin','file') > 0, ...
                'lsqnonlin not available (Optimization Toolbox required).');
        end
    end

    methods
        function requireStats(tc)
        % mfitwrapcon's fitting path calls nlparci and tinv to build the
        % standard errors. The 'nofit' path does not.
            tc.assumeTrue(exist('nlparci','file') > 0 && exist('tinv','file') > 0, ...
                'nlparci/tinv not available (Statistics Toolbox required).');
        end
    end

    methods (Static)
        function [d,m] = lineDataset(x, ptrue)
        % One noiseless dataset, y = p(1) + p(2)*x.
            d = struct('x', x, 'y', ptrue(1) + ptrue(2).*x);
            m = struct('fn', @(p,xx) p(1) + p(2).*xx);
        end
    end

    % =====================================================================
    %  Parameter recovery
    % =====================================================================
    methods (Test)

        function recoversLineParameters(tc)
            x = linspace(0,10,50);
            ptrue = [1 2];
            [d,m] = tSmFitwrap.lineDataset(x, ptrue);
            p = mfitwrap(d, m, [0 0], tSmFitwrap.NoPlot, [1 1]);
            tc.verifyEqual(p, ptrue, 'AbsTol', tSmFitwrap.FitTol);
        end

        function recoversGaussianParameters(tc)
            x = linspace(-4,4,80);
            fn = @(p,xx) p(1).*exp(-((xx-p(2))./p(3)).^2);
            ptrue = [2, 0.7, 1.3];              % amplitude, center, width
            d = struct('x', x, 'y', fn(ptrue,x));
            m = struct('fn', fn);

            p = mfitwrap(d, m, [1 0 1], tSmFitwrap.NoPlot, [1 1 1]);

            tc.verifyEqual(p(1), ptrue(1), 'RelTol', 1e-4);
            tc.verifyEqual(p(2), ptrue(2), 'AbsTol', 1e-4);
            % The width enters squared, so its sign is not observable.
            tc.verifyEqual(abs(p(3)), ptrue(3), 'RelTol', 1e-4);
        end

        function sharesParameterAcrossDatasets(tc)
        % The point of mfitwrap: one slope shared by both datasets, each
        % with its own offset, all in a single parameter vector.
            x = linspace(0,5,40);
            slope = 2; off1 = 1; off2 = -3;

            d(1).x = x; d(1).y = slope.*x + off1;
            d(2).x = x; d(2).y = slope.*x + off2;
            m(1).fn = @(p,xx) p(1).*xx + p(2);
            m(2).fn = @(p,xx) p(1).*xx + p(3);

            p = mfitwrap(d, m, [0 0 0], tSmFitwrap.NoPlot, [1 1 1]);
            tc.verifyEqual(p, [slope off1 off2], 'AbsTol', tSmFitwrap.FitTol);
        end

        function chisqIsScalarAndNearZeroForExactFit(tc)
            x = linspace(0,10,50);
            [d,m] = tSmFitwrap.lineDataset(x, [1 2]);
            [~, chisq] = mfitwrap(d, m, [0 0], tSmFitwrap.NoPlot, [1 1]);
            tc.verifyTrue(isscalar(chisq));
            tc.verifyLessThan(abs(chisq), 1e-8);
        end

    end

    % =====================================================================
    %  Shape and orientation contracts
    %
    %  The residual vector is built by concatenating (fd-y)./sqrt(sy) over
    %  datasets. If fd and y disagree in orientation, implicit expansion
    %  turns the residual into an N-by-N matrix -- lsqnonlin still runs and
    %  returns a plausible but wrong answer, with no error or warning.
    % =====================================================================
    methods (Test)

        function orientationDoesNotChangeResult(tc)
            ptrue = [1 2];
            fn = @(p,xx) p(1) + p(2).*xx;
            xr = linspace(0,10,50);         % row
            xc = xr(:);                     % column

            % {x orientation, orientation of the x used to build y}
            combos = {xr, xr; xr, xc; xc, xr; xc, xc};
            labels = {'row x, row y', 'row x, column y', ...
                      'column x, row y', 'column x, column y'};

            results = zeros(4,2);
            for k = 1:4
                d = struct('x', combos{k,1}, 'y', fn(ptrue, combos{k,2}));
                m = struct('fn', fn);
                results(k,:) = mfitwrap(d, m, [0 0], tSmFitwrap.NoPlot, [1 1]);
            end

            for k = 1:4
                tc.verifyEqual(results(k,:), ptrue, 'AbsTol', tSmFitwrap.FitTol, ...
                    sprintf('Wrong fit for %s.', labels{k}));
            end
        end

        function columnModelOutputWithRowData(tc)
        % A model that always returns a column, fed row data. This is the
        % orientation mismatch that does not depend on how the caller
        % shaped x and y.
            x = linspace(0,10,50);                          % row
            ptrue = [1 2];
            d = struct('x', x, 'y', ptrue(1) + ptrue(2).*x);% row
            m = struct('fn', @(p,xx) p(1) + p(2).*xx(:));   % column

            p = mfitwrap(d, m, [0 0], tSmFitwrap.NoPlot, [1 1]);
            tc.verifyEqual(p, ptrue, 'AbsTol', tSmFitwrap.FitTol);
        end

        function mismatchedLengthsError(tc)
        % A genuine length mismatch must throw rather than silently
        % expand into a matrix of residuals.
            d = struct('x', linspace(0,10,20), 'y', linspace(0,10,9));
            m = struct('fn', @(p,xx) p(1) + p(2).*xx);
            tc.verifyError(@() mfitwrap(d, m, [0 0], tSmFitwrap.NoPlot, [1 1]), ...
                ?MException);
        end

    end

    % =====================================================================
    %  Masking and weighting
    % =====================================================================
    methods (Test)

        function maskHoldsParameterFixed(tc)
            x = linspace(0,10,50);
            [d,m] = tSmFitwrap.lineDataset(x, [1 2]);
            p0 = [5 0];

            p = mfitwrap(d, m, p0, tSmFitwrap.NoPlot, [0 1]);

            % Masked-out parameter must come back untouched, exactly.
            tc.verifyEqual(p(1), p0(1));
            tc.verifyNotEqual(p(2), p0(2));
        end

        function covIsFullSizeWithMaskedParameter(tc)
            x = linspace(0,10,50);
            [d,m] = tSmFitwrap.lineDataset(x, [1 2]);

            [~, ~, cov] = mfitwrap(d, m, [5 0], tSmFitwrap.NoPlot, [0 1]);

            tc.verifySize(cov, [2 2]);
            tc.verifyEqual(cov(1,1), 0);        % masked out, no covariance
            tc.verifyGreaterThan(cov(2,2), 0);
        end

        function varianceWeightingDownweightsOutlier(tc)
            x = linspace(0,10,21);
            ptrue = [1 2];
            y = ptrue(1) + ptrue(2).*x;
            y(11) = y(11) + 50;                 % x(11) == 5 == mean(x)

            m = struct('fn', @(p,xx) p(1) + p(2).*xx);

            % Equal weights: the outlier drags the intercept by ~50/21.
            pEq = mfitwrap(struct('x',x,'y',y), m, [0 0], ...
                tSmFitwrap.NoPlot, [1 1]);
            tc.verifyGreaterThan(abs(pEq(1) - ptrue(1)), 1);

            % Large variance on that point: it is effectively ignored.
            vy = ones(size(x)); vy(11) = 1e8;
            pW = mfitwrap(struct('x',x,'y',y,'vy',vy), m, [0 0], ...
                tSmFitwrap.NoPlot, [1 1]);
            tc.verifyEqual(pW, ptrue, 'AbsTol', 1e-3);
        end

    end

    % =====================================================================
    %  mfitwrapcon: bounds and the nofit path
    % =====================================================================
    methods (Test)

        function conRecoversLineParameters(tc)
            tc.requireStats();
            x = linspace(0,10,50);
            ptrue = [1 2];
            [d,m] = tSmFitwrap.lineDataset(x, ptrue);

            p = mfitwrapcon(d, m, [0 0], [-10 -10], [10 10], ...
                tSmFitwrap.NoPlot, [1 1]);
            tc.verifyEqual(p, ptrue, 'AbsTol', tSmFitwrap.FitTol);
        end

        function conRespectsUpperBound(tc)
            tc.requireStats();
            x = linspace(0,10,50);
            [d,m] = tSmFitwrap.lineDataset(x, [1 2]);   % true slope is 2
            ubSlope = 1.5;

            p = mfitwrapcon(d, m, [0 0], [-10 -10], [10 ubSlope], ...
                tSmFitwrap.NoPlot, [1 1]);

            tc.verifyLessThanOrEqual(p(2), ubSlope + 1e-8);
            tc.verifyEqual(p(2), ubSlope, 'AbsTol', 1e-4);  % pinned to the bound
        end

        function conNofitReturnsScalarChisq(tc)
        % The nofit branch computes chisq by hand instead of fitting.
        % Note: it never assigns cov, so at most two outputs may be asked for.
            x = linspace(0,10,25);
            [d,m] = tSmFitwrap.lineDataset(x, [1 2]);
            pGuess = [3 2];                     % intercept off by exactly 2

            [p, chisq] = mfitwrapcon(d, m, pGuess, [-10 -10], [10 10], ...
                'nofit', [1 1]);

            tc.verifyEqual(p, pGuess);          % nofit must not move the parameters
            tc.verifyTrue(isscalar(chisq));
            tc.verifyEqual(chisq, 4, 'AbsTol', 1e-10);   % mean(2^2)
        end

        function conNofitHandlesColumnModelOutput(tc)
        % Same as above but with a model returning a column against row
        % data. Before the shape fix this produced a 25-by-25 residual and
        % chisq came back as a 1-by-25 row of column means.
            x = linspace(0,10,25);                          % row
            d = struct('x', x, 'y', 1 + 2.*x);              % row
            m = struct('fn', @(p,xx) p(1) + p(2).*xx(:));   % column
            pGuess = [3 2];

            [~, chisq] = mfitwrapcon(d, m, pGuess, [-10 -10], [10 10], ...
                'nofit', [1 1]);

            tc.verifyTrue(isscalar(chisq));
            tc.verifyEqual(chisq, 4, 'AbsTol', 1e-10);
        end

    end
end
