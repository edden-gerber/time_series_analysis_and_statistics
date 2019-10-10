function [ plv ] = PLV( phase_sig1, phase_sig2 )
% Compute the Phase Locking Value between two signals across trials, according to Lachaux, 
% Rodriguez, Martinerie, and Varela (1999). The PLV value ranges from 0, indicating random 
% phase differences, to 1 indicating a fixed phase difference. 
% phase_sig1 and phase_sig2 should be the phase values of the signals in radians, arranged as
% Samples x Trials. These can bed
% computed using the Wavelet or Hilbert transform, for example:
% phase_sig = angle(hilbert(BPS)); 
% Where BPS is the signal after band-pass filtering around the frequency range of interest. 
% 
% Written by Edden Gerber 2012

[~, Ntrials] = size(phase_sig1);

% compute PLV
e = exp(1i*(phase_sig1 - phase_sig2));
plv = abs(sum(e,2)) / Ntrials;
end

