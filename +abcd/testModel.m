function [contrast_results] = testModel(varargin)
% Generates peak tables, statistics and figures for a given model specified
% by the following parameters (See Nick's CT script for how to set it up).
%
% [contrast_results] = testModel(Y, Model, contrasts, avsurf, ['optionName', optionValue...]);
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
%   'captionNotes': struct variable
%   'dfAdjust': default 0
%   'colormap': default spectral
%   'colorbarLimits': default actual min/max of data
%   'clusterFormingThreshold': default 0.001
%   'aal78': TODO

isTerm = @(x) isa(x, 'term');
isContrastSet = @(x) isstruct(x);  % TODO: could be more strict by requiring all of x's fields to match strcmp(class(xfield),'term');
isSurface = @(x) isstruct(x); % TODO: could be more strict by checking for field names tri and coord
isIntegerNumeric = @(x) isnumeric(x) && (floor(x) == x);
isColormap = @(x) ismatrix(x) && size(x, 2)==3;

p = inputParser;
p.addRequired('Y', @ismatrix);
p.addRequired('Model', isTerm);
p.addRequired('contrasts', isContrastSet);
p.addRequired('avsurf', isSurface);
p.addParamValue('avsurfPlot', struct(), isSurface);
p.addParamValue('mask', [], @islogical); % TODO: after parsing input, assert that dimensions of mask are correct for Y
p.addParamValue('captionNotes', struct(), @isstruct);
p.addParamValue('dfAdjust', 0, isIntegerNumeric);
% p.addParamValue('aal78', .... % TODO: best to provide all AAL data in a single struct variable
p.addParamValue('colormap', spectral, isColormap);
p.addParamValue('colorbarLimits', [], @isvector); % could be more strict
p.addParamValue('clusterFormingThreshold', 0.001, @isnumeric);
% TODO: add options for which plots to create, which tables to print (or move table printing to separate function?)
p.parse(varargin{:});

% for convenience, make some variables from the required input results
Y = p.Results.Y;
Model = p.Results.Model;
contrasts = p.Results.contrasts;
avsurf = p.Results.avsurf;
plot_notes = p.Results.captionNotes;
df_adjust = p.Results.dfAdjust;
mask = p.Results.mask;
clusterFormingThreshold = p.Results.clusterFormingThreshold;


% handle defaults
if (isempty(mask))
    mask = true(1,size(Y,2));
end


plotEffectSize = false;

contrast_results = [];

% MODEL
disp('Cross-correlation of parameters in model:');
term(corrcoef(double(Model)), char(Model))
figure('Name','cor(mdl)', 'NumberTitle', 'off');
image(abs(corrcoef(double(Model)))*length(colormap));
set(gca, 'XTick', [1:size(Model,2)], 'XTickLabel', char(Model), 'YTick', [1:size(Model,2)], 'YTickLabel', char(Model));
set(colorbar,'YTickLabel',{})
title('Correlations among model parameters')

slm_main = SurfStatLinMod( Y, Model, avsurf );

modelString = '';
for s = char(Model)
    if (numel(modelString) > 0)
        modelString = [modelString ' + '];
    end
    modelString = [modelString s{1}];
end

notes=''; for f=fields(plot_notes)'; notes=[notes plot_notes.(char(f)) ' ']; end

% plots will generally be captioned as such:
% line 1) contrast term / peak npk thresholds / N DF
% line 2) modelString
% line 3) plot notes

% CONTRASTS
f = fields(contrasts);
contrast_results = [];
for c = 1:numel(f);

    contrastname = f{c};
    contrast = contrasts.(contrastname);

    labels = []; labels.name = contrastname; labels.short = lower(labels.name);

    slm = slm_main;
    if df_adjust > 0
        % e.g. if we factored out a covariate from Y before running model,
        % should adjust DF accordingly
        slm.df = slm.df - df_adjust;
    end

    % RUN CONTRAST
    slm = SurfStatT( slm, contrast );

    [ labels.name notes]

    [ resels, reselspervert, edg ] = SurfStatResels( slm, mask );
    [ pval, peak, clus, clusid ] = SurfStatP( slm, boolean(mask), clusterFormingThreshold);

    % PRINT PEAK SUMMARY
    if numel(peak) > 0
        peak.label_name = [];
        term( peak ) + term( SurfStatInd2Coord( peak.vertid, avsurf )', {'x','y','z'})
        for i = 1:size(peak.vertid,1)
            label = aal_labels(peak.vertid(i));
            if label > 0 && label <= 78;
                label_name = aal_78_ids{2}{label};
                label_name_full = aal_78_ids{3}{label};
            else
                label_name = '(not defined)';
                label_name_full = '(not defined)';
            end
            if i <= 10
                fprintf('peak #%d at vertid %5d is in AAL region: %s (%s)\n', i, peak.vertid(i), label_name, label_name_full);
            end
            peak.label_name{i} = label_name;
            peak.label_name_full{i} = label_name_full;
        end
        fprintf('\n');
    else
        peak
        peak.label_name = [];
    end
    term( clus )

    tthresh = stat_threshold( resels, length(slm.t), 1, slm.df );
    tthreshUC001 = -1*tinv(0.001,slm.df);

    n_note = sprintf(' [N=%i,DF=%i]', size(Model,1), slm.df);

    % PLOT T MAP
    max_abs_tval = max([max(slm.t.*mask) abs(min(slm.t.*mask))]);
    caption_text = sprintf('T: %s, pk=%.2f, npk=%.2f (0.05r=%.2f, 0.001u=%.2f) %s\n%s\n%s', labels.name, max(slm.t.*mask), min(slm.t.*mask), tthresh, tthreshUC001, n_note, modelString, notes);
    contrast_results.(contrastname).figT = figure; SurfStatView( slm.t.*mask, avsurf_view );
    colormap(image_colormap);
    dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',12); suptitle(caption_text); set(gcf,'defaultaxesfontsize',dafs);
    set(gcf,'Name',['T.' labels.short]);
    set(gcf, 'NumberTitle', 'off');
    if numel(fixed_colorbar_limits) > 0
        SurfStatColLim(fixed_colorbar_limits);
    else
        SurfStatColLim([-1*max_abs_tval max_abs_tval]);
    end

    % PLOT EFFECT SIZE
    if (plotEffectSize)
        figure; SurfStatView( slm.ef.*mask, avsurfinfl, ' ' );
        caption_text = sprintf('Effect size (coef) for %s, pk=%.2f, npk=%.2f %s\n%s\n%s', labels.name, max(slm.ef.*mask), min(slm.ef.*mask), n_note, modelString, notes);
        dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); suptitle(caption_text); set(gcf,'defaultaxesfontsize',dafs);
        set(gcf,'Name',['ef.' labels.short]);
        set(gcf, 'NumberTitle', 'off');
    end

    % PLOT P MAP
    contrast_results.(contrastname).figP = [];
    if isfield(peak, 'P')
        min_pval = min([pval.P(boolean(mask)) pval.C(boolean(mask))])
        if min_pval < 0.05
            caption_text = sprintf('P: %s, pk=%.2f clThr=%s %s\n%s\n%s', labels.name, min_pval, num2str(clusterFormingThreshold), n_note, modelString, notes);
            contrast_results.(contrastname).figP = figure; SurfStatView( pval, avsurf_view, ' ' );
            dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); suptitle(caption_text); set(gcf,'defaultaxesfontsize',dafs);
            set(gcf,'Name', ['P.' labels.short]);
            set(gcf, 'NumberTitle', 'off');
        end
    end

    % PLOT Q MAP
    qval = SurfStatQ( slm, boolean(mask) );
    min_qval = min(qval.Q(boolean(mask)))
    contrast_results.(contrastname).figQ = [];
    if min_qval < 0.05
        caption_text = sprintf('Q: %s, pk=%.2f %s\n%s\n%s', labels.name, min_qval, n_note, modelString, notes);
        contrast_results.(contrastname).figQ = figure; SurfStatView( qval, avsurf_view, ' ');
        dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); suptitle(caption_text); set(gcf,'defaultaxesfontsize',dafs);
        set(gcf,'Name', ['Q.' labels.short]);
        set(gcf, 'NumberTitle', 'off');
    end

    contrast_results.(contrastname).slm = slm;
    contrast_results.(contrastname).peak = peak;
    contrast_results.(contrastname).pval = pval;
    contrast_results.(contrastname).clus = clus;
    contrast_results.(contrastname).clusid = clusid;
    contrast_results.(contrastname).qval = qval;
    contrast_results.(contrastname).resels = resels;
    contrast_results.(contrastname).tthresh_rft = tthresh;
    contrast_results.(contrastname).tthresh_uc001 = tthreshUC001;
end

fprintf('Cluster forming threshold = %s\n', num2str(clusterFormingThreshold));
for c = 1:numel(f);
    contrastname = f{c};
    nResult = [];
    nResult.pkUc = 0;
    nResult.pkRft = 0;
    nResult.clRft = 0;
    nResult.pkFdr = 0;
    if isfield(contrast_results.(contrastname).peak,'vertid')
        nResult.pkUc = size(contrast_results.(contrastname).peak.vertid,1);
    end
    if isfield(contrast_results.(contrastname).peak,'P')
        nResult.pkRft = sum(contrast_results.(contrastname).peak.P<0.05);
    end
    if isfield(contrast_results.(contrastname).clus,'P')
        nResult.clRft = sum(contrast_results.(contrastname).clus.P<0.05);
    end
    if isfield(contrast_results.(contrastname).qval,'Q')
        nResult.pkFdr = sum(contrast_results.(contrastname).qval.Q<0.05);
    end
    fprintf('Contrast %-7s has %3i uc peaks, %3i RFT peaks, %3i RFT clus, %4i FDR peaks\n', contrastname, nResult.pkUc, nResult.pkRft, nResult.clRft, nResult.pkFdr);
end

end