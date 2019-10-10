function [t, df] = simpleTTest2(x1,x2)
% A 2-sample t-test which computes only the t-value (and degrees of
% freedom), skipping the very time-consuming p-value computation. This
% function is good for permutation tests which need to compute t-values a
% large number of times as fast as possible. 
% This test assumes equal variances, and allows for unequal sample sizes. 
% 
% Written by Edden Gerber, March 2016. 

n1  = length(x1);
n2  = length(x2);

xmean1 = sum(x1)/n1; % works faster then mean
xmean2 = sum(x2)/n2; % works faster then mean

% compute std  (based on the std function, but without unnecessary stages
% which make that function general, but slow (especially using repmat)
xc = bsxfun(@minus,x1,xmean1);  % Remove mean
xstd1 = sqrt(sum(conj(xc).*xc,1)/(n1-1));
xc = bsxfun(@minus,x2,xmean2);  % Remove mean
xstd2 = sqrt(sum(conj(xc).*xc,1)/(n2-1));

sx1x2 = sqrt(((n1-1)*xstd1^2 + (n2-1)*xstd2^2)/(n1+n2-2));

t = (xmean1 - xmean2) / (sx1x2 * sqrt(1/n1 + 1/n2));
df = n1+n2-2;

end