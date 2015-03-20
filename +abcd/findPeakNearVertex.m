function [ vertexId, xyz, peakValue ] = findPeakNearVertex(varargin)
%   [ vertexId, xyz, peakValue ] = findPeakNearVertex(vertexValues, vertexId, surface, [options])
%
%   Required:
%       vertexValues    Vector of values across all vertices (e.g. T
%                       values)
%       vertexId        The vertex ID to search near
%       surface         The brain surface
%
%   Optional arguments by name:
%       'searchRadiusMm' The search radius in millimeters (default 20)
%       'negative'      If true, will search for negative peaks instead
%                       (default false)
%
%   Returns:
%       vertexId        The vertex ID of the peak value found
%       xyz             A vector of the xyz coordinates of the peak in mm
%       peakValue       The peak value of vertexValues found at vertexId

isSurface = @(x) isstruct(x); % TODO: could be more strict by checking for field names tri and coord
isIntegerNumeric = @(x) isnumeric(x) && (floor(x) == x);
isScalarLogical = @(x) islogical(x) && isscalar(x);
isScalarNumeric = @(x) isnumeric(x) && isscalar(x);

p = inputParser;
p.addRequired('vertexValues', @isvector);
p.addRequired('vertexId', isIntegerNumeric);
p.addRequired('surface', isSurface);
p.addParamValue('negative', false, isScalarLogical);
p.addParamValue('searchRadiusMm', 20, isScalarNumeric);
p.parse(varargin{:});

values = p.Results.vertexValues(:)' .* -2*(single(p.Results.negative) - 0.5);
peakValue = max(values .* double(SurfStatROI(p.Results.vertexId, p.Results.searchRadiusMm, p.Results.surface)));
vertexId = find(values==peakValue, 1);
xyz = SurfStatInd2Coord(vertexId, p.Results.surface);

end

