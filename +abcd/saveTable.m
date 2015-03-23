function saveTable( table, file, varargin )

% A flexible table writer to save tabular data to a file. Accepts data in
% several formats, and can handle mixed text and numeric data.
%
% Usage: saveTable( table, file [, optionName, optionvalue ...]);
%
%   table   The input table data. Can be:
%             - A structure array where each field contains one column.
%                Column names are taken from the field names.
%             - A cell array where the first row contains the field names,
%                and the following rows contain the data values.
%
%   file    The output file. Can be:
%             - A file name
%             - The fid of an already-open file
%
%   OPTIONS
%
%   'colDelim'  Default is tab ('\t')
%
%   'rowDelim'  Default is newline ('\n')
%
%   'strict'    Require all table rows to have equal number of columns. Default is false.
%

p = inputParser;
p.addParamValue('colDelim', sprintf('\t'), @ischar);
p.addParamValue('rowDelim', sprintf('\n'), @ischar);
p.addParamValue('strict', false, @islogical);
p.parse(varargin{:});

outputTable = {};
if (isa(table, 'struct'))
    outputTable = cellTableFromStructTable(table, p.Results);
end

if isnumeric(file)
    fid = file;
elseif ischar(file)
    fid = fopen(file, 'w');
else
    error('File must be a filename or fid');
end

if fid < 0
    error('Error opening outout file');
end

writeCellTableToOpenFile(outputTable, fid, p.Results);

if fid > 2          % if fid is not STDOUT/STDIN/STDERR
    fclose(fid);
end

end


%% Private functions . . .

function writeCellTableToOpenFile(table, fid, p)
   for r = 1:size(table,1)
       for c = 1:size(table,2)
           if c>1, fprintf(fid, p.colDelim); end
           if isnumeric(table{r,c})
               fprintf(fid, '%s', num2str(table{r,c}));
           elseif ischar(table{r,c})
               fprintf(fid, '%s', table{r,c});
           else
               error('Unrecognized value type in output table, row=%d, col=%s, type=%s', r, c, class(table{r,c}));
           end
       end
       fprintf(fid, p.rowDelim);
   end
end

function cellTable = cellTableFromStructTable(structTable, p)
    f = fieldnames(structTable);
    maxRows = 0;
    allColsEqualLength = true;
    for i = 1:length(f)
        prevMaxRows = maxRows;
        if (ischar(structTable.(f{i})))
            maxRows = max(maxRows, size(structTable.(f{i}),1));
        elseif (isvector(structTable.(f{i}))  ||  isempty(structTable.(f{i})))
            maxRows = max(maxRows, length(structTable.(f{i})));
        else
            error(['Received a structure array table, but a column is not a column vector! Field = ' f{i}]);
        end
        if (prevMaxRows ~= 0  &&  prevMaxRows ~= maxRows)
            allColsEqualLength = false;
        end
    end

    if ~allColsEqualLength
        if p.strict
            error('Not all columns have an equal number of values!');
        else
            warning('Not all columns have an equal number of values!');
        end
    end

    cellTable = cell(maxRows+1, length(f));
    cellTable(1,:) = f(:)';

    for i = 1:length(f)
        if (ischar(structTable.(f{i})))
            cellTable(2:1+size(structTable.(f{i}),1), i) = cellstr(structTable.(f{i}))';
        elseif (iscellstr(structTable.(f{i})))
            cellTable(2:1+size(structTable.(f{i}),1), i) = structTable.(f{i})(:)';
        elseif ((isvector(structTable.(f{i})) || isempty(structTable.(f{i}))) && isnumeric(structTable.(f{i})))
            cellTable(2:1+length(structTable.(f{i})), i) = num2cell(structTable.(f{i})(:))';
        else
            error(['Unrecognized column type, field = ' f{i}]);
        end
    end
end

