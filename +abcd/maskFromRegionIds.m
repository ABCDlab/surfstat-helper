function newMask = maskFromRegionIds(regionLabels, regionIds)
%  newMask = abcd.maskFromRegionIds(regionLabels, regionIds, ['optionName',optionValue...])
%
%   Given a loaded atlas regionLabels and a number of region ID numbers, 
%   Gives a new mask which can be combined with previous mask using 
%   mask.*newMask
%

%   
%   Required:
%       regionLabels    regionLabels variable such as that returned by
%                       loadAal78
%       regionIds       a vector list of Ids corresponding to areas in
%                       regionLabels
%
%   Returns:
%       newMask         Vector (logical) of vertices with value 1
%                       for masked regions (matching regionIds) and value 0
%                       for unmasked regions.


newMask = zeros(1,numel(regionLabels.idByVertex));

for id =regionIds(:)'
    assert(any(regionLabels.idByVertex == id), 'No vertex has ID %.0f', id)
    newMask(regionLabels.idByVertex == id) = 1;
end

newMask = logical(newMask);