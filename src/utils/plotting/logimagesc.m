function [out] = logimagesc(x,y,data)
% logimagesc() - make an imagesc() plot with log10 x-axis values
%
% Usage:  >> [out] = logimagesc(x,y,data);
%
% Input:
%   x = vector of x-axis values
%   y = vector of y-axis values
%   data  = matrix of size (y,x)
% Output:
%   out is the imagesc() color plot

% Author: Scott Makeig, SCCN/INC/UCSD, La Jolla, 4/2000

% Copyright (C) 4/2000 Scott Makeig, SCCN/INC/UCSD, scott@sccn.ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Log: logimagesc.m,v $
% Revision 1.1  2002/04/05 17:36:45  jorn
% Initial revision

% 08-07-00 made ydir normal -sm
% 01-25-02 reformated help & license -ad
% 03-23-23 modified by YFY

lx = log10(x); lx = lx(:);
lgx = linspace(lx(1),lx(end),length(lx)); lgx = lgx(:);
[meshx, meshy] = meshgrid(lx,y);
datout = griddata(meshx,meshy,data,lgx,y); % Interpolates scattered data

out = imagesc(lgx,y,datout);
set(gca,'ydir','normal')
set(gca,'XScale','log')
xlim([min(x) max(x)])

end