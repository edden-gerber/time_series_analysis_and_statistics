function [ out ] = PhaseShuffle( in )
% Returns a vector of the same size and amplitude spectrum but with shuffled
% phase information. 

if mod(length(in),2)==1
    h = in(end);
    in = in(1:(end-1));
else 
    h = [];
end

F = fft(in);
N = length(in);
r = abs(F);
t = zeros(size(F));
t(1) = 0;
t(2:floor(N/2)) = rand(floor(N/2)-1,1)*2*pi-pi;
t((floor(N/2)+2):end) = -t(floor(N/2):-1:2);

out = ifft( r.* exp(1i*t) );
out = [out ; h];
end
