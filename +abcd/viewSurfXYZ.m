function [ figureHandle ] = viewSurfXYZ( surf, points, radius )
%  viewSurfXYZ( surface, points, radius )
%   
%  points is a matrix in the format [x y z; x y z; ...], i.e. each point is
%  a row
%
%  Default point radius is 5 mm

tagmask = false(size(surf.coord,2));

if (nargin < 3), radius = 5; end

for i = 1:size(points,1)
    vertex = SurfStatCoord2Ind(points(i,:), surf);
    tagmask(SurfStatROI( vertex, radius, surf )) = true;
end

figureHandle = figure;
SurfStatView(tagmask, surf);

end

