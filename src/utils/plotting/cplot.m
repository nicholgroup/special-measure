function [out] = cplot(x,y,z)
%wrapper function for better imagesc(x,y,z)

if (~exist('y','var') | ~exist('z','var'))
    out = imagesc(x); set(gca,'YDir','normal');
else
    out = imagesc(x,y,z); set(gca,'YDir','normal');
end

end

