function requireBuildNumber(requiredBuildNumber)
    % Test that the build number 

    actualBuildNumber = abcd.buildNumber();
    assert (floor(actualBuildNumber) == floor(requiredBuildNumber), 'abcd: Build number %s is not compatible with %s', num2str(actualBuildNumber), num2str(requiredBuildNumber));
    
end