function n = buildNumber()
    % Current build number for abcd package
    %
    % Build numbers are decimals. The part before the decimal is the
    % 'major' build number, and the part after the decimal is the 'minor'
    % build number.  
    %
    % Updates that increase the 'major' build number will require calling
    % scripts to be changed for some functions. 
    % 
    % See the requireBuildNumber function.
    n = 0.1;

end