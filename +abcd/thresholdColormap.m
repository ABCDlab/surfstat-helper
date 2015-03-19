function cm = thresholdColormap(varargin)
% thresholdColormap returns a colormap matrix that can be passed to the matlab
% colormap function.
%
% The colormap consists of one or more solid colors at specific values
% (i.e. thresholds). This is useful when you want one color to indicate values
% above X, and another to indicate values above another lesser value Y, etc.
%
% Example:  A colormap with red>8, orange for 5-8, and green for 2.5-5
%
%   colormap(abcd.thresholdColormap([2.5 5 8], 'mirrorToNegative', false));
%
% Note that whatever "limit" thresholds you use when calling this function,
% you ALSO need to set the actual color bar limits with those same values.
% This function doesn't/can't do that for you.
%
% Arguments:
% varargin        Parameters customizing the colormap
%                       'thresholds': vector of 1, 2 or 3 values corresponding
%                          to "first", "second" and "limit" thresholds.
%                          Note that if num values < 3, "first" is omitted first,
%                          then "second" (default [3 4 5])
%                       'mirrorToNegative' [boolean]: if negative thesholds
%                          should be automatically included (default true)
%                       'colorNegLimit': 3 value vector, color for most
%                          negative threshold (default [1 0 1] i.e. purple)
%                       'colorNegSecond': 3 value vector, color for second
%                          negative threshold (default [0 1 1] i.e. cyan)
%                       'colorNegFirst': 3 value vector, color for first
%                          negative threshold (default [0 0 1] i.e. blue)
%                       'colorZero': 3 value vector, color for values
%                           closer to zero than the first threshold(s)
%                           (default [0.8 0.8 0.8] i.e. light gray)
%                       'colorPosFirst': 3 value vector, color for first
%                          positive threshold (default [0 0.7 0] i.e. green)
%                       'colorPosSecond': 3 value vector, color for second
%                          positive threshold (default [1 0.5 0] i.e. orange)
%                       'colorPosLimit': 3 value vector, color for most
%                          positive threshold (default [1 0 0] i.e. red)
%                       'numLevels': more levels increases precision of
%                          thresholds (default 256)


p = inputParser;
p.addOptional('thresholds',        [3 4 5], @(x) isnumeric(x) && isvector(x) && length(x)<=3);
p.addParamValue('mirrorToNegative',  true, @(x) islogical(x));
p.addParamValue('colorNegLimit',     [1 0 1], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('colorNegSecond',    [0 1 1], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('colorNegFirst',     [0 0 1], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('colorZero',    0.8.*[1 1 1], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('colorPosFirst',     [0 0.7 0], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('colorPosSecond',    [1 0.5 0], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('colorPosLimit',     [1 0 0], @(x) isnumeric(x) && isvector(x) && length(x)==3);
p.addParamValue('numLevels',     	256, @(x) isnumeric(x) && isscalar(x));
p.parse(varargin{:});

thresholds = fliplr(p.Results.thresholds(:)');
numThresholds = length(thresholds);

stops = [...
    -1*thresholds(1)                    p.Results.colorNegLimit(:)'; ...
    -1*thresholds(min(2,numThresholds)) p.Results.colorNegSecond(:)'; ...
    -1*thresholds(min(3,numThresholds)) p.Results.colorNegFirst(:)'; ...
    0                                   p.Results.colorZero(:)'; ...
    thresholds(min(3,numThresholds))    p.Results.colorPosFirst(:)'; ...; ...
    thresholds(min(2,numThresholds))    p.Results.colorPosSecond(:)'; ...
    thresholds(1)                       p.Results.colorPosLimit(:)'; ...
];

useStops = true(7,1);

if ~p.Results.mirrorToNegative
    useStops(1:3) = false;
end
if (length(p.Results.thresholds) < 3)
    useStops([3 5]) = false;
end
if (length(p.Results.thresholds) < 2)
    useStops([2 6]) = false;
end

stops = stops(useStops,:);

nc = p.Results.numLevels;

cm = zeros(nc,3);

for i = 1:nc
    thisVal = stops(1,1) + (i-1)/(nc-1)*(stops(end,1) - stops(1,1));
    thisColor = [0 0 0];
    for s = 1:size(stops,1)
        if (stops(s,1) <= 0  &&  thisVal <= stops(s,1))
            thisColor = stops(s,2:4);
            break;
        elseif (stops(s,1) >= 0  &&  thisVal >= stops(s,1)  &&  (s == size(stops,1) || thisVal < stops(s+1,1)))
            thisColor = stops(s,2:4);
            break;
        end
    end
    cm(i,:) = thisColor;
end


end
