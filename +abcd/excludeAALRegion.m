function [mask] = excludeAALRegion(region, currentMask)
% --EXCLUDE AN AAL REGION--
% Masks out an area of choice (like ones that don't pass QC)
% region: a string that specifies AAL region(s) (e.g. 'Insula').
%     to get a region in one hemisphere only, type e.g. 'Left Insula'
%     to get more than one region, type e.g. 'Parietal' 
% currentMask: the current mask (will be combined with the new mask so you 
% don't lose any areas already masked)

disp('Masking all regions matching:')
disp(region)

% load the variable aal_78_ids and assigns more information to the struct aal_info
% TODO: put this loop in the loadAal78 script so there won't be further
% indexing problems...
aal_info = abcd.loadAal78;
for cell = 1:length(aal_info.regions)
    if ~ischar(aal_info.regions(cell).nameLong)
        aal_info.regions(cell).nameLong = '';
    end
end
for cell = 1:length(aal_info.regions)
    if ~ischar(aal_info.regions(cell).nameShort)
        aal_info.regions(cell).nameShort = '';
    end
end
for cell = 1:length(aal_info.regions)
    if isempty(aal_info.regions(cell).id)
        aal_info.regions(cell).id = 0;
    end
end
% get index for AAL names that match the region
nameListLong = {aal_info.regions.nameLong}';
idx = ~cellfun('isempty', (regexpi(nameListLong, region)));
% extract ids from aal_info.regions.id corresponding to region
roiIds = [aal_info.regions(idx).id];
% logical map of vertices in aal_info.idByVertex that have one of these ids
roiBoolverts = zeros(length(aal_info.idByVertex),1);
for roid = roiIds
    roiBoolverts = roiBoolverts | (aal_info.idByVertex == roid)';
end
% next: multiply current mask by the inverse of this logical map
newMask = ~roiBoolverts;
mask = logical(currentMask .* newMask');

end %end function
