function [ handles ] = scalpview( varargin )
% Plots multiple axes on a figure each of which corresponds to the location of an electrode on the scalp. 
% Usage:
% h = scalpview(cmd) runs the string cmd as a command for each electrode. If the string includes the
% variable INDEX (capitalized), then that variable will take on the index of the specific electrode
% for each plot. h is a structure which holds the handles of the figure and of all the individual axes objects. 
% Example: 
% Assuming that D is a time x channel matrix, then: 
% cmd = 'plot(data(:,INDEX))' ;
% h = scalpview(cmd); 
% - Will plot the time course of each electrode individually.
% 
% scalpview(h,cmd) will apply the commands in the string cmd to the figure referred to by h, which
% is the handle structure returned by the previous run of the function. For example:
% scalpview(h,'xlim([0 1])');
% Will set the x-limits in every single plot of the existing scalpview figure. 
% 
% scalpview(cmd,...,ChannelList), where ChannelList is a 1D cell array, defines the names of the 
% electrodes in the data set. These should be the standard names corresponding to those found 
% in the ChannelMap variable. If not set, the default 71-electrode arrangement is assumed (see
% inside the function for its structure). 
% 
% scalpview(cmd,...,ChannelMap), where ChannelMap is a 2D cell matrix, defines the arrangement
% of electrode plots in the figure. If not set, the default 71-electrode arrangement is assumed (see
% inside the function for its structure). 
%
% scalpview(cmd...,'labels',Flag), where Flag is either the string 'on' or 'off', will determine
% whether to present channel labels on plots. Default value is 'on'.
%
% Written by Edden Gerber, lab of Leon Y. Deouell, 2011
% Please send bug reports and requsts to edden.gerber@gmail.com


% Configuration
HorizontalPlotSpace = 0.1;
VerticalPlotSpace = 0.2;
TopMarg = 10;
BottomMarg = 20;
LeftMarg = 10;
RightMarg = 10;

ChannelMap = {...
            [],                 [],                  [],                     'LHEOG',      [],                   'Nose',          [],                  'RHEOG'         [],                  [],                  'RVEOGS' ;...
            ['LVEOGI'], [],                  [],                    'Fp1',             [],                   'Fpz',            [],                  'Fp2',               [],                   [],                  'RVEOGI' ;...
            [],                'AF7',            [],                    'AF3',             [],                   'AFz',            [],                  'AF4',               [],                 'AF8',              [] ;...
            [],                'F7',              'F5',                'F3',               'F1',               'Fz',              'F2',               'F4',                'F6',              'F8',                [] ;...
            [],                'FT7',           'FC5',             'FC3',             'FC1',            'FCz',           'FC2',            'FC4',              'FC6',           'FT8',              [] ; ...
            [],                'T7',               'C5',               'C3',               'C1',               'Cz',              'C2',               'C4',                'C6',              'T8',                [] ; ...
            [],                'TP7',            'CP5',            'CP3',             'CP1',            'CPz',            'CP2',            'CP4',             'CP6',            'TP8',             [] ; ...
            'P9',           'P7',               'P5',               'P3',               'P1',               'Pz',               'P2',               'P4',               'P6',               'P8',               'P10' ; ...
            [],                'PO7',            [],                   'PO3',              [],                   'POz',            [],                   'PO4',              [],                   'PO8',             [] ; ...
            [],                 [],                  [],                     [],                   'O1',                'Oz',             'O2',                [],                     []                    [],                    [] ;...
            ['M1'],                 [],                  [],                     [],                    [],                   'Iz',               [],                    [],                    [],                    [],                   ['M2'] };
        
ChannelList = {'Fp1'; 'AF7'; 'AF3';'F1'; 'F3'; 'F5'; 'F7'; 'FT7'; 'FC5'; 'FC3'; 'FC1';'C1'; 'C3'; 'C5'; 'T7'; 'TP7'; 'CP5'; 'CP3'; 'CP1'; ....
                                    'P1'; 'P3'; 'P5'; 'P7'; 'P9'; 'PO7'; 'PO3'; 'O1';'Iz'; 'Oz'; 'POz'; 'Pz'; 'CPz'; 'Fpz';'Fp2'; 'AF8'; 'AF4'; 'AFz'; 'Fz';....
                                    'F2'; 'F4'; 'F6'; 'F8'; 'FT8'; 'FC6'; 'FC4'; 'FC2';'FCz';  'Cz';'C2'; 'C4'; 'C6'; 'T8'; 'TP8'; 'CP6'; 'CP4'; 'CP2';'P2'; ....
                                    'P4'; 'P6'; 'P8'; 'P10'; 'PO8'; 'PO4'; 'O2'; 'Nose';'LHEOG';'RHEOG';'RVEOGS';'RVEOGI';'M1';'M2';'LVEOGI'};


% Handle function input
newfig = true;
CMD = ''; 
handles = struct;								 % Handle structure for the GUI
ShowLabels = true;
HandleInput(varargin);

% Load map 
Map = LoadMap;

% Create new figure if necessary
if newfig
    CreateFig;
    maximize_figure;
    if exist('ERPfigure')==2 % check that ERPfigure is supported;
        ERPfigure(handles.figure);
    end
end

N = length(handles.axes);

% Plot
for INDEX = 1:N
    if ishandle(handles.axes(INDEX))
        % focus
        axes(handles.axes(INDEX));
        % modify command
        CMD_ind = strrep(CMD,'INDEX',num2str(INDEX));
        CMD_err = ['try; ' CMD_ind '; catch err; throw(err); end;'];
        evalin('caller',CMD_err);
        drawnow;
        if ShowLabels
            apos = get(handles.axes(INDEX),'position');
%             text('Units','pixels','Position',[5 apos(4)-5],'String',ChannelList{INDEX},'fontsize',8);
            text('Units','normalized','Position',[0.01 0.9],'String',ChannelList{INDEX},'fontsize',8);
        end
    end
end

%% Nested functions 

% Handle input
    function HandleInput(argin)
        % check legal number of input arguments
        if length(argin) < 1
        	error('Not enough input arguments.');
        end
        
        arg = 1;
        narg = length(argin);
        
        % Check if first parameter is a handle struct
        if isstruct(argin{arg})
            if ishandle(argin{arg}.figure)
                handles = argin{arg};
                arg = arg + 1;
                newfig = false;
            else
                error('Nonexistent or illegal handle');
            end
        end
        
        % Check if next parameter is a string command
        if ischar(argin{arg})
            CMD = argin{arg};
            arg = arg + 1;
        else 
            error('String command not detected.');
        end
        
        % Look at additional variables
        for arg = arg:narg
            switch class(argin{arg})
                case 'cell'
                    P = argin{arg};
                    if (size(P,1) == 1) || (size(P,2) == 1)     % vector - channel list
                        ChannelList = P;
                    else    % matrix - channel map
                        ChannelMap = P;
                    end
                    arg = arg + 1;
                case 'char'
                    switch argin{arg}
                        case 'labels'
                            if arg==narg; error( '''labels'' argument should be followed by ''on'' or ''off''.');end;
                            switch argin{arg+1}
                                case 'on'
                                    ShowLabels = true;
                                case 'off'
                                    ShowLabels = false;
                                otherwise
                                    error( '''labels'' argument should be followed by ''on'' or ''off''.');
                            end
                    end
            end
        end
    end

% Create a new figure
    function CreateFig
        
        % GUI parameter definitions
        set(0,'units','points');
        ScSize = get(0,'screensize');
        FigurePos = ScSize + [10 10 10 -100];
        
        % Figure
        handles.figure = figure('Name','Scalp View','NumberTitle','off','Position',FigurePos,'ReSize','on',...
            'Tag','SvGuiFig','ToolBar','figure','WindowStyle','normal','Visible','on','ResizeFcn',@fig_ResizeFcn,...
            'windowButtonDownFcn', @CopyToNewWindow);
        
        % Axes
        [ R C ] = size(Map);
        for r=1:R
            for c=1:C
                if Map(r,c) > 0
                    index = Map(r,c);
                    
                    FigSize = get(handles.figure,'Position'); 
                    FigSize = [FigSize(3) FigSize(4)];
                    HorSize = FigSize(1) / (C + (C+1)*HorizontalPlotSpace);
                    VerSize = FigSize(2) / (R + (R+1)*VerticalPlotSpace);
                    HorLoc = HorSize*HorizontalPlotSpace + (c-1)*HorSize*(1+HorizontalPlotSpace);
                    VerLoc = VerSize*VerticalPlotSpace + (R-r)*VerSize*(1+VerticalPlotSpace);
                    Position = [ HorLoc VerLoc HorSize VerSize ];
                    
                    handles.axes(index) = axes('Units','pixels','Position',[1 1 300 300],'FontSize',6);
                end
            end
        end
    end

% Load scalp map
    function Map= LoadMap
        
        Map = zeros(size(ChannelMap));
        
        for c=1:numel(ChannelMap)
            ind = find(strcmp(ChannelList,ChannelMap{c}));
            if ~isempty(ind)
                Map(c) = ind;
            end
        end
    end

%% GUI object functions

    function fig_ResizeFcn( hObject, eventdata )
        % Get sizes
        [ R C ] = size(Map);
        for r=1:R
            for c=1:C
                if Map(r,c) > 0
                    index = Map(r,c);
                    
                    FigSize = get(handles.figure,'Position'); 
                    FigSize = [FigSize(3)-(LeftMarg+RightMarg) FigSize(4)-(TopMarg+BottomMarg)];
                    HorSize = FigSize(1) / (C + (C+1)*HorizontalPlotSpace);
                    VerSize = FigSize(2) / (R + (R+1)*VerticalPlotSpace);
                    HorLoc = HorSize*HorizontalPlotSpace + (c-1)*HorSize*(1+HorizontalPlotSpace);
                    VerLoc = VerSize*VerticalPlotSpace + (R-r)*VerSize*(1+VerticalPlotSpace);
                    Position = [ HorLoc+LeftMarg VerLoc+BottomMarg HorSize VerSize ];
                    
                    set(handles.axes(index),'Position',Position);
                end
            end
        end
    end

end

function maximize_figure(h)
    % Maximize the figure (thanks to http://undocumentedmatlab.com/):

    drawnow; 
    if nargin <  1
        h = gcf;
    end
    jFrame = get(handle(h),'JavaFrame');
    jFrame.setMaximized(true);   % to maximize the figure
    clear jFrame
end

function f=CopyToNewWindow(a)
    %Copy current axes to a new figure window with all its children and prperties
    %(except position)
    %--------------------------
    %By Leon Deouell @ Hebrew University, Jerusalem, Israel

    if ~exist('a', 'var')
        a = gca;
    end
    f = ERPfigure;
    set(f,'visible','off')
    new = copyobj(a, f);
    set(new, 'units','normal','pos',[.1 .1 .8 .8])
    set(f,'windowButtonDownFcn',[]); % Edden 28.5.13 (clicking on the new figure will not open another). 
    set(f,'toolbar','figure'); % Edden 28.5.13 (show figure toolbar). 
    set(f, 'visible','on');
end
