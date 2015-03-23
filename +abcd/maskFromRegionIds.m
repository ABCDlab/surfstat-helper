function mask = maskFromRegionIds(regionLabels, regionIds)
%  mask = abcd.maskFromRegionIds(regionLabels, regionIds)
%
%   Given a loaded atlas regionLabels and one or more region ID numbers,
%   returns a logical mask of all vertices contained within these regions.
%
%   The returned mask can be combined (intersected) with a previous mask
%   using previousMask.*mask, or excluded from the previous mask using
%   previousMask .* ~mask.
%
%   Required:
%       regionLabels    regionLabels variable such as that returned by
%                       loadAal78
%       regionIds       a vector list of Ids corresponding to areas in
%                       regionLabels
%
%   Returns:
%       mask         Vector (logical) of vertices with value true
%                       for masked regions (matching one of the regionIds)
%                       and value false for unmasked regions.


mask = false(1,numel(regionLabels.idByVertex));

for id = regionIds(:)'
    assert(any(regionLabels.idByVertex == id), 'No vertex has ID %.0f', id)
    mask(regionLabels.idByVertex == id) = true;
end
