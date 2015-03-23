function [ figureIds ] = viewRegionForVertexId(regionLabels, vertexId, surface, varargin)
%  [ figureIds ] = viewRegionForVertexId(regionLabels, vertexId, surface, [options])
%
%   Plots the location of a vertex and the region containing it
%   
%   Required:
%       regionLabels    A regionLabels variable such as that returned by
%                       loadAal78
%       vertexId        The ID of the vertex of interest (or a vector of
%                       IDs, to make multiple figures)
%       surface         The brain surface used for localization
%
%   Optional arguments by name:
%       surfaceView     The brain surface for visualization (defaults to
%                       same surface as the 'surface' argument)
%
%   Returns:
%       figureIds       The ID(s) of the figures

isSurface = @(x) isstruct(x);

p = inputParser;
p.addParamValue('surfaceView', [], isSurface);
p.parse(varargin{:});

surfacePlot = surface;
if ~isempty(p.Results.surfaceView)
    surfacePlot = p.Results.surfaceView;
end

figureIds = [];

for vertid = vertexId(:)'
    xyz = SurfStatInd2Coord( vertid, surface )';
    
    plotValues = zeros(size(surface.coord,2),1);
    regionId = regionLabels.idByVertex(vertid);
    regionLabelName = '';
    if (regionId ~= 0)
        regionLabelName = regionLabels.regions(regionId).nameLong;
    end
    plotValues(regionLabels.idByVertex == regionId) = 1.3;
    
    dotAroundVertex = SurfStatROI(vertid, 3, surface);
    plotValues(dotAroundVertex) = 2;
    
    fid = figure; SurfStatView(plotValues, surfacePlot, sprintf('Vertex %d (%.1f %.1f %.1f)\n%s region %d: %s', vertid, xyz(1), xyz(2), xyz(3), regionLabels.name, regionId, regionLabelName));
    cmap = spectral; cmap(1,:) = 0.7*[1 1 1];
    colormap(cmap);
    SurfStatColLim([0 2.2]);
    figureIds = [figureIds fid];
    set(fid,'Name', sprintf('v.%d', vertid));

end

end

