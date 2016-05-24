function [ Yresidualized ] = residualizeViaModel( varargin )
% Given observation and a model, estimates the model and returns the
% residuals. Useful to factor out the effects of covariates.
% 
% [ Yresidualized ] = residualizeViaModel( Y, Model, ['optionName', optionValue ...] )
%
% Required:
%   Y               2D matrix of values where rows are observations,
%                   columns are datasets (e.g. vertices)
%   Model           Model containing all covariates against which to
%                   residualize
%
% Optional:
%   'preserveMean'  default true
%   'meanMask'      logical vector indexing which datasets (Y columns) from
%                   which to calculate the mean value to be added back to
%                   residuals
%
% Note that the precision of the Y matrix will be preserved, so if you pass
% in single precision data, you will get single precision data out.

isTerm = @(x) isa(x, 'term');
isScalarLogical = @(x) islogical(x) && isscalar(x);
isVectorLogical = @(x) islogical(x) && isvector(x);

p = inputParser;
p.addRequired('Y', @ismatrix);
p.addRequired('Model', isTerm);
p.addParamValue('preserveMean', true, isScalarLogical);
p.addParamValue('meanMask', [], isVectorLogical);
p.parse(varargin{:});

meanMask = p.Results.meanMask(:)';

if isempty(meanMask)
    meanMask = true(1, size(p.Results.Y, 2));
end

% more input validation
assert(ndims(p.Results.Y) <= 2, 'Y argument must have 1 or 2 dimensions');
assert(numel(meanMask) == size(p.Results.Y,2), 'meanMask size does not match number of columns in Y argument');

addMean = 0;
if p.Results.preserveMean
    addMean = mean(mean(p.Results.Y(:,meanMask)));
end

slm = SurfStatLinMod(p.Results.Y, p.Results.Model);

Ypredicted = slm.X * slm.coef;

Yresidualized = (p.Results.Y - Ypredicted) + addMean;

% --- verification that values are exactly the same as via SurfStatLinMod2 ---
%slm2 = SurfStatLinMod2(p.Results.Y, p.Results.Model);
%Yresidualized2 = slm2.resid + addMean;
%residDiff = Yresidualized2 - Yresidualized;
%maxResidDiff = residDiff(abs(residDiff)==max(abs(residDiff)));
%fprintf('Maximum difference in residuals (preserving mean): %f\n', maxReisdDiff(1));
%assert(all(all(residDiff == 0)), 'Residuals do not match!!');

end

