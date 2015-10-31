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
%       groupColumns        A vector of column indexes in designMatrix
%                           corresponding to group membership. If
%                           specified, a surface mesh will be plotted for
%                           each group, but to avoid clutter no datapoints
%                           will be plotted (default empty, i.e. don't plot
%                           by group)
%       residualize         If true, the dependent values will be
%                           residualized by any non-plotted dimensions
%                           (default true)
%       dropLines           Draw stems from datapoints to 'bottom', 'mesh'
%                           or 'none' (default 'bottom')
%       dropLineColor       Color of the lines that connect data points to
%                           the base of the plot (default [0.5 0.5 0.5],
%                           i.e. gray)
%       markerSize          Size of data points (default 70)
%       meshDivisions       Number of divisions in the mesh (default 10)
%       meshAlpha           Opacity of the lines in the mesh (0-1; default
%                           1, i.e. fully opaque)
%       surfaceAlpha        Opacity of the surface of the mesh (0-1;
%                           default 0.1)
%       yLinesAt            Vector of y values at which to plot individual
%                           regression lines (default empty)
%       yLineColor          Color for yLinesAt lines as [r g b] (default
%                           [0.8 0.8 0.8], i.e. gray)
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
%       limits              Struct that can contain fields 'x', 'y', 'z',
%                           and/or 'color', each having value of [min max]
%                           for the axis. E.g. struct('x',[0 10],'z',[3 8]). 
%                           Any unspecified axes will be auto-scaled. 
%
% Created by Nick Foster 2015-07


assert(isvector(dependentValues), 'dependentValues is not a vector!');
assert(isvector(modelCoefficients), 'modelCoefficients is not a vector!');

dependentValues = dependentValues(:);       % ensure is column vector
modelCoefficients = modelCoefficients(:);   % ensure is column vector
designMatrix = double(designMatrix);

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
p.addParamValue('groupColumns', [], isNumericVector);
p.addParamValue('limits', [], @isstruct);
p.addParamValue('dropLines', 'bottom', @ischar);
p.parse(varargin{:});


sourceVals = [];
sourceVals.x = designMatrix(:,columnX);
sourceVals.y = designMatrix(:,columnY);
sourceVals.groups = [];

groupInteractionColumns = struct('x',[], 'y',[], 'xy',[]);
nCoef = size(modelCoefficients,1);
if ~isempty(p.Results.groupColumns)
    xValues = designMatrix(:,columnX);
    yValues = designMatrix(:,columnY);
    sourceVals.groups = designMatrix(:,p.Results.groupColumns);
    assert(all(nonzeros(sourceVals.groups)==1), 'Group columns must be coded with 0 and 1 only!'); % if other values used, need to remember values to use later, and that's too complicated
    for iGroup = 1:numel(p.Results.groupColumns)
        % find group*x column
        iCol = find(all(designMatrix == repmat(sourceVals.groups(:,iGroup) .* xValues, 1, nCoef)), 1);
        if ~isempty(iCol)
            groupInteractionColumns.x(iGroup) = iCol;
        else 
            groupInteractionColumns.x(iGroup) = 0;
            warning('No group*x column found corresponding to group column %d in design matrix!', p.Results.groupColumns(iGroup));
        end
        % find group*y column
        iCol = find(all(designMatrix == repmat(sourceVals.groups(:,iGroup) .* yValues, 1, nCoef)), 1);
        if ~isempty(iCol)
            groupInteractionColumns.y(iGroup) = iCol;
        else 
            groupInteractionColumns.y(iGroup) = 0;
            warning('No group*y column found corresponding to group column %d in design matrix!', p.Results.groupColumns(iGroup));
        end
        % find group*x*y column
        iCol = find(all(designMatrix == repmat(sourceVals.groups(:,iGroup) .* xValues .* yValues, 1, nCoef)), 1);
        if ~isempty(iCol)
            groupInteractionColumns.xy(iGroup) = iCol;
        else 
            groupInteractionColumns.xy(iGroup) = 0;
            warning('No group*x*y column found corresponding to group column %d in design matrix!', p.Results.groupColumns(iGroup));
        end
    end
end


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

plotData = [];
plotData.handle.figure = figure;
hold on

% Plot Scatter
if isempty(p.Results.groupColumns)
    plotXYvals = [];
    plotXYvals.x = p.Results.xMean + sourceVals.x * p.Results.xSD;  % un-standardize if necessary
    plotXYvals.y = p.Results.yMean + sourceVals.y * p.Results.ySD;

    plotData.handle.scatter = scatter3(plotXYvals.x, plotXYvals.y, plotDependentValues, p.Results.markerSize, dependentValues, 'filled');
    if ~isempty(p.Results.limits) 
        if isfield(p.Results.limits, 'x')
            xlim(p.Results.limits.x);
        end
        if isfield(p.Results.limits, 'y')
            ylim(p.Results.limits.y);
        end
        if isfield(p.Results.limits, 'z')
            zlim(p.Results.limits.z);
        end        
        if isfield(p.Results.limits, 'color')
            caxis(p.Results.limits.color);
        end
    end
end

% Plot Surface(s)
meshSourceVals = [];
meshSourceVals.x = min(sourceVals.x) : range(sourceVals.x)/(p.Results.meshDivisions - 1) : max(sourceVals.x);
meshSourceVals.y = min(sourceVals.y) : range(sourceVals.y)/(p.Results.meshDivisions - 1) : max(sourceVals.y);

groupColumns = 0;   % magic value 0 will indicate no extra group terms to manipulate
if ~isempty(p.Results.groupColumns)
    groupColumns = p.Results.groupColumns;
end
    
for iGroup = 1:numel(groupColumns)
    meshSourceVals.z = nan(p.Results.meshDivisions, p.Results.meshDivisions);
    meshPlotVals = [];

    for iX = 1:p.Results.meshDivisions   % maybe there's a way of calculating the predicted values across full x-y matrix at once?
        xVal = meshSourceVals.x(iX);

        meshDesignMatrix = repmat(mean(designMatrix,1), p.Results.meshDivisions, 1);
        meshDesignMatrix(:,columnX) = repmat(xVal, p.Results.meshDivisions, 1);
        meshDesignMatrix(:,columnY) = meshSourceVals.y';
        meshDesignMatrix(:,columnXY) = meshDesignMatrix(:,columnX) .* meshDesignMatrix(:,columnY);
        
        if groupColumns(iGroup)>0
            % clear all group interaction columns
            meshDesignMatrix(:,nonzeros([groupColumns groupInteractionColumns.x groupInteractionColumns.y groupInteractionColumns.xy])) = 0;
            % now fill in values for selected group
            meshDesignMatrix(:,groupColumns(iGroup)) = 1;
            if groupInteractionColumns.x(iGroup)>0
                meshDesignMatrix(:,groupInteractionColumns.x(iGroup)) = meshDesignMatrix(:,columnX);
            end
            if groupInteractionColumns.y(iGroup)>0
                meshDesignMatrix(:,groupInteractionColumns.y(iGroup)) = meshDesignMatrix(:,columnY);
            end
            if groupInteractionColumns.xy(iGroup)>0
                meshDesignMatrix(:,groupInteractionColumns.xy(iGroup)) = meshDesignMatrix(:,columnXY);
            end
        end

        meshPlotVals.z(iX,:) = meshDesignMatrix * modelCoefficients(:);
    end

    meshPlotVals.x = p.Results.xMean + meshSourceVals.x * p.Results.xSD; % un-standardize if necessary
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

        if groupColumns(iGroup)>0
            % clear all group interaction columns
            meshDesignMatrix(:,nonzeros([groupColumns groupInteractionColumns.x groupInteractionColumns.y groupInteractionColumns.xy])) = 0;
            % now fill in values for selected group
            meshDesignMatrix(:,groupColumns(iGroup)) = 1;
            if groupInteractionColumns.x(iGroup)>0
                meshDesignMatrix(:,groupInteractionColumns.x(iGroup)) = meshDesignMatrix(:,columnX);
            end
            if groupInteractionColumns.y(iGroup)>0
                meshDesignMatrix(:,groupInteractionColumns.y(iGroup)) = meshDesignMatrix(:,columnY);
            end
            if groupInteractionColumns.xy(iGroup)>0
                meshDesignMatrix(:,groupInteractionColumns.xy(iGroup)) = meshDesignMatrix(:,columnXY);
            end
        end

        plotXYZ.z = meshDesignMatrix * modelCoefficients(:);

        plotXYZ.x = p.Results.xMean + plotXYZ.x * p.Results.xSD;
        plotXYZ.y = p.Results.yMean + plotXYZ.y * p.Results.ySD;

        lineWidth = 3;
        if groupColumns(iGroup)>0
            lineWidth = 2;
        end

        plotData.handle.yLines(iLine) = line(plotXYZ.x, plotXYZ.y, plotXYZ.z, 'LineWidth',lineWidth, 'Color',p.Results.yLineColor); % 0.8*[1 1 1]
    end

end


if ~isempty(p.Results.limits) 
    if isfield(p.Results.limits, 'x')
        xlim(p.Results.limits.x);
    end
    if isfield(p.Results.limits, 'y')
        ylim(p.Results.limits.y);
    end
    if isfield(p.Results.limits, 'z')
        zlim(p.Results.limits.z);
    end        
    if isfield(p.Results.limits, 'color')
        caxis(p.Results.limits.color);
    end
end

% draw stems (need to do this after set z limits)
if strcmpi(p.Results.dropLines, 'bottom')
    currentZLim = zlim;
    zLineVals = vertcat(repmat(plotDependentValues(:)', 1, 1), repmat(currentZLim(1), 1, numel(plotXYvals.y)));
    plotData.handle.stems = line(repmat(plotXYvals.x(:)', 2, 1), ...
         repmat(plotXYvals.y(:)', 2, 1), ...
         zLineVals, ...
         'color',p.Results.dropLineColor, 'MarkerEdgeColor','none', 'MarkerFaceColor','none');
elseif strcmpi(p.Results.dropLines, 'mesh')
    predictedZVals = designMatrix * modelCoefficients(:);
    zLineVals = vertcat(repmat(plotDependentValues(:)', 1, 1), predictedZVals(:)');
    plotData.handle.stems = line(repmat(plotXYvals.x(:)', 2, 1), ...
         repmat(plotXYvals.y(:)', 2, 1), ...
         zLineVals, ...
         'color',p.Results.dropLineColor, 'MarkerEdgeColor','none', 'MarkerFaceColor','none');

elseif strcmpi(p.Results.dropLines, 'none')
    % do nothing
else
    warning('dropLines argument value not recognized: %s', p.Results.dropLines);
end

grid on
hidden off

end

