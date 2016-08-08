function [ h, cb ] = viewSurfP( structArg, varargin )
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

    if ~isstruct(structArg) && isvector(structArg) && isnumeric(structArg)
        structArg = struct('P', structArg(:)');
    end
    assert(isstruct(structArg), 'First argument must be a struct or a vector');

    if isfield(structArg,'C')
        if isfield(structArg,'P')
            warning('Using P field for values, and ignoring C field. To plot the values in C instead, either 1) remove the P field or 2) pass the C values in the P field');
        else
            structArg.P = structArg.C;
        end
        structArg = rmfield(structArg,'C');
    end

    assert(isfield(structArg, 'P'), 'First argument must at least contain the "P" field');

    % if no explicit mask, create all-true mask
    if ~isfield(structArg,'mask')
        structArg.mask = true(size(structArg.P));
    end

    if ~isfield(structArg, 'sign')
        structArg.sign = sign(structArg.P);
    end

    structArg.P = abs(structArg.P);
    structArg.C = structArg.P;
    structArg.P(structArg.sign<=0) = 1;
    structArg.C(structArg.sign>=0) = 1;

    if isfield(structArg,'datamask')
        structArg.P(~structArg.datamask) = 1;
        structArg.C(~structArg.datamask) = 1;
    end

    [h, cb] = SurfStatView(structArg, varargin{:});
    set(get(cb,'XLabel'), 'String', 'P (neg)                  P (pos)');
end

