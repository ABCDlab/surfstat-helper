function [ figureHandle ] = histStacked( valueOfInterest, groupingTerm, groupingTermName )
% [ figureHandle ] = histStacked( valueOfInterest, groupingTerm )
% 
%   valueOfInterest     A column vector of numeric data values
%   groupingTerm        A term (SurfStat) containing the group membership
%                       of the data values

assert(isvector(valueOfInterest), 'valueOfInterest argument must be a vector');
assert(isnumeric(valueOfInterest), 'valueOfInterest argument must be numeric');

valueOfInterest = valueOfInterest(:); % make sure is column vector

assert(isa(groupingTerm, 'term'), 'groupingTerm argument must be a term variable');
assert(size(groupingTerm,1)==numel(valueOfInterest), 'valueOfInterest and groupingTerm must have the same number of items');

groupingTermNames = char(groupingTerm);
numGroupingTerms = numel(groupingTermNames);

% t test
groupingTermCellstr = cell(numel(valueOfInterest),1);
for iG=1:numGroupingTerms
    thisGroupingTermName = groupingTermNames{iG};
    thisGroupingTermValues = groupingTerm.(thisGroupingTermName);
    for i=1:numel(valueOfInterest)
        if (thisGroupingTermValues(i))
            groupingTermCellstr{i} = thisGroupingTermName;
        end
    end
end
[P,ANOVATAB,STATS] = anova1(valueOfInterest, groupingTermCellstr, 'off');
P

% histo - w/ normal fit
figureHandle = figure; 
[n,xout] = hist(valueOfInterest);
binwidth=xout(2)-xout(1);
for i = 1:numGroupingTerms
    subplot(numGroupingTerms,1,i);
    histfit(valueOfInterest(logical(groupingTerm.(groupingTermNames{i}))));
    xlim([xout(1)-binwidth xout(numel(xout))+binwidth]);
    ylabel('N subjects');
    xlabel(['values for ' groupingTermNames{i}]);
    if (i==1)
        title(sprintf('%s\nP = %s', groupingTermName, num2str(P)));
    end
end

end

