function [ out ] = fitSpinBump( t,sb,beta0 )
%fitSpinBump(t,sb,beta0) fits a spin bump.
% fits sb (signal in mV) as a function of t (time in us) to t/tau
% fit fn: p(1) + p(2)*(x./p(3)).*exp(-x./p(3))
% returns tunnel time
% beta0 is optional guess for p (default is beta0 = [sb(1) max(sb) 5];)

if size(sb,2) > 1
    sb = sb';
end

if size(t,1) > 1
    t = t';
end

x = t;
y = sb;

fitfn = @(p,x) p(1) + p(2)*(x./p(3)).*exp(-x./p(3));
if ~exist('beta0','var')
    beta0 = [sb(1) max(sb) 5];
end
beta = fitwrap('plfit', x, y', beta0, fitfn);

out = struct;
out.fitfn = fitfn(beta,x);
out.beta = beta;
out.ttime = beta(3);

end

