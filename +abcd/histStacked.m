function [ figureHandle ] = histStacked( valueOfInterest, groupingTerm, groupingTermTitle, valueTitle )
% [ figureHandle ] = histStacked( valueOfInterest, groupingTerm )
%
%   valueOfInterest     A column vector or cell array of numeric data values
%   groupingTerm        A term (SurfStat) or cell array (string) containing the group
%                       membership of the data values
%   groupingTermTitle   A string to label the grouping term in the plot
%   valueTitle          A string to label the type of values being plotted
%
%   Note that there are two different ways of specifying the values/groups:
%       Single column vector with grouping term:
%           values = column vector, e.g. [1; 2; 3; 4]
%           grouping = SurfStat term with categorical values, e.g. term({'GroupA', 'GroupB', 'GroupA', 'GroupB'})
%           Note that in this case, the grouping argument has the same number of items as the values vector
%       Cell array of values with character array of group labels:
%           values = cell array where the groups are already separated, e.g. {[1; 3], [2; 4]}
%           grouping = cell array of strings to label the groups, e.g. {'GroupA', 'GroupB'}
%           Note that in this case, the grouping argument has as many items as the number of groups in the values array
%   Note that the two examples above are equivalent.
%   If your data have the groups already separated, consider using the second method.

if nargin < 4
    valueTitle = '';
end
if nargin < 3
    groupingTermTitle = '';
end

assert(isvector(valueOfInterest), 'valueOfInterest argument must be a vector');
assert(isnumeric(valueOfInterest)|iscell(valueOfInterest), 'valueOfInterest argument must be numeric');

valueOfInterest = valueOfInterest(:); % make sure is column vector

if iscell(valueOfInterest)
    tempGroups = cell(numel(valueOfInterest),1);
    for i=1:numel(valueOfInterest)
        valueOfInterest{i} = valueOfInterest{i}(:); % make sure elements are column vectors
        tempGroups{i} = repmat(groupingTerm{i}(:)', numel(valueOfInterest{i}), 1);
    end
    groupingTerm = term(cellstr(char(tempGroups)));
    valueOfInterest = cell2mat(valueOfInterest(:));
end

if iscellstr(groupingTerm)
    groupingTerm = term(groupingTerm);
end

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
usableElements = ~isnan(valueOfInterest);

[P,ANOVATAB,STATS] = anova1(valueOfInterest(usableElements), groupingTermCellstr(usableElements), 'off');
fprintf('histStacked ANOVA: p=%s (comparing %s)\n', num2str(P), abcd.util.joinCellStr(groupingTermNames, ', '));
ANOVATAB
STATS

% histo - w/ normal fit
figureHandle = figure;
[n,xout] = hist(valueOfInterest);
binwidth=xout(2)-xout(1);
for i = 1:numGroupingTerms
    subplot(numGroupingTerms,1,i);
    values = valueOfInterest(logical(groupingTerm.(groupingTermNames{i})));
    histfit(values);
    xlim([xout(1)-binwidth xout(numel(xout))+binwidth]);
    ylabel('N subjects');
    usableValues = ~isnan(values);
    numNan = sum(~usableValues);
    nanNote = '';
    if numNan > 0
        nanNote = sprintf('  [%d NaN values]', numNan);
    end
    xlabel(sprintf('%s values for %s  (mean %.2f, SD %.2f)%s', valueTitle, groupingTermNames{i}, mean(values(usableValues)), std(values(usableValues)), nanNote), 'Interpreter','none');
    if (i==1)
        title(sprintf('%s\nP = %s', groupingTermTitle, num2str(P)), 'Interpreter','none');
    end
end

end

