function [contrastResults] = testModel(varargin)
% Generates peak tables, statistics and figures for a given model specified
% by the following parameters (See Nick's CT script for how to set it up).
%
% [contrastResults] = testModel(Y, Model, contrasts, avsurf, ['optionName', optionValue...]);
%
% Required:
%   Y:      output from CIVET for vertex-wise cortical thickness or surface area
%   Model:  a model composed of pre-defined Terms you want to include
%   contrasts: defined Terms in Model for which you would like to generate
%   tables and t-value maps (and P and Q, if anything passes threshold)
%   avsurf: the average surface data for the group used for Y
%
% Optional:
%   'avsurfPlot': default same as avsurf
%   'mask': default true for all vertices
%   'avsurfPlot': average surface rendering
%   'captionNotes': figure caption notes, as string or attributeStore or struct
%   'dfAdjust': default 0
%   'colormap': default spectral
%   'colorbarLimits': default actual min/max of data
%   'clusterFormingThreshold': default 0.001
%   'regionLabels': a regionLabels variable, e.g. as generated by abcd.loadAal78()
%   'twoTailed': default true
%   'createFigures': default true

isTerm = @(x) isa(x, 'term');
isContrastSet = @(x) isstruct(x);  % TODO: could be more strict by requiring all of x's fields to match strcmp(class(xfield),'term');
isSurface = @(x) isstruct(x); % TODO: could be more strict by checking for field names tri and coord
isIntegerNumeric = @(x) isnumeric(x) && (floor(x) == x);
isScalarLogical = @(x) islogical(x) && isscalar(x);
isColormap = @(x) ismatrix(x) && size(x, 2)==3;
isCaptionNotes = @(x) isstruct(x) || isa(x,'abcd.attributeStore') || ischar(x);

p = inputParser;
p.addRequired('Y', @ismatrix);
p.addRequired('Model', isTerm);
p.addRequired('contrasts', isContrastSet);
p.addRequired('avsurf', isSurface);
p.addParamValue('avsurfPlot', [], isSurface);
p.addParamValue('mask', [], @islogical); % TODO: after parsing input, assert that dimensions of mask are correct for Y
p.addParamValue('captionNotes', '', isCaptionNotes);
p.addParamValue('twoTailed', true, isScalarLogical);
p.addParamValue('dfAdjust', 0, isIntegerNumeric);
p.addParamValue('regionLabels', [], @isstruct);
p.addParamValue('colormap', spectral, isColormap);
p.addParamValue('colorbarLimits', [], @isvector); % could be more strict
p.addParamValue('clusterFormingThreshold', 0.001, @isnumeric);
p.addParamValue('createFigures', true, isScalarLogical);
% TODO: add options for which plots to create, which tables to print (or move table printing to separate function?)
p.parse(varargin{:});

% for convenience, make some variables from the required input results
Y = p.Results.Y;
Model = p.Results.Model;
contrasts = p.Results.contrasts;
avsurf = p.Results.avsurf;
avsurfPlot = p.Results.avsurfPlot;
captionNotes = p.Results.captionNotes;
dfAdjust = p.Results.dfAdjust;
mask = p.Results.mask;
imageColormap = p.Results.colormap;
fixedColorbarLimits = p.Results.colorbarLimits;
clusterFormingThreshold = p.Results.clusterFormingThreshold;
regionLabels = p.Results.regionLabels;


% handle defaults
if (isempty(mask))
    mask = true(1,size(Y,2));
end
if (isempty(avsurfPlot))
    avsurfPlot = p.Results.avsurf;
end


plotEffectSize = false; % TODO

contrastResults = [];
figureHandles = [];

% MODEL
modelValues = double(Model);
if p.Results.createFigures
    if size(modelValues,2) > 1
        modelParameterNames = char(Model);
        firstParameterIndex = 1;
        if strcmp(modelParameterNames{1},'1'), firstParameterIndex = 2; end
        corrplot(modelValues(:, firstParameterIndex:end), 'varNames', modelParameterNames(:, firstParameterIndex:end), 'testR', 'on');
        figureHandles = [figureHandles gcf];
    else
        hist(modelValues)
        figureHandles = [figureHandles gcf];
    end
    set(gcf, 'Name','cor(mdl)', 'NumberTitle', 'off');
end

slm_main = SurfStatLinMod( Y, Model, avsurf );

modelString = abcd.util.joinCellStr(char(Model), ' + ');

notes='';
if ischar(captionNotes)
    notes = captionNotes;
elseif isa(captionNotes,'abcd.attributeStore')
    notes = captionNotes.asString();
elseif isstruct(captionNotes)
    for f=fields(captionNotes)'; notes=[notes captionNotes.(char(f)) ' ']; end
end

% plots will generally be captioned as such:
% line 1) contrast term / peak npk thresholds / N DF
% line 2) modelString
% line 3) plot notes

% CONTRASTS
f = fields(contrasts);
contrastResults = [];
for c = 1:numel(f);

    contrastname = f{c};
    contrast = contrasts.(contrastname);

    if size(contrast,2) > 1
        warning('Contrast "%s" has >1 column! This will probably cause an error in SurfStatT. Did you enter a categorical factor instead of a contrast between this factor''s specific levels?', contrastname);
    end

    labels = []; labels.name = contrastname; labels.short = lower(labels.name);

    slm = slm_main;
    if dfAdjust > 0
        % e.g. if we factored out a covariate from Y before running model,
        % should adjust DF accordingly
        slm.df = slm.df - dfAdjust;
    end

    % RUN CONTRAST
    slm = SurfStatT( slm, contrast );

    [ labels.name notes]

    [ resels, reselspervert, edg ] = SurfStatResels( slm, mask );
    [ pval, peak, clus, clusid ] = SurfStatP( slm, boolean(mask), clusterFormingThreshold);

    if p.Results.twoTailed
        fprintf('Adjusting P values to two-tailed for all peaks and clusters\n');
        if isfield(pval, 'P'),  pval.P = 2*pval.P; end
        if isfield(pval, 'C'),  pval.C = 2*pval.C; end
        if isfield(peak, 'P'),  peak.P = 2*peak.P; end
        if isfield(clus, 'P'),  clus.P = 2*clus.P; end
    end

    % PRINT PEAK SUMMARY
    if numel(peak) > 0
        peak.label_name = [];
        term( peak ) + term( SurfStatInd2Coord( peak.vertid, avsurf )', {'x','y','z'})
        if ~isempty(regionLabels)
            for i = 1:size(peak.vertid,1)
                regionId = regionLabels.idByVertex(peak.vertid(i));
                nameShort = regionLabels.regions(regionId).nameShort;
                nameLong = regionLabels.regions(regionId).nameLong;
                if i <= 10
                    fprintf('peak #%d at vertid %5d is in region: %s (%s)\n', i, peak.vertid(i), nameShort, nameLong);
                end
                peak.label_name{i} = nameShort;
                peak.label_name_full{i} = nameLong;
            end
            fprintf('\n');
        end
    else
        peak
        peak.label_name = [];
    end
    term( clus )

    if p.Results.twoTailed
        n_note_tail = '2-tailed';
        tailFactor = 2;
    else
        n_note_tail = '1-tailed';
        tailFactor = 1;
    end

    tthresh = stat_threshold( resels, length(slm.t), 1, slm.df, 0.05/tailFactor );
    tthreshUC001 = -1*tinv(0.001/tailFactor,slm.df);

    n_note = sprintf(' [N=%i,DF=%i,%s]', size(Model,1), slm.df, n_note_tail);

    % PLOT T MAP
    maxAbsoluteTValue = max([max(slm.t.*mask) abs(min(slm.t.*mask))]);
    captionText = sprintf('T: %s, pk=%.2f, npk=%.2f (0.05r=%.2f, 0.001u=%.2f) %s\n%s\n%s', labels.name, max(slm.t.*mask), min(slm.t.*mask), tthresh, tthreshUC001, n_note, modelString, notes);
    if p.Results.createFigures
        contrastResults.(contrastname).figT = figure; SurfStatView( slm.t.*mask, avsurfPlot );
        figureHandles = [figureHandles contrastResults.(contrastname).figT];
        colormap(imageColormap);
        dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',12); h=suptitle(captionText); set(h, 'interpreter','none'); set(gcf,'defaultaxesfontsize',dafs);
        set(gcf,'Name',['T.' labels.short]);
        set(gcf, 'NumberTitle', 'off');
        if numel(fixedColorbarLimits) > 0
            SurfStatColLim(fixedColorbarLimits);
        else
            SurfStatColLim([-1*maxAbsoluteTValue maxAbsoluteTValue]);
        end
    end

    % PLOT EFFECT SIZE
    if p.Results.createFigures && plotEffectSize
        contrastResults.(contrastname).figEf = figure; SurfStatView( slm.ef.*mask, avsurfinfl, ' ' );
        figureHandles = [figureHandles contrastResults.(contrastname).figEf];
        captionText = sprintf('Effect size (coef) for %s, pk=%.2f, npk=%.2f %s\n%s\n%s', labels.name, max(slm.ef.*mask), min(slm.ef.*mask), n_note, modelString, notes);
        dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); h=suptitle(captionText); set(h, 'interpreter','none'); set(gcf,'defaultaxesfontsize',dafs);
        set(gcf,'Name',['ef.' labels.short]);
        set(gcf, 'NumberTitle', 'off');
    end

    % PLOT P MAP
    contrastResults.(contrastname).figP = [];
    if p.Results.createFigures && isfield(peak, 'P')
        minPValue = min([pval.P(boolean(mask)) pval.C(boolean(mask))])
        if minPValue < 0.05
            captionText = sprintf('P: %s, pk=%.2f clThr=%s %s\n%s\n%s', labels.name, minPValue, num2str(clusterFormingThreshold), n_note, modelString, notes);
            contrastResults.(contrastname).figP = figure; SurfStatView( pval, avsurfPlot, ' ' );
            figureHandles = [figureHandles contrastResults.(contrastname).figP];
            dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); h=suptitle(captionText); set(h, 'interpreter','none'); set(gcf,'defaultaxesfontsize',dafs);
            set(gcf,'Name', ['P.' labels.short]);
            set(gcf, 'NumberTitle', 'off');
        end
    end

    % PLOT Q MAP
    qval = SurfStatQ( slm, boolean(mask) );
    minQValue = min(qval.Q(boolean(mask)))
    contrastResults.(contrastname).figQ = [];

    if p.Results.createFigures && minQValue < 0.05
        warningNote = '';
        if p.Results.twoTailed
            warningNote = '*This result 1-tailed!';
        end

        captionText = sprintf('Q: %s, pk=%.2f %s %s\n%s\n%s', labels.name, minQValue, n_note, warningNote, modelString, notes);
        contrastResults.(contrastname).figQ = figure; SurfStatView( qval, avsurfPlot, ' ');
        figureHandles = [figureHandles contrastResults.(contrastname).figQ];
        dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); h=suptitle(captionText); set(h, 'interpreter','none'); set(gcf,'defaultaxesfontsize',dafs);
        set(gcf,'Name', ['Q.' labels.short]);
        set(gcf, 'NumberTitle', 'off');
    end


    contrastResults.(contrastname).slm = slm;
    contrastResults.(contrastname).peak = peak;
    contrastResults.(contrastname).pval = pval;
    contrastResults.(contrastname).clus = clus;
    contrastResults.(contrastname).clusid = clusid;
    contrastResults.(contrastname).qval = qval;
    contrastResults.(contrastname).resels = resels;
    contrastResults.(contrastname).tthresh_rft = tthresh;
    contrastResults.(contrastname).tthresh_uc001 = tthreshUC001;
    export = [];
    export.n = [1:size(contrastResults.(contrastname).peak.vertid,1)]';
    export.labelShort = char(contrastResults.(contrastname).peak.label_name);
    export.labelLong = char(contrastResults.(contrastname).peak.label_name_full);
    export.vertid = contrastResults.(contrastname).peak.vertid;
    export.clusid = contrastResults.(contrastname).peak.clusid;
    xyz = SurfStatInd2Coord( contrastResults.(contrastname).peak.vertid, avsurf )';
    export.x = xyz(:,1);
    export.y = xyz(:,2);
    export.z = xyz(:,3);
    export.t = contrastResults.(contrastname).peak.t;
    export.P_RFTpk = contrastResults.(contrastname).peak.P;
    export.P_RFTcl = contrastResults.(contrastname).clus.P(contrastResults.(contrastname).peak.clusid);
    export.Q_RFTpk = contrastResults.(contrastname).qval.Q(1,contrastResults.(contrastname).peak.vertid)';
    export.P_UC = 1-tcdf(contrastResults.(contrastname).peak.t, contrastResults.(contrastname).slm.df);
    contrastResults.(contrastname).data.table = [export.n, ...
        export.vertid,export.clusid, ...
        export.x, export.y, export.z, ...
        export.t, ...
        export.P_RFTpk, ...
        export.P_RFTcl, ...
        export.Q_RFTpk, ...
        export.P_UC,];
    contrastResults.(contrastname).data.labelShort = export.labelShort;
    contrastResults.(contrastname).data.labelLong = export.labelLong;
    
end

%Add some of the input parameters to the contrastResults struct
%so they can be given along with the output
contrastResults.params.Model = p.Results.Model;
contrastResults.params.twoTailed = p.Results.twoTailed;
contrastResults.params.dfAdjust = p.Results.dfAdjust;
contrastResults.params.mask = p.Results.mask;
contrastResults.params.clusterFormingThreshold = p.Results.clusterFormingThreshold;
contrastResults.params.plotNotes = captionNotes;
contrastResults.params.figureHandles = figureHandles;

fprintf('Cluster forming threshold = %s\n', num2str(clusterFormingThreshold));

for c = 1:numel(f);
    contrastname = f{c};
    nResult = [];
    nResult.pkUc = 0;
    nResult.pkRft = 0;
    nResult.clRft = 0;
    nResult.pkFdr = 0;
    if isfield(contrastResults.(contrastname).peak,'vertid')
        nResult.pkUc = size(contrastResults.(contrastname).peak.vertid,1);
    end
    if isfield(contrastResults.(contrastname).peak,'P')
        nResult.pkRft = sum(contrastResults.(contrastname).peak.P<0.05);
    end
    if isfield(contrastResults.(contrastname).clus,'P')
        nResult.clRft = sum(contrastResults.(contrastname).clus.P<0.05);
    end
    if isfield(contrastResults.(contrastname).qval,'Q')
        nResult.pkFdr = sum(contrastResults.(contrastname).qval.Q<0.05);
    end
    fprintf('Contrast %-7s has %3i uc peaks, %3i RFT peaks, %3i RFT clus, %4i FDR peaks\n', contrastname, nResult.pkUc, nResult.pkRft, nResult.clRft, nResult.pkFdr);
end

end