function clusterFig = clusterOnlyMap(contrastResults, contrastname, avsurfPlot)
% When given a set of results from the testModel function, removes RFT peak
% plotting from the P-map and leaves clusters,generating a new figure.
%   'contrastResults' : results from testModel function
%   'contrastname' : contrast to be plotted with clusters only
%   'avsurfPlot': average surface rendering; default same as avsurf


modelString = '';
for s = char(contrastResults.params.Model)
    if (numel(modelString) > 0)
        modelString = [modelString ' + '];
    end
    modelString = [modelString s{1}];
end
mask = contrastResults.(contrastname).pval.mask;
minPValue = min([contrastResults.(contrastname).pval.P(boolean(mask)) contrastResults.(contrastname).pval.C(boolean(mask))]);
labels = []; labels.name = contrastname; labels.short = lower(labels.name);
if contrastResults.params.twoTailed
        n_note_tail = '2-tailed';
        tailFactor = 2;
    else
        n_note_tail = '1-tailed';
        tailFactor = 1;
    end
n_note = sprintf(' [N=%i,DF=%i,%s]', size(contrastResults.params.Model,1), contrastResults.(contrastname).slm.df, n_note_tail);
clusterFormingThreshold = num2str(contrastResults.params.clusterFormingThreshold);
plotNotes = contrastResults.params.plotNotes;
notes=''; for f=fields(plotNotes)'; notes=[notes plotNotes.(char(f)) ' ']; end
captionText = sprintf('P: %s, pk=%.2f clThr=%s %s\n%s\n%s', contrastname, char(minPValue), clusterFormingThreshold, n_note, modelString, notes);
clusterFig = figure; SurfStatView( contrastResults.(contrastname).pval.C, avsurfPlot, ' ' );
dafs=get(gcf,'defaultaxesfontsize'); set(gcf,'defaultaxesfontsize',9); suptitle(captionText); set(gcf,'defaultaxesfontsize',dafs);
set(gcf,'Name', ['P.' labels.short]);
set(gcf, 'NumberTitle', 'off');
cm =    [0    0.9921    1.0000
         0    0.9843    1.0000
         0    0.9764    1.0000
         0    0.9685    1.0000
         0    0.9606    1.0000
         0    0.9528    1.0000
         0    0.9449    1.0000
         0    0.9370    1.0000
         0    0.9291    1.0000
         0    0.9213    1.0000
         0    0.9134    1.0000
         0    0.9055    1.0000
         0    0.8976    1.0000
         0    0.8898    1.0000
         0    0.8819    1.0000
         0    0.8740    1.0000
         0    0.8661    1.0000
         0    0.8583    1.0000
         0    0.8504    1.0000
         0    0.8425    1.0000
         0    0.8346    1.0000
         0    0.8268    1.0000
         0    0.8189    1.0000
         0    0.8110    1.0000
         0    0.8031    1.0000
         0    0.7953    1.0000
         0    0.7874    1.0000
         0    0.7795    1.0000
         0    0.7717    1.0000
         0    0.7638    1.0000
         0    0.7559    1.0000
         0    0.7480    1.0000
         0    0.7402    1.0000
         0    0.7323    1.0000
         0    0.7244    1.0000
         0    0.7165    1.0000
         0    0.7087    1.0000
         0    0.7008    1.0000
         0    0.6929    1.0000
         0    0.6850    1.0000
         0    0.6772    1.0000
         0    0.6693    1.0000
         0    0.6614    1.0000
         0    0.6535    1.0000
         0    0.6457    1.0000
         0    0.6378    1.0000
         0    0.6299    1.0000
         0    0.6220    1.0000
         0    0.6142    1.0000
         0    0.6063    1.0000
         0    0.5984    1.0000
         0    0.5906    1.0000
         0    0.5827    1.0000
         0    0.5748    1.0000
         0    0.5669    1.0000
         0    0.5591    1.0000
         0    0.5512    1.0000
         0    0.5433    1.0000
         0    0.5354    1.0000
         0    0.5276    1.0000
         0    0.5197    1.0000
         0    0.5118    1.0000
         0    0.5039    1.0000
         0    0.4961    1.0000
         0    0.4882    1.0000
         0    0.4803    1.0000
         0    0.4724    1.0000
         0    0.4646    1.0000
         0    0.4567    1.0000
         0    0.4488    1.0000
         0    0.4409    1.0000
         0    0.4331    1.0000
         0    0.4252    1.0000
         0    0.4173    1.0000
         0    0.4094    1.0000
         0    0.4016    1.0000
         0    0.3937    1.0000
         0    0.3858    1.0000
         0    0.3780    1.0000
         0    0.3701    1.0000
         0    0.3622    1.0000
         0    0.3543    1.0000
         0    0.3465    1.0000
         0    0.3386    1.0000
         0    0.3307    1.0000
         0    0.3228    1.0000
         0    0.3150    1.0000
         0    0.3071    1.0000
         0    0.2992    1.0000
         0    0.2913    1.0000
         0    0.2835    1.0000
         0    0.2756    1.0000
         0    0.2677    1.0000
         0    0.2598    1.0000
         0    0.2520    1.0000
         0    0.2441    1.0000
         0    0.2362    1.0000
         0    0.2283    1.0000
         0    0.2205    1.0000
         0    0.2126    1.0000
         0    0.2047    1.0000
         0    0.1969    1.0000
         0    0.1890    1.0000
         0    0.1811    1.0000
         0    0.1732    1.0000
         0    0.1654    1.0000
         0    0.1575    1.0000
         0    0.1496    1.0000
         0    0.1417    1.0000
         0    0.1339    1.0000
         0    0.1260    1.0000
         0    0.1181    1.0000
         0    0.1102    1.0000
         0    0.1024    1.0000
         0    0.0945    1.0000
         0    0.0866    1.0000
         0    0.0787    1.0000
         0    0.0709    1.0000
         0    0.0630    1.0000
         0    0.0551    1.0000
         0    0.0472    1.0000
         0    0.0394    1.0000
         0    0.0315    1.0000
         0    0.0236    1.0000
         0    0.0157    1.0000
         0    0.0079    1.0000
         0         0    1.0000
    0.7000    0.7000    0.7000];

colormap(cm)
SurfStatColLim([0 0.05])

end