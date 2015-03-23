function [regionIds] = findRegionIdsByText(regionLabels, searchText, varargin)
%  [regionIds] = abcd.findRegionIdsByText(regionLabels, searchText, ['optionName',optionValue...])
%
%   Searches a regionLabels structure for regions matching searchText.
%
%   Default search is a case-insensitive substring search of the "nameLong"
%   field.
%   
%   Required:
%       regionLabels    regionLabels variable such as that returned by
%                       loadAal78
%       searchText      Text string to search for in region names
%   
%   Optional:
%       'regexpSearch'  If true, searchText is searched as a regular
%                       expression. If false, searchText is searched as a
%                       substring. (default false)
%       'searchField'   Either 'nameShort' or 'nameLong' (default
%                       'nameLong')
%       'caseSensitive' If true, searches are case-sensitive (default
%                       false)
%       'quiet'         If true, suppresses text output (default false)
%
%   Returns:
%       regionIds       Vector of regionId values

isScalarLogical = @(x) isscalar(x) && islogical(x);

p = inputParser;
p.addParamValue('regexpSearch', false, isScalarLogical);
p.addParamValue('searchField', 'nameLong', @ischar);
p.addParamValue('caseSensitive', false, isScalarLogical);
p.addParamValue('quiet', false, isScalarLogical);
p.parse(varargin{:});

assert(isfield(regionLabels.regions, p.Results.searchField), '%s is not a valid searchField!', p.Results.searchField)

if ~p.Results.quiet
    fprintf('Searching for regions having %s matching "%s"\n', p.Results.searchField, searchText);
end

nameList = {regionLabels.regions.(p.Results.searchField)}';

% fixup any empty names
for i = 1:numel(nameList)
    if isempty(nameList{i})
        nameList{i} = '';
    end
end

if ~p.Results.caseSensitive
    nameList = lower(nameList);
    searchText = lower(searchText);
end

if p.Results.regexpSearch
    regionIds = find(~cellfun('isempty', (regexp(nameList, searchText))))';
else
    regionIds = find(~cellfun('isempty', (strfind(nameList, searchText))))';
end

if ~p.Results.quiet
    for id = regionIds
        fprintf('Region %d matches: %s\n', id, regionLabels.regions(id).(p.Results.searchField));
    end
end


end %end function
