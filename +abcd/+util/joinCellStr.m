function [joinedString] = joinCellStr(strings, delimiter)
% [joinedString] = joinCellStr(strings, delimiter)
%
% Example:
%   joinCellStr({'a', 'b', 'c'}, '-')
% produces output 'a-b-c'


joinedString = '';
for s = strings(:)'
    if (numel(joinedString) > 0)
        joinedString = [joinedString delimiter];
    end
    joinedString = [joinedString s{1}];
end

