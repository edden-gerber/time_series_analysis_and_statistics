function [ handle ] = varplot( varargin )
%VARPLOT: Plot data with variance indicators
% 
%Usage: 
%VARPLOT(D), where D is a matrix, plots the mean and variance of the
%matrix (the mean is plotted as a line and the variance as a shading around
%it). The data is assumed to be arranged in columns, such that each column 
%is a "trial". The default variance indicator is 95% confidence intervals. 
%
%VARPLOT(x,D), where x is a vector of the same length as D, defines the 
%x-axis of the plot, as in the plot function. 
%
%VARPLOT(v,low,high), where v, low and high are vectors of equal length,
%plots v with the shading borders defined by the low and high vectors. 
%
%VARPLOT(...,method), where method is either 'ci','std' or 'stderr',
%defines the variance indicator as confidence intervals, one standard
%deviation, or one standard error from the mean. 'ci' must be followed by 
%the confidence interval alpha, for instance VARPLOT(D,'ci',0.9). 
%
%VARPLOT(...,'transparency',t), where t is between 0 and 1, defines the 
%transparency level of the shading. Default is 0.5.
%
%VARPLOT(...,'palefactor',p), where p is between 0 and 1, defines how
%much paler (whiter) the shading will be compared to the line (in addition
%to the transparency effect). Setting the pale factor to 0 will use the 
%same color, while setting it to 1 will always change the color to white.
%Default is 0.5.
%
%VARPLOT(...,<plot arguments>) will pass additional arguments to Matlab's 
%standard plot function. Note that these arguments must always come after 
%the varplot-specific arguments. For instance, VARPLOT(D,'transparency',
%0.2,'k','linewidth',2) will set the line color and line width in the same 
%way as it would when using the plot function. 
% 
%h = VARPLOT(...) will return a handle to the plot object, in the same way
%as for the plot function. 
%
%Written by Edden M. Gerber, lab of Leon Y. Deouell, April 2014. 
%Please send bug reports and requsts to edden.gerber@gmail.com

% Handle input
var_method = 'ci';
ci_alpha = 0.95;
transparency = 0.5;
pale_factor = 0.5;

if nargin < 1
    error('No input arguments');
end

% count number of initial numeric arguments
num_numeric = 0;
for ind = 1:nargin
    if isnumeric(varargin{ind})
        num_numeric = num_numeric + 1;
    else
        break;
    end
end

switch num_numeric
    case 0
        error('First input argument must be vector or matrix.');
    case 1
        data = varargin{1};
    case 2
        x_vec = varargin{1};
        data = varargin{2};
    case 3
        data = varargin{1};
        lo_lim = varargin{2};
        hi_lim = varargin{3};
    case 4 
        x_vec = varargin{1};
        data = varargin{2};
        lo_lim = varargin{3};
        hi_lim = varargin{4};
    otherwise
        error('Not expecting more than five initial numeric input arguments');
end

% if data is a vector, make sure it's a column vector
if size(data,1)==1
    data = data';
end

% make an x vector variable if it was not defined.
if ~exist('x_vec','var')
    x_vec = 1:size(data,1);
end
if size(x_vec,1)==1;
    x_vec = x_vec';
end

% define the y vector
if isvector(data)
    matrix_input = false;
    y_vec = data;
    if ~exist('lo_lim','var') || ~exist('hi_lim','var')
        error('Non-matrix input must be followed by lower-limit vector and upper-limit vector');
    end
    if length(lo_lim) ~= length(data) || length(hi_lim) ~= length(data)
        error('Lower-limit vector, upper-limit vector and data vector must be of equal length');
    end
else
    matrix_input = true;
    y_vec = mean(data,2);
end

% handle additional optional input arguments
plot_arguments = {};
ind = num_numeric + 1;
while ind <= nargin
    switch varargin{ind}
        case 'ci'
            if ~isnumeric(varargin{ind+1})
                error('Optional argument ''ci'' must be followed by the confidence interval alpha, for example 0.95');
            end
            var_method = 'ci';
            ci_alpha = varargin{ind+1};
            ind = ind + 2;
        case 'std'
            var_method = 'std';
            ind = ind + 1;
        case 'stderr'
            var_method = 'stderr';
            ind = ind + 1;
        case 'palefactor'
            if ~isnumeric(varargin{ind+1}) || varargin{ind+1} < 0 || varargin{ind+1} > 1
                error('Optional argument ''palefactor'' must be followed by a numeric between 0 and 1');
            end
            pale_factor = varargin{ind + 1};
            ind = ind + 2;
        case 'transparency'
            if ~isnumeric(varargin{ind+1}) || varargin{ind+1} < 0 || varargin{ind+1} > 1
                error('Optional argument ''transparency'' must be followed by a numeric between 0 and 1');
            end
            transparency = varargin{ind + 1};
            ind = ind + 2;
        otherwise
            plot_arguments = varargin(ind:end);
            break;
    end
end

% Determine shade limits
if matrix_input
    switch var_method
        case 'ci'
            [~,~,ci] = ttest(data',0,'alpha',1-ci_alpha);
            lo_lim = ci(1,:)';
            hi_lim = ci(2,:)';
        case 'std'
            stdev = std(data,0,2);
            lo_lim = y_vec - stdev;
            hi_lim = y_vec + stdev;
        case 'stderr'
            stderr = std(data,0,2) / sqrt(size(data,2));
            lo_lim = y_vec - stderr;
            hi_lim = y_vec + stderr;
    end
end

% Plot mean
plot_held = ishold;
h_plot = plot(x_vec,y_vec,plot_arguments{:});

% add shading
clr = get(h_plot,'color');
clr = clr + pale_factor*(1-clr);
hold all
h_shade = fill([x_vec ; x_vec(end:-1:1)],[lo_lim ; hi_lim(end:-1:1)],clr,'FaceAlpha',transparency,'EdgeAlpha',0);
% if the plot was not help previously, keep it unheld
if ~plot_held 
    hold off
end

% output plot handle
if nargout > 0
handle = h_plot;

end

