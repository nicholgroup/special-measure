function [oPos] = resizeFig(t, l, b, r)
% resizeFig resizes the figure.
%   resizeFig(t, l, b, r) adds t,l,b,r pixels to a figure on the top, left,
%   bottom, and right.
% written by Alenxander Laut
% https://www.mathworks.com/matlabcentral/answers/423117-how-to-resize-figure-without-moving-contents
fh = gcf();
set(findall(fh,'-property','Units'),'Units', 'pixels');  %%Set Object Sizes to Pixels
set(fh,'position',get(fh,'position')+[-l,-r,l+r,t+b]);    % extends range of figure only
%%Grab Re-Sizeable Objects
objs = findobj(fh,'-property','position');    % grabs all objects with position properties
oPos = get(objs,'position'); % grabs position of moveable objects
if ~iscell(oPos)
    oPos={oPos};
end
ind = cellfun(@(C) size(C,2)==4,oPos);  % finds objects that take 4 vector position input
objs = objs(ind);
oPos = oPos(ind);
%%Resize Objects within Figure
nPos = cellfun(@(C) C+[l,b,0,0],oPos,'uniformoutput',false);  % displace positions left and down
for i = 1:length(objs)
    set(objs(i),'position',nPos{i});%+[dleft,dbot,0,0]);
end
%%Set objects back to normalized/rescaleable
set(findall(fh,'-property','Units'),'Units', 'normalized');
end
