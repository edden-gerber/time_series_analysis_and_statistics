function x = randwalk(length,varargin)
% Produce random walk signal
%
% Usage:
% x = randwalk(L) produces a random walk signal of length L, where each step size is taken from a
% uniform distribution.
% x = randwalk(L,...,'normal') produces a random walk where the step sizes are taken from a normal
% distribution (larger steps are rare).
% x = randwalk(L,...,'bound',b) introduces a bias towards zero, which increases as the walk deviates
% from zero. b is the overall magnitude of the bias. 
% x = randwalk(L,...,'step',s) determines the step size magnitude (default is 1; in this case the
% steps will be U(0,1) for the uniform distribution or N(0,1) for the normal distribution). 
% 
% Written by Edden Gerber 2011

d = 1;          % default distribution is uniform
bound = 0; % default is no bound
step = 1;   % default step size is 1

narg = size(varargin,2);
arg = 1;
while arg < narg
    switch varargin{arg}
        case 'uniform'
            d = 1;
            arg = arg + 1;
        case 'normal'
            d=2;
            arg = arg + 1;
        case 'bound'
            bound = varargin{arg+1};
            arg = arg + 2;
        case 'step'
            step = varargin{arg+1};
            arg  = arg + 2;
    end
end

switch d
    case 1
        x = rand(length,1)*2*step-step;
    case 2
        x = rand(length,1);
        x = norminv(x)*step;
end

for i=2:length
    x(i) = x(i) + x(i-1);
    if bound ~= 0
        pull = x(i)/bound*step/2;
        x(i) = x(i) - pull;
    end
end
end
