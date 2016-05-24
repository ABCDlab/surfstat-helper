function [ h, cb ] = viewSurfP( struct, varargin )
% Wrapper for SurfStatView that plots P values and supports negative values
%
% Usage: [ a, cb ] = abcd.SurfStatViewP( struct, surf [,title [,background] ] );
%
% Arguments:
% struct        = 1 x v vector of corrected P-values for vertices (can
%                 contain negative P values), or a P-value structure:
%     P-value structure:
%     struct.P      = 1 x v vector of corrected P-values for vertices (can
%                     contain negative P values)
%     struct.sign   = 1 x v vector of values indicating positive/negative
%                     direction (optional). If specified, overrides sign of
%                     struct.P values! Values will be passed into sign()
%                     function
%     struct.mask   = 1 x v, 1=inside, 0=outside, v=#vertices.
%     struct.datamask = 1 x v, 1=inside, 0=outside, v=#vertices. (optional)
%                     Does not plot masked region, but simply omits any
%                     significant results outside mask
%     struct.thresh = P-value threshold for plot, 0.05 by default.
% surf, title, background: same as in SurfStatViewP
%
% Returns:
% a  = vector of handles to the axes, left to right, top to bottom.
% cb = handle to the colorbar.

    if ~isstruct(struct) && isvector(struct) && isnumeric(struct)
        struct = struct('P', struct);
    end
    assert(isstruct(struct), 'First argument must be a struct or a vector');

    if isfield(struct,'C')
        if isfield(struct,'P')
            warning('Using P field for values, and ignoring C field. To plot the values in C instead, either 1) remove the P field or 2) pass the C values in the P field');
        else
            struct.P = struct.C;
        end
        struct = rmfield(struct,'C');
    end

    assert(isfield(struct, 'P'), 'First argument must at least contain the "P" field');

    % if no explicit mask, create all-true mask
    if ~isfield(struct,'mask')
        struct.mask = true(size(struct.P));
    end

    if ~isfield(struct, 'sign')
        struct.sign = sign(struct.P);
    end

    struct.P = abs(struct.P);
    struct.C = struct.P;
    struct.P(struct.sign<=0) = 1;
    struct.C(struct.sign>=0) = 1;

    if isfield(struct,'datamask')
        struct.P(~struct.datamask) = 1;
        struct.C(~struct.datamask) = 1;
    end

    [h, cb] = SurfStatView(struct, varargin{:});
    set(get(cb,'XLabel'), 'String', 'P (neg)                  P (pos)');
end

