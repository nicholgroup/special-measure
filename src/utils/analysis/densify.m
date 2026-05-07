function [densex,densey,fitparams] = densify(x,y,ffn,guess,npt)
%densify increases the density of points.
%
%densify(x,y,ffn,guess) takes in x and y vectors, fits them to ffn using
%guess, and then creates a dense linear space from min(x) to min(y) with points npt, and
%calculates densey by feeding densex into ffn

[x,idx] = sort(x);
y = y(idx);
ps = fitwrap('plinit plfit',x,y,guess,ffn);

densex = linspace(min(x),max(x),npt);
densey = ffn(ps,densex);
fitparams = ps;

end

