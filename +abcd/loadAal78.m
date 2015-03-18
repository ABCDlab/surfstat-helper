function [ aal_78 ] = loadAal78()
%loadAal78 loads data about the 78 cortical AAL regions
%
%   Returns a structure containing:
%       regions: List of regions where items 1-90 are the full set of AAL
%                regions, with the 78 cortical regions containing full
%                information and the remaining non-cortcal regions being
%                blank. The index of each element is the AAL region ID, and
%                the value is a structure containing:
%
%           nameShort:  Abbreviated region name
%           nameLong:   Full region name
%           centroid:   3x1 vector containing x, y, z coordinates of center
%                       of region
%           id:         The AAL region ID
%
%       idByVertex: List of AAL region IDs for each of 81924 brain surface
%                   vertices. Vertices with no AAL mapping are coded as 99.
%       wmDistance: Average white matter tract distance between pairs of
%                   regions. Distances between non-cortical regions are
%                   NaN.

% region(i).splitHemisphereId:
% idFromSplitHemisphereId

aalDir = which('abcd.buildNumber'); % slighty hackish
aalDir = [aalDir(1:numel(aalDir)-13) '/aal/'];

aalVertexLabels = load([aalDir 'aal_labels_78']);
aalCentroids = load([aalDir 'aal_centroids_78']);
wmDistance = load([aalDir 'aal_distances_wm_78']);
fid=fopen([aalDir 'AAL_78_tabdelim_NF.txt']); aal_78_ids=textscan(fid, '%d %s %s', 78, 'Delimiter', '\t'), fclose(fid);

aal_78 = [];

for i = 1:numel(aal_78_ids{1})
    id = aal_78_ids{1}(i);
    aal_78.regions(id).nameShort = aal_78_ids{2}{i};
    aal_78.regions(id).nameLong = aal_78_ids{3}{i};
    aal_78.regions(id).centroid = aalCentroids.centroids(:,i);
    aal_78.regions(id).splitHemisphereId = i;
    aal_78.regions(id).id = id;
    aal_78.idFromSplitHemisphereId(i) = id;
    %aal_78.centroids(:,id) = aalCentroids.centroids(:,i);
end
aal_78.regions(99).nameShort = 'UNKNOWN';
aal_78.regions(99).nameLong = 'UNKNOWN';

aal_78.wmDistance = nan(90,90);
aal_78.wmDistance(aal_78.idFromSplitHemisphereId(:),aal_78.idFromSplitHemisphereId(:)) = wmDistance.aal_dist;

label_map_to_id = aal_78_ids{1};
label_map_to_id(99) = 99;
label_map_from_vx = aalVertexLabels.aal_labels;
label_map_from_vx(label_map_from_vx==0) = 99;
aal_78.idByVertex = label_map_to_id(label_map_from_vx)';

% Make empty cells into '' or 0, to deal with indexing problems.

for cell = 1:length(aal_78.regions)
    if ~ischar(aal_78.regions(cell).nameLong)
        aal_78.regions(cell).nameLong = '';
    end
end
for cell = 1:length(aal_78.regions)
    if ~ischar(aal_78.regions(cell).nameShort)
        aal_78.regions(cell).nameShort = '';
    end
end
for cell = 1:length(aal_78.regions)
    if isempty(aal_78.regions(cell).id)
        aal_78.regions(cell).id = 0;
    end
end



end

