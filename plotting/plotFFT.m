function [ spectrum, x_axis ] = plotFFT(in, sampling_rate)
% Calculate the FFT of the input signal and plot on a frequency axis
%
% Input:
% in - input data. If it is a matrix, the computed spectrum will be the
% mean of the spectrum of the matrix columns. 
% sampling_rate - input sampling rate
% Output:
% spectrum - the FFT result
% x_axis - the absolute frequency values correspnding to the spectrum
% vector (depending on the sampling frequency and the length of the data
% vector). 
% 
% Note - the result will be plotted only when there is no output variable. 
%
% Written by Edden Gerber 2011

% if row vector change to column
if size(in,1)==1
    in = in';
end

L = floor(size(in,1));

NFFT = 2^nextpow2(L); % Next power of 2 from length of X

F = fft(in,NFFT)/L;
fx = sampling_rate/2*linspace(0,1,NFFT/2+1);

% Get single-sided amplitude spectrum.
F = 2*abs(F(1:NFFT/2+1,:));

if nargout == 0
    plot(fx,mean(F,2));
    title('Single-Sided Amplitude Spectrum')
    xlabel('Frequency (Hz)')
end

if nargout > 0
    spectrum = F;
end
if nargout > 1
    x_axis = fx;
end
end

