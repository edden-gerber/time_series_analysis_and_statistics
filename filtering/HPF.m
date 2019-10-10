function [ out ] = HPF( in, sr, cutoff, varargin )
% HPF: Simple high pass filter
%
% Syntax:
% out = HPF(x,f,c), applies low-pass filter to input signal x, around the
% cutoff frequency c, where f is the sampling frequency. The default filter
% is a 4th-degree non-causal Butterworth filter. 
%
% out = HPF(x,f,c,d) defines d as the filter order (e.g. 2,3,8). 
%
% out = HPF(...,'causal') specifies a causal filter (see NOTE 1).
%
% out = HPF(...,'cheb',R) specifies a Chebyshev Type I filter rather than
% Butterworth. R is the peak-to-peak passband ripple amplitude, in dB. If
% ommited, the default value is 0.5 dB. 
%
% out - HPF(...,'butter') specifies a Butterworth filter. This is the
% default setting. 
% 
%
% NOTE 1: A Causal filter is one where the signal is filtered once in the
% forward direction, shifting the signal forward in relation to the
% original signal, but preserving its "causality", i.e., the value of each 
% data point is determined only by past data points. By contrast, in a 
% non-causal filter the signal is zero-shifter preserving peak latencies,
% but with the expense of each point being the product of both past and 
% future time points, meaning that the onset of a waveform may appear
% earlier than it was in the non-filtered signal. 
% 
% NOTE 2: A non-causal (default) filter is implemented using Matlab's 
% filtfilt function, which filters the signal twice - once in every
% direction. This means that the attenuation at each frequency will be
% double (in dB) relative to the causal filter with the same parameters.
% For example, a 4nd Butterworth filter attenuates the signal by 3dB at the
% cutoff frequency and by 12 dB per octave (i.e. per each doubling of the
% cutoff frequency). However unless a causal filter is specified, the
% signal resulting from this function will be attenuated by 6 dB at the
% cutoff frequency and by 24 dB per octave. 
%
% Written by Edden M. Gerber, lab of Leon Y. Deouell, August 2014.
% Please send bug reports and feature requests to edden.gerber@gmail.com

% define default parameters
order = 4; % default
causal = false; % default
type = 'butter'; % default
chebyshev_passband_ripple = 0.5; % default, in dB

% handle input
arg = 1;
nargin = length(varargin);
while arg <= nargin
    if ischar(varargin{arg})
        switch varargin{arg}
            case 'causal'
                causal = true;
                arg = arg + 1;
            case 'cheb'
                type = 'cheb';
                if nargin > arg && isscalar(varargin{arg+1})
                    chebyshev_passband_ripple = varargin{arg+1};
                    arg = arg + 1;
                end
                arg = arg + 1;
            case 'butter'
                type = 'butter';
                arg = arg + 1;
            otherwise
                error(['HPF: Unrecognized input argument ' varargin{arg}]);
        end
    elseif isnumeric(varargin{arg})
        if isscalar(varargin{arg}) && varargin{arg} > 0 && round(varargin{arg}) == varargin{arg} 
            order = varargin{arg};
            arg = arg+1;
        else
            error('HPF: Order argument expected to be positive natural number');
        end
    else
    end
    
end

% design filter
c1 = cutoff/(sr/2);
switch type 
    case 'butter'
        [b,a] = butter(order,c1,'high');
    case 'cheb'
        [b,a] = cheby1(order,chebyshev_passband_ripple,c1,'high');
end

% apply filter
if causal
    out = filter(b,a,in);
else
    out = filtfilt(b,a,in);
end


end

