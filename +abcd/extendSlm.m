function slm = extendSlm(slm, Ydata)
%  slm = extendSlm(slm, Ydata)
%
%  Extends a SurfStat linear model structure variable to include several
%  additional fields relevant to prediction, residuals and goodness of fit.
%
%  Required:
%    slm        Structure variable as returned from SurfStatLinMod
%    Ydata      The column of dependent variables upon which slm was calculated
%
%  Output:
%    The slm variable is returned with the following extra fields added:
%
%  slm.Y        The dependent Y values (copied from 2nd argument)
%  slm.pred     Predicted Y values based on slm.X and slm.coef
%  slm.resid    Residuals, i.e. Y - slm.pred
%  slm.r2       R^2 coefficient of determination describing model's goodness of fit
%  slm.r2adj    Adjusted R^2, better for comparing models
%  slm.aic      Akaike information criterion (AIC), using formula:
%                  aic = 2k + n [Ln( 2(pi) RSS/n ) + 1]
%                 where k=number of parameters including error; RSS=residual
%                 sum of squares; n=number of rows in Ydata
%
%               Note on AIC values:
%               Remember, AIC is used to compare between different models
%               on same dataset (same vertex), not between same model on
%               different datasets (across vertices). In practice, you
%               should look at difference between AIC values (b/w models),
%               not the absolute value of any particular AIC; Between AIC
%               values from different models (on same dataset), lower (less
%               positive; more negative) AIC values are preferred.


% include dependent values
slm.Y = Ydata;

% calculate predicted values
slm.pred = slm.X * slm.coef;

% calculate residuals
slm.resid = double(Ydata) - slm.pred;

% calculate R^2

% sanity check for constant term in model; warn about comparing R-squared
% between models with/without constant term
if ~any(all(slm.X==1,1))
    warning('slm.X doesn''t seem to contain a constant term! Don''t compare the r^2 values to a model that does contain a constant term.');
end

% (commented out code is sloooow):
% slm.r2 = nan(1, size(Ydata,2));
% for i = 1:size(Ydata,2)
%     slm.r2(1,i) = corr(Ydata(:,i), slm.pred(:,i))^2;
% end

% following is FASTER: http://stackoverflow.com/a/9264173
% max error vs slow method is ~ 1e-6 for r2 values, which is very
% acceptable
An=bsxfun(@minus,Ydata,mean(Ydata,1));
Bn=bsxfun(@minus,slm.pred,mean(slm.pred,1));
An=bsxfun(@times,An,1./sqrt(sum(An.^2,1)));
Bn=bsxfun(@times,Bn,1./sqrt(sum(Bn.^2,1)));
slm.r2 = sum(An.*Bn,1) .^ 2;
% adjusted r-squared
% http://people.duke.edu/~rnau/rsquared.htm
slm.r2adj = 1 - (1 - slm.r2) * (size(Ydata,1) - 1) / (size(Ydata,1) - size(slm.coef,1) - 1);

% *** n.b. PROBLEMS with using R^2
% http://www.statisticalengineering.com/r-squared.htm

% residual standard deviation may be better indicator of goodness of fit
% than R^2?

% general online textbook introducing analytical approaches, concepts
% http://www.statsoft.com/Textbook


% Both AIC and SC can show if the addition of an extra independent variable
% helps the model specification. If their values are less after the addition
% of the extra variable (compared to the initial model) then the variable
% should be included in the model.

% good overview
% http://theses.ulaval.ca/archimede/fichiers/21842/apa.html

% "For small sample sizes (i.e., n/K < ~40), the second-order Akaike
% Information Criterion (AICc) should be used instead"
%
% "One should ensure that the same data set is used for each model, i.e.,
% the same observations must be used for each analysis. Missing values for
% only certain variables in the data set can also lead to variations in the
% number of observations."
%
% "Furthermore, the same response variable (y) must be used for all models
% (i.e., it must be identical across models, consistently with or without
% transformation). Nonetheless, one may specify different link functions or
% distributions to compare different types of models (e.g., normal,
% Poisson, logistic; see McCullagh and Nelder 1989)."


% calculate AIC
% one-liner copied from:
% http://www.mathworks.com/matlabcentral/fileexchange/34394-fast---detailed-multivariate-ols-regression/content/reg/aic.m

slm.aic = nan(1, size(Ydata,2));
slm.aicc = nan(1, size(Ydata,2));
n = size(Ydata,1);
k = size(slm.coef,1) + 1; % For k, I think we're supposed to count the residuals as a parameter
aiccAdj = 2*k*(k + 1)/(n - k - 1);
for i = 1:size(Ydata,2)
    %slm.aic(1,i) = log(1./n * (slm.resid(:,i)'*slm.resid(:,i))) + (2.*(k+1))./n;
    residSumSq = (slm.resid(:,i)'*slm.resid(:,i));
    slm.aic(1,i) = 2*k + n*(log(2 * pi * residSumSq / n) + 1);
    slm.aicc = slm.aic + aiccAdj;
end

%n.b. following line assumes Residuals is a column vector; if it's a
%row vector (and long) you will have a bad time...
%aic = log(1./n * (Residuals'*Residuals)) + (2.*(k+1))./n;
