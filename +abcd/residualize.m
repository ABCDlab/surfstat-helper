function [residMeasure] = residualize(varToResidualize, varAgainst)
% Residualizes the variable varToResidualize agains the variable
% varAgainst. These two variables must be lists of the same length.
% For example, to find the amount of variation in voice pitch not accounted
% for by sex, varToResidualize would be a measure of voice pitch, and 
% varAgainst would be sex.

coeffs = polyfit(varAgainst, varToResidualize,1);
yfit = polyval(coeffs,varAgainst);
residMeasure = varToResidualize - yfit;