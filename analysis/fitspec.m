 function [out] = fitspec(S,f,opts,model)
%fitspec(S,f,opts,model) fits the spectrum S(f) to A/f^b line or a Lorentzian
%   S is PSD (1D vector)
%   f is frequency (1D vector)
%   opts is optional struct that can have fields:
%       opts.fitrng = [fmin fmax] which specifies the frequency fit range

% 2023/5/8 YFY
% Add an 'model' option to fit to either a power law or a Lorentzian
% Default fit to a power law if 'model' is not specified
% 'pow' fits to a power law
% 'L' fits to a Lorentzian

if ~exist('opts','var')
    opts = struct('fitrng',[min(f) max(f)]);
end
frng = opts.fitrng;

if ~exist('model','var')
    model = 'pow'; % default to a power law fit
end

Srow = size(S,1);
if ~Srow
    S = S';
end
frow = size(f,1);
if ~frow
    f = f';
end

% fit
if strcmp(model,'pow') % power law fit A/f^beta

    ffn = @(p,x) p(1) + p(2)*x;
    fitfs = (f>min(frng) & f<max(frng));
    x = f(fitfs);
    y = S(fitfs);
    [~,ind1Hz] = min(abs(f-1));
    guess = [log10(S(ind1Hz)) -1];
    mask = [1 1];
    [params,~,~,~,~,~,se] = fitwrap('plfit',log10(x),log10(y),guess,ffn,mask);
    A = 10^params(1);
    b = -params(2);

    Aerr = mean([abs(A-10^(params(1)-se(1))) abs(A-10^(params(1)+se(1)))]);

    out.ffn = ffn;
    out.A = A;
    out.b = b;
    out.A_err = Aerr;
    out.b_err = se(2);

elseif strcmp(model,'L') % fit to a Lorentzian B/(1+f^2/f0^2)

    ffn = @(p,x) log10( p(1)./(1+(10.^x).^2./p(2).^2) ); % B, f0
    fitfs = (f>min(frng) & f<max(frng));
    x = f(fitfs);
    y = S(fitfs);
    [~,ind1Hz] = min(abs(f-1));
    guess = [S(ind1Hz) min(x)];
    mask = [1 1];
    [params,~,~,~,~,~,se] = fitwrap('plfit',log10(x),log10(y),guess,ffn,mask);
    B = params(1);
    f0 = params(2);

    out.ffn = ffn;
    out.B = B;
    out.f0 = f0;
    out.B_err = se(1);
    out.f0_err = se(2);
    out.amp = B./(1+1./f0.^2); % charge noise at 1 Hz

end

end
