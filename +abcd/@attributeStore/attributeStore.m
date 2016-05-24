classdef attributeStore < handle
    % AttributeStore is a class to store name-value attributes.
    % The contents of the store can be rendered to a string in a flexible
    % format using the asString method.

    properties
        Attribs = struct();
    end

    properties (Hidden)
        StringOptions = [];
    end

    methods
        function obj = attributeStore(varargin)
            % Create an AttributeStore object
            if (nargin == 1)
                arg = varargin{1};
                if (isa(arg, class(obj)))
                    % pass through
                    obj = arg;
                elseif (isa(arg, 'struct'))
                    f = fieldnames(arg);
                    for i=1:numel(f)
                        name = f{1};
                        obj.set(name, arg.(name));
                    end
                end
            elseif (nargin > 1)
                obj.set(varargin{:});
            end
        end

        function value = value(AS, name)
            % Get value of attribute
            if (~isfield(AS.Attribs, name))
                value = [];
            else
                value = AS.Attribs.(name);
            end
        end

        function set(AS, varargin)
            % Set value of attribute
            for i=1:2:numel(varargin)
                name = varargin{i};
                value = varargin{i+1};
                assert(any(strcmp(class(value),{'char' 'single' 'double' 'logical'})));
                AS.Attribs.(name) = value;
            end
        end

        function append(AS, name, value, delimiter)
            if (nargin < 4), delimiter = ','; end
            origValue = AS.value(name);
            if (isempty(origValue)), delimiter = ''; origValue = ''; end
            if (~isa(origValue, 'char'))
                error('The append method requires the existing value to be a string or empty');
            end
            AS.set(name, [origValue delimiter value]);
        end

        function clear(AS, name)
            if (nargin < 2)
                AS.Attribs = struct();
            else
                if (isfield(AS.Attribs, name))
                    AS.Attribs = rmfield(AS.Attribs, name);
                end
            end
        end

        function setStringOptions(AS, varargin)
            AS.StringOptions = parseStringOptions(varargin{:});
        end

        function p = stringOptions(AS, varargin)
            if (~isempty(varargin))
                p = parseStringOptions(varargin{:});
            elseif (~isempty(AS.StringOptions))
                p = AS.StringOptions;
            else
                p = parseStringOptions();
            end

            if (isempty(p))
                error('This AttributeStore does not have any stringOptions set yet');
            end
        end

        function attributeString = asString(AS, varargin)
            % asString([optionName, optionValue...])
            %
            % itemDelim:    delimiter between attributes (default ', ')
            % before:       string preceding each attribute including the first one (default '')
            % after:        string following each attribute including the last one (default '')
            % attributeNames: attribute names are only included if this is true (default true)
            % attributeDelim: delimiter between attribute name and value (default '=')
            p = AS.stringOptions(varargin{:});

            attributeString = '';
            n = 0;
            f = fieldnames(AS.Attribs);
            for i = 1:numel(f)
                name = f{i};
                value = AS.Attribs.(name);
                valueString = '';
                if (isnumeric(value))
                    valueString = num2str(value);
                elseif (islogical(value))
                    valueString = 'false';
                    if (value)
                        valueString = 'true';
                    end
                elseif (ischar(value))
                    valueString = value;
                else
                    error('Unknown type for attribute %s', name);
                end

                itemDelim = '';
                nameString = '';
                attributeDelim = '';
                if (p.Results.attributeNames)
                    nameString = name;
                    attributeDelim = p.Results.attributeDelim;
                end
                if (i > 1), itemDelim = p.Results.itemDelim; end
                attributeString = [ ...
                        attributeString ...
                        itemDelim ...
                        p.Results.before ...
                        nameString ...
                        attributeDelim ...
                        valueString ...
                        p.Results.after ...
                    ];
            end
        end
    end
end

function options = parseStringOptions(varargin)
    p = inputParser();
    p.addParamValue('itemDelim', ', ', @ischar);
    p.addParamValue('before', '', @ischar);
    p.addParamValue('after', '', @ischar);
   % p.addParamValue('wrap', {}, @iscellstr);
    p.addParamValue('attributeNames', true, @islogical);
    p.addParamValue('attributeDelim', '=', @ischar);
    p.parse(varargin{:});

%     if (numel(p.Results.wrap) >= 2)
%         p.Results.before = p.Results.wrap{1};
%         p.Results.after = p.Results.wrap{2};
%     end
    options = p;
end