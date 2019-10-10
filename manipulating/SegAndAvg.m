function [AVG SEGS REJ] = SegAndAvg ( data, locs, window, varargin)
% SEGANDAVG returns an average of the input data over event-windows. 
%
% AVG = SegAndAvg(DATA, LOCS, WINDOW) averages together segments
% each defined by LOCS(i) + WINDOW, where LOCS is a vector of event occurance 
% times and WINDOW is the averaging window relative to each occurance. Note 
% that in WINDOW, negative values correspond to the pre-event period.
%
% AVG = SegAndAvg(...,'dim',d) specifies dimension d as the dimension on
% which segmentation and averaging will be performed (for instance, if 
% the input data is arranged as Frequency * Time and segmentation is to 
% be done on the time dimension, set d = 2). Default value is 1. However, if 
% the input data is a row or column vector, there is no need to explicitly 
% specify the dimension. 
% 
% AVG = SegAndAvg(...,'reject',L) specifies a list of indices L corresponding
% to bad data locations. Segments overlapping these locations will be
% excluded. 
%
% AVG = SegAndAvg(...,'rejectwin',W) specifies the range within each
% segment which is sensitive to bad data (e.g. only the post-stimulus part
% of a peri-stimulus window, etc.). W can be either a logical vector the same size 
% as the intended segment size, with logical 1's indicating sensitive regions, or a 
% scalar vector with the equivalent indexes. If W is a matrix, then it must be a 
% logical L x N matrix, where L is the segment length and N is the number of 
% segmentation locations, and the rejection-sensitivity mask is then given for each 
% segment separately. 
% 
% AVG = SegAndAvg(...,'warnings','on'/'off') speficifies whether text warnings
% will be displayed. Default is 'on'.
%
% [AVG SEGS] = SegAndAvg(...) returns a matrix of individual segments
% in addition to the average. The segments dimension will be the last one. 
%
% [AVG SEGS REJ] = SegAndAvg(...) returns a vector of location indexes
% which corresponded to rejected segments, due to them being either
% out-of-range or overlapping rejected data locations.
%
% Written by Edden Gerber, lab of Leon Y. Deouell, April 2011.
% Please send bug reports and requsts to edden.gerber@gmail.com
%
% Modification history:
% 18.11.2013 (Edden): Added a warning in case NaN values are averaged.


% Handle optional input variables
Dim = 1;
ShowWarnings = true;
Reject = [];
RejectWin = 1:length(window);

narg = size(varargin,2);
arg = 1;
while arg < narg
    switch lower(varargin{arg})
        case 'dim'
            if isscalar(varargin{arg+1})
                Dim = varargin{arg+1};
                arg = arg + 2;
            else
                error('Input variable following ''dim'' should be a scalar.');
            end
        case 'warnings'
            if ischar(varargin{arg+1})
                switch lower(varargin{arg+1})
                    case 'on'
                        ShowWarnings = true;
                    case 'off'
                        ShowWarnings = false;
                    otherwise
                        error('''warnings'' tag must be followed by ''on'' or ''off''.');
                end
                arg = arg + 2;
            else
                error('Input variable following ''warnings'' should be ''on'' or ''off''.');
            end
        case 'reject'
            if ismatrix(varargin{arg+1})
                Reject = varargin{arg+1};
                arg = arg + 2;
            else
                error('Input variable following ''reject'' should be a scalar array.');
            end
        case 'rejectwin'
            if ismatrix(varargin{arg+1})
                RejectWin = varargin{arg+1};
                arg = arg + 2;
            else
                error('Input variable following ''rejectwin'' should be a scalar array.');
            end
    end
end

% Make sure there are no NANs in the input parameters:
if any(isnan(locs(:))) 
    error('There should not be NaN values in the "locs" input argument');
end
if any(isnan(window(:))) 
    error('There should not be NaN values in the "window" input argument');
end

% Make sure locs, window and Reject are column vectors
if size(locs,1)==1;locs = locs';end;
if size(window,1)==1;window = window';end;
if size(Reject,1)==1;Reject = Reject';end;
if size(RejectWin,1)==1;RejectWin = RejectWin';end;


% If no dimension was specified and data is a row vector, change it to a column vector
if Dim == 1 && size(data,1)==1
    data = data';
end

% If RejectWin was given as a scalar vector, change it to logical
if isvector(RejectWin) && ~islogical(RejectWin)
    temp = false(size(window));
    temp(RejectWin) = true;
    RejectWin = temp;
    clear temp;
end

% Initialize 
NumSegs = length(locs);
WinLen = length(window);
NDims = ndims(data);
if NDims == 2 && (size(data,1)==1 || size(data,2)==1)
    NDims = 1;
end

% Cycle data dimensions so that the relevant one is first (it's simpler this way).
data = shiftdim(data,Dim-1);

% Create segment indices matrix
temp1 = repmat(window,1,NumSegs);
temp2 = repmat(locs',WinLen,1);
SegInd = temp1 + temp2;
clear temp1 temp2

% Filter out rejected segments
if isvector(RejectWin)
    ArtInd = ismember(SegInd(RejectWin,:),Reject);
else
    temp = zeros(size(SegInd));
    temp(RejectWin) = SegInd(RejectWin);
    ArtInd = ismember(temp,Reject);
end
NoArtSeg = find(sum(ArtInd,1)==0);
ArtSeg = find(sum(ArtInd,1)>0);
NoArt = SegInd(:,NoArtSeg);
NumRejSegs = length(ArtSeg);

% Filter out segments out of range
OutRange = (NoArt<1) | (NoArt > size(data,1));
OutRangeSeg = find(sum(OutRange,1)>0);
NoOutRangeSeg = sum(OutRange,1)==0;
InRange = NoArt(:,NoOutRangeSeg);
NumOutRange = length(OutRangeSeg);
NumSegs = size(InRange,2);

% List segments which have been rejected
REJ = unique(sort([ArtSeg' ; OutRangeSeg']));

if ShowWarnings && (NumRejSegs + NumOutRange > 0)
    disp(['SegAndAvg: ' num2str(NumRejSegs) ' bad segments and ' num2str(NumOutRange) ' out-of-range segment were excluded out of ' num2str(size(SegInd,2)) ' segments.']);
end

% Create output segments
OutDims = size(data);
OutDims = OutDims(1:NDims); % in case NDims==1
OutDims(1) = WinLen;
OutDims(3:(NDims+1)) = OutDims(2:NDims);
OutDims(2) = NumSegs;

SEGS = data(InRange,:,:,:,:,:,:,:,:,:,:,:);
SEGS = reshape(SEGS,OutDims);

if isempty(SEGS)
    AVG = [];
    error('No segments remaining after segment rejection');
end

% Re-arrange dimensions (cycle back to original order and add the segments last)
Order = 1:(NDims+1);
Order = circshift(Order,[1 Dim-1]);
t = Order(Dim+1);
Order(Dim+1) = [];
Order(NDims+1) = t;
SEGS = permute(SEGS,Order);

% Calculate segments average
if any(isnan(SEGS(:)))
   if ShowWarnings
       disp('SegAndAvg warning: data contains NaN values, averaging using nanmean'); 
   end
   AVG = nanmean(SEGS,NDims+1);
else
    AVG = mean(SEGS,NDims+1);
end

AVG = squeeze(AVG);

end