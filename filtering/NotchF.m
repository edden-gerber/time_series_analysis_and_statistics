function [ out ] = NotchF( in, samprate, center, bw )
% Simple Notch Filter
% Inputs:
% in: input signal; filtering is performed on the columns. 
% samp_rate: sampling rate
% center: the frequency around which to filter
% bw: the bandwidth of the notch filter
% 
% Optional inputs:
% Adding the string 'causal' as a final argument will perform a causal filter (the signal will only
% be smeared forward in time, so that no "backward influence" is allowed). 
%
% Written by Edden M. Gerber 2014

wo = center/(samprate/2);
bw = bw / (samprate/2);
[b,a] = iirnotch(wo,bw);

if nargin > 4 && strcmp(varargin{1},'causal')
    out = filter(b,a,in);
else 
    % NOTE: The degree is divided by 2 here since the filtfilt function applies
    % the filter twice, effectively doubling the degree. 
    out = filtfilt(b,a,in);
end
