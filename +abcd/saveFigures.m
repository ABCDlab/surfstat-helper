function saveFigures(varargin)
% Saves figure(s) to file(s), in one or multiple formats.
%
% saveFigures(directory, ['optionName', optionValue...])
%
% Options
%
%   'directory' Output directory (default current directory)
%   'prefix'    Filename prefix (default none)
%   'all'       If true, saves all open figures; if false, only saves
%               current figure (default false) 
%   'formats'   Cell array of formats to save. Available formats are 'png',
%               'fig' and 'pdf'. (default {'png'})
%   'pngRes'    Resolution for PNG images. Higher values produce larger
%               images. (default 150) 
%   'saveWorkspace' If true, saves MATLAB workspace to a .mat file (default
%                      false)
%   'hideCaption' If true, hides figure caption from SurfStatView figures
%                 before saving (default false) 
%   'figNumbers' If true, figure numbers are included in filenames (default
%                false)
%   'windowLayout' Set a MATLAB window layout before saving figures (useful
%                  to ensure a standard window size or undocking figures;
%                  default none)



p = inputParser;
p.addParamValue('directory', '.', @ischar);
p.addParamValue('prefix', '', @ischar);
p.addParamValue('all', false, @islogical);
p.addParamValue('formats', {'png'}, @iscellstr);
p.addParamValue('pngRes', 150, @isnumeric);
p.addParamValue('saveWorkspace', false, @islogical);
p.addParamValue('hideCaption', false, @islogical);
p.addParamValue('figNumbers', false, @islogical);
p.addParamValue('clusterFormingThreshold', 0.001, @isnumeric);
p.addParamValue('windowLayout', [], @ischar);
p.parse(varargin{:});



restoreLayout = false;
if (numel(p.Results.windowLayout) > 0)
    try
        com.mathworks.mde.desk.MLDesktop.getInstance.restoreLayout('surfstatFigUndocked');
        restoreLayout = true;
    catch
    end
end

exportdir = p.Results.directory;
filePrefix = p.Results.prefix;
allFigs =   p.Results.all;
asPng =     any(strcmpi('png', p.Results.formats));
asFig =     any(strcmpi('fig', p.Results.formats));
asPdf =     any(strcmpi('pdf', p.Results.formats));
saveWorkspaceMat = p.Results.saveWorkspace;
hideCaption =      p.Results.hideCaption;
includeFigNumber = p.Results.figNumbers;
pngRes = p.Results.pngRes;

if (asPng && ~exist('export_fig', 'file'))
    error('PNG selected as an output format, but export_fig script is not installed!');
end

if allFigs
    figureHandles = flipud(get(0,'Children'));
else
    figureHandles = gcf;
end

for ix_f = 1:numel(figureHandles)
    figureHandle = figureHandles(ix_f);
    if (isempty(get(figureHandle, 'Children'))), continue; end  % skip blank figures
    
    figName = get(figureHandle,'Name');
    
    filenameBits = {};    

    if (numel(filePrefix) > 0)
        filenameBits = [filenameBits, {filePrefix}];
    end
    
    if includeFigNumber
        filenameBits = [filenameBits, {sprintf('%02d', figureHandle)}];
    end
    
    if (numel(figName) > 0)
        filenameBits = [filenameBits, {figName}];
    end

    if (isempty(filenameBits))
        filenameBits = [filenameBits, {sprintf('figure-%02d', figureHandle)}];
    end
    
    if hideCaption
        h=get(findobj(figureHandle,'Tag','Colorbar'),'Title');
        if numel(h) == 1
            set(h,'Visible','off');
        end
    end
    
    filenameBase = '';
    for i=1:numel(filenameBits)
        if (i > 1)
            filenameBase = [filenameBase '--'];
        end
        filenameBase = [filenameBase filenameBits{i}];
    end
    
    filenameBaseFull = [exportdir '/' filenameBase];
    fprintf('Saving fig %d with base %s\n', figureHandle, filenameBaseFull);
    
    if asPdf; print(figureHandle, '-dpdf', [filenameBaseFull '.pdf']); end
    if asPng; export_fig('-png', sprintf('-r%d',pngRes), filenameBaseFull, figureHandle); end
    if asFig; saveas(figureHandle, [filenameBaseFull '.fig']); end

    if hideCaption
        h=get(findobj(figureHandle,'Tag','Colorbar'),'Title');
        if numel(h) == 1
            set(h,'Visible','on');
        end
    end
end

if (saveWorkspaceMat)
    save([exportdir '/' filePrefix '-workspace.mat']);
end

if (restoreLayout)
    try
        com.mathworks.mde.desk.MLDesktop.getInstance.restoreLayout('surfstatFigDocked');
    catch
    end
end

fprintf('Done\n');

end
