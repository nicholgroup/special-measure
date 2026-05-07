function errorBox(x,y,epsx,epsy)
%see https://stackoverflow.com/questions/15008705/how-to-create-a-shaded-error-bar-box-for-a-scatterplot-in-r-or-matlab

%# make sure inputs are all column vectors
x = x(:); y = y(:); epsx = epsx(:); epsy = epsy(:);

%# define the corner points of the error boxes
errBoxX = [x-epsx, x-epsx, x+epsx, x+epsx];
errBoxY = [y-epsy, y+epsy, y+epsy, y-epsy];

%# plot the transparant errorboxes
fill(errBoxX',errBoxY','b','FaceAlpha',0.3,'EdgeAlpha',0)
end