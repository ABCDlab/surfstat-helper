function plotData = plot3dInteractionMesh(dependentValues, designMatrix, modelCoefficients, columnX, columnY, columnXY, varargin)
% figureHandle = plot3dInteractionMesh(dependentValues, designMatrix, modelCoefficients, columnX, columnY, columnXY, [options])
%
%   Plots a 2-way continuous interaction vs the dependent variable. The coefficients
%   of the interaction model should already be estimated (e.g. by SurfStatLinMod)
%
%   Example of plotting an interaction from SurfStat at vertex 1243 where the model was
%    1 + varA*varB + varA + varB + varC
%
%   plot3dInteractionMesh(dependentValues, slm.X, slm.coef(:,1243), 3, 4, 2)
%
%   Required Arguments:
%       dependentValues     Column vector of n dependent values from which
%                           the model was estimated
%       designMatrix        Matrix of n-by-k values giving the design
%                           matrix (e.g. slm.X) from which the model was estimated
%       modelCoefficients   Vector of k parameter coefficients estimated from the
%                           model (e.g. slm.coef(:,vertexId))
%       columnX             The index of the column in designMatrix that
%                           corresponds to the x-axis values to be plotted
%       columnY             The index of the column in designMatrix that
%                           corresponds to the y-axis values to be plotted
%       columnXY            The index of the column in designMatrix that
%                           corresponds to the interaction of the columnX
%                           and columnY values
%
%   Options:
%       residualize         If true, the dependent values will be
%                           residualized by any non-plotted dimensions
%                           (default true)
%       dropLineColor       Color of the lines that connect data points to
%                           the base of the plot (default [0.5 0.5 0.5],
%                           i.e. gray)
%       markerSize          Size of data points (default 70)
%       meshDivisions       Number of divisions in the mesh (default 10)
%       yLinesAt            Vector of y values at which to plot individual
%                           regression lines (default empty)
%       xMean               If the values of the x parameter in the model
%                           were standardized by mean correction or z-score
%                           conversion, you can specify the mean here to
%                           calculate the original values before plotting
%                           (default 0, i.e. no change)
%       xSD                 If the values of the x parameter in the model
%                           were standardized by z-score conversion, you can
%                           specify the standard deviation here to
%                           calculate the original values before plotting
%                           (default 1, i.e. no change)
%       yMean               Same as xMean but for the y parameter
%       ySD                 Same as xSD but for the y parameter

% Created by Nick Foster 2015-07


assert(isvector(dependentValues), 'dependentValues is not a vector!');
assert(isvector(modelCoefficients), 'modelCoefficients is not a vector!');

dependentValues = dependentValues(:);       % ensure is column vector
modelCoefficients = modelCoefficients(:);   % ensure is column vector

assert(size(modelCoefficients,1) == size(designMatrix,2), 'Number of modelCoefficients != number of columns in designMatrix!');
assert(size(dependentValues,1) == size(designMatrix,1), 'Number of dependentValues != number of rows in designMatrix!');


isPositiveScalarInteger = @(x) floor(x)==x && isscalar(x) && x>0;
isPositiveScalar = @(x) isnumeric(x) && isscalar(x) && x>0;
isLogicalScalar = @(x) islogical(x) && isscalar(x);
isNumericScalar = @(x) isnumeric(x) && isscalar(x);
isNumericVector = @(x) isnumeric(x) && isvector(x);

p = inputParser;
p.addParamValue('meshDivisions', 10, isPositiveScalarInteger);
p.addParamValue('dropLineColor', 0.5*[1 1 1]);
p.addParamValue('yLineColor', 0.8*[1 1 1]);
p.addParamValue('markerSize', 100, isPositiveScalar);
p.addParamValue('residualize', true, isLogicalScalar);
p.addParamValue('xMean', 0, isNumericScalar);
p.addParamValue('xSD', 1, isNumericScalar);
p.addParamValue('yMean', 0, isNumericScalar);
p.addParamValue('ySD', 1, isNumericScalar);
p.addParamValue('meshAlpha', 1, isNumericScalar);
p.addParamValue('surfaceAlpha', 0.1, isNumericScalar);
p.addParamValue('yLinesAt', [], isNumericVector);
p.parse(varargin{:});


sourceVals = [];
sourceVals.x = double(designMatrix(:,columnX));
sourceVals.y = double(designMatrix(:,columnY));

plotDependentValues = dependentValues;

if p.Results.residualize
    constantColumn = find(all(designMatrix==1,1));
    assert(numel(constantColumn)==1, 'Should be 1 constant term in design matrix?!?!');
    covariateColumns = true(1,numel(modelCoefficients));
    covariateColumns([constantColumn columnX columnY columnXY]) = false;

    residDesignMatrix = designMatrix;
    residDesignMatrix(:,~covariateColumns) = 0; % only want to calculate based on covariate columns.
    % mean-adjust the values in each column, otherwise when we subtract
    % below we're changing the mean value of dependentValue:
    residDesignMatrix = residDesignMatrix - repmat(mean(residDesignMatrix,1), numel(dependentValues), 1);

    residDelta = residDesignMatrix * modelCoefficients(:);
    plotDependentValues = dependentValues - residDelta;
end

plotXYvals = [];
plotXYvals.x = p.Results.xMean + sourceVals.x * p.Results.xSD;
plotXYvals.y = p.Results.yMean + sourceVals.y * p.Results.ySD;

plotData = [];
plotData.handle.figure = figure;
hold on

plotData.handle.stems = stem3(plotXYvals.x, plotXYvals.y, plotDependentValues, 'color',p.Results.dropLineColor, 'MarkerEdgeColor','none', 'MarkerFaceColor','none');
plotData.handle.scatter = scatter3(plotXYvals.x, plotXYvals.y, plotDependentValues, p.Results.markerSize, dependentValues, 'filled');
hidden off
grid on;

meshSourceVals = [];
meshSourceVals.x = min(sourceVals.x) : range(sourceVals.x)/(p.Results.meshDivisions - 1) : max(sourceVals.x);
meshSourceVals.y = min(sourceVals.y) : range(sourceVals.y)/(p.Results.meshDivisions - 1) : max(sourceVals.y);
meshSourceVals.z = nan(p.Results.meshDivisions, p.Results.meshDivisions);

meshPlotVals = [];

for iX = 1:p.Results.meshDivisions   % maybe there's a way of calculating the predicted values across full x-y matrix at once?
    xVal = meshSourceVals.x(iX);

    meshDesignMatrix = repmat(mean(designMatrix,1), p.Results.meshDivisions, 1);
    meshDesignMatrix(:,columnX) = repmat(xVal, p.Results.meshDivisions, 1);
    meshDesignMatrix(:,columnY) = meshSourceVals.y';
    meshDesignMatrix(:,columnXY) = meshDesignMatrix(:,columnX) .* meshDesignMatrix(:,columnY);

    meshPlotVals.z(iX,:) = meshDesignMatrix * modelCoefficients(:);
end

meshPlotVals.x = p.Results.xMean + meshSourceVals.x * p.Results.xSD;
meshPlotVals.y = p.Results.yMean + meshSourceVals.y * p.Results.ySD;
plotData.values.surface = {meshPlotVals.x, meshPlotVals.y, meshPlotVals.z'};
plotData.handle.surface = surf(meshPlotVals.x, meshPlotVals.y, meshPlotVals.z', 'FaceColor','interp', 'FaceAlpha',p.Results.surfaceAlpha, 'EdgeColor','interp', 'EdgeAlpha',p.Results.meshAlpha);

plotData.handle.yLines = zeros(1,numel(p.Results.yLinesAt));
for iLine = 1:numel(p.Results.yLinesAt)
    lineY = p.Results.yLinesAt(iLine);
    plotXYZ = [];
    plotXYZ.x = meshSourceVals.x([1 p.Results.meshDivisions]);
    plotXYZ.y = [lineY lineY]';
    meshDesignMatrix = repmat(mean(designMatrix,1), 2,1);
    meshDesignMatrix(:,columnX) = plotXYZ.x;
    meshDesignMatrix(:,columnY) = plotXYZ.y;
    meshDesignMatrix(:,columnXY) = meshDesignMatrix(:,columnX) .* meshDesignMatrix(:,columnY);

    plotXYZ.z = meshDesignMatrix * modelCoefficients(:);
    
    plotXYZ.x = p.Results.xMean + plotXYZ.x * p.Results.xSD;
    plotXYZ.y = p.Results.yMean + plotXYZ.y * p.Results.ySD;
    
    
    plotData.handle.yLines(iLine) = line(plotXYZ.x, plotXYZ.y, plotXYZ.z, 'LineWidth',3, 'Color',p.Results.yLineColor); % 0.8*[1 1 1]
end



end

