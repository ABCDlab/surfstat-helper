function n = buildNumber()
    % Current build number for abcd package
    %
    % Build numbers are decimal values. The part before the decimal is the
    % 'major' build number, and the part after the decimal is the 'minor'
    % build number.
    %
    % Updates that increase the 'major' build number involve changes that
    % will require scripts using these functions to be checked and
    % possibly updated (e.g. changes to existing function arguments,
    % defaults, behavior or output).
    %
    % See the requireBuildNumber function.

    n = 2.2;

end