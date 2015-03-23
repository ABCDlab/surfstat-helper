function newMask = maskFromRegionIds(regionLabels, regionIds, varargin)
%  newMask = abcd.maskFromRegionIds(regionLabels, regionIds, ['optionName',optionValue...])
%
%   Given a loaded atlas regionLabels and a number of region ID numbers, 
%   Gives a new mask (1x81924 logical) which can be combined with previous
%   mask using mask.*newMask
%

%   
%   Required:
%       regionLabels    regionLabels variable such as that returned by
%                       loadAal78
%       regionIds       a vector list of Ids corresponding to areas in
%                       regionLabels
%
%   Returns:
%       newMask         Vector (1x81924 logical) of vertices with value 0
%                       for masked regions (matching regionIds) and value 1
%                       for unmasked regions.

isScalarLogical = @(x) isscalar(x) && islogical(x);

p = inputParser;
p.parse(varargin{:});


newMask = ones(1,81924);

for id =regionIds
    assert(~isempty(find((regionLabels.idByVertex == id),1)), 'No vertex has ID %.0f', id)
    newMask(regionLabels.idByVertex == id) = 0;
end