function [ out_timestamps, out_values, deleted_event_indexes ] = inspect_events( event_timestamps, event_values, varargin )
%INSPECT_EVENTS is a graphical tool for inspecting the temporal structure of event 
% markers. It can be used both to manually inspect and modify event timing and values, 
% as well as to automatically remove illegal event seuqences. 
% 
% Syntax:
% [out_t, out_v] = INSPECT_EVENTS(t,v) Initiates the inspec_events tool. t is a 
%                                       vector of event timestamps, v is a vector of 
%                                       event values. out_t and out_v are the 
%                                       corresponding output vectors
%
% INSPECT_EVENTS(...'srate',s)         Where s is a scalar, indicates the sampling rate.
%                                       Displayed timestamps will be divided by this 
%                                       value. 
%
% INSPECT_EVENTS(...,c,v)              Where c is a single character string and v is 
%                                       a vector of event values, defines an event 
%                                       category identified by the character symbol c  
%                                       and comprising the list of events v.
%
% INSPECT_EVENTS(...,'exp',e)          where e is a string, initializes the
%                                       inspect_events tool with the regular expression 
%                                       string e. 
%
% INSPECT_EVENTS(...,'auto',s)         where s is a string equal to either
%                                       'match' or 'nonmatch', indicates that the function 
%                                       should run on automatic non-GUI mode, deleting 
%                                       any events which either match or do not match 
%                                       the regular expression given using the 'exp' 
%                                       argument.
%
% Written by Edden M. Gerber, lab of Leon Y. Deouell, Sep. 2014. 
% Please send bug reports and feature requests to edden.gerber@gmail.com
%

%% Parameters

% Figure dimensions
FIGURE_PIXEL_SIZE = [700 850];

% Font size
TEXT_FONT_SIZE = 11;

% Object position guidelines (normalized to figure dimensions)
BUTTON_HEIGHT = 0.04;
PLOT_Y_POS = 0.05;
PLOT_HEIGHT = 0.2;
EVENTS_TABLE_Y_POS = 0.35;
EVENTS_TABLE_HEIGHT = 0.26;
REGEXP_Y_POS = 0.68;
CATEG_TABLE_Y_POS = 0.8;
CATEG_TABLE_HEIGHT = 0.15;
CATEG_TABLE_X_POS = 0.28;

% Graphical object positions in figure (normalized)
POS_AXES = [0.05 PLOT_Y_POS 0.9 PLOT_HEIGHT];
POS_TEXT_PLOT_TITLE = [0.05 PLOT_Y_POS+PLOT_HEIGHT 0.9 0.02];
POS_BUTTON_DEL_SELECTED = [0.05 EVENTS_TABLE_Y_POS-BUTTON_HEIGHT 0.225 BUTTON_HEIGHT];
POS_BUTTON_DEL_MATCH = [0.275 EVENTS_TABLE_Y_POS-BUTTON_HEIGHT 0.225 BUTTON_HEIGHT];
POS_BUTTON_DEL_NONMATCH = [0.5 EVENTS_TABLE_Y_POS-BUTTON_HEIGHT 0.225 BUTTON_HEIGHT];
POS_BUTTON_RESTORE = [0.725 EVENTS_TABLE_Y_POS-BUTTON_HEIGHT 0.225 BUTTON_HEIGHT];
POS_TABLE_EVENTS = [0.05 EVENTS_TABLE_Y_POS 0.9 EVENTS_TABLE_HEIGHT];
POS_BUTTON_PREV_M = [0.05 EVENTS_TABLE_Y_POS+EVENTS_TABLE_HEIGHT 0.225 BUTTON_HEIGHT];
POS_BUTTON_NEXT_M = [0.275 EVENTS_TABLE_Y_POS+EVENTS_TABLE_HEIGHT 0.225 BUTTON_HEIGHT];
POS_BUTTON_PREV_NM = [0.5 EVENTS_TABLE_Y_POS+EVENTS_TABLE_HEIGHT 0.225 BUTTON_HEIGHT];
POS_BUTTON_NEXT_NM = [0.725 EVENTS_TABLE_Y_POS+EVENTS_TABLE_HEIGHT 0.225 BUTTON_HEIGHT];
POS_TEXT_EVENTS_TITLE = [0.05 EVENTS_TABLE_Y_POS+EVENTS_TABLE_HEIGHT+BUTTON_HEIGHT 0.9 0.02];
POS_TEXT_REGEXP_SUMMARY = [0.28 REGEXP_Y_POS 0.9 0.02];
POS_TEXT_REGEXP = [0.05 REGEXP_Y_POS+0.03 0.27 0.02];
POS_EDIT_REGEXP = [0.28 REGEXP_Y_POS+0.02 0.52 BUTTON_HEIGHT];
POS_BUTTON_RUN = [0.8 REGEXP_Y_POS+0.02 0.09 BUTTON_HEIGHT];
POS_BUTTON_REGEXP_HELP = [0.89 REGEXP_Y_POS+0.02 0.06 BUTTON_HEIGHT];
POS_TEXT_CATEGORY_SUMMARY = [CATEG_TABLE_X_POS CATEG_TABLE_Y_POS-0.03 0.95-CATEG_TABLE_X_POS 0.03];
POS_TABLE_FREQUENCIES = [0.05 CATEG_TABLE_Y_POS CATEG_TABLE_X_POS-0.055 CATEG_TABLE_HEIGHT];
POS_TABLE_CATEGORIES = [CATEG_TABLE_X_POS CATEG_TABLE_Y_POS 0.8-CATEG_TABLE_X_POS CATEG_TABLE_HEIGHT];
POS_BUTTON_ADD_CATEGORY = [0.8 CATEG_TABLE_Y_POS+CATEG_TABLE_HEIGHT*2/3 0.15 CATEG_TABLE_HEIGHT/3];
POS_BUTTON_DEL_CATEGORY = [0.8 CATEG_TABLE_Y_POS+CATEG_TABLE_HEIGHT/3 0.15 CATEG_TABLE_HEIGHT/3];
POS_BUTTON_CATEG_HELP = [0.8 CATEG_TABLE_Y_POS 0.15 CATEG_TABLE_HEIGHT/3];
POS_TEXT_FREQ_TITLE = [0.05 CATEG_TABLE_Y_POS+CATEG_TABLE_HEIGHT CATEG_TABLE_X_POS-0.05 0.02];
POS_TEXT_CATEG_TITLE = [CATEG_TABLE_X_POS CATEG_TABLE_Y_POS+CATEG_TABLE_HEIGHT 0.8-CATEG_TABLE_X_POS 0.02];

% Table column widths (pixels)
TAB_FREQ_COL_WIDTHS = {53, 53};
TAB_CATEG_COL_WIDTHS = {55, 205, 55};
TAB_MARK_COL_WIDTHS = {111, 111, 111, 111, 111};

%% Handle input

% Validate input
if ~isvector(event_timestamps) || ~isnumeric(event_timestamps) || ~isvector(event_values) || ~isnumeric(event_values)
    error('inspect_events: timestamps and event values expected to be numeric vectors');
end
if length(event_timestamps) ~= length(event_values)
    error('inspect_events: timestamps and values vectors should have equal length');
end
% Turn row vectors into columns
if size(event_timestamps,1) == 1
    event_timestamps = event_timestamps'; 
end
if size(event_values,1) == 1
    event_values = event_values'; 
end

% Initialize optional arguments
srate = 1;
inputCategoryNames = {};
inputCategoryLists = {};
regExpString = [];
autoRun = false;
printReport = [];
groupToDelete = '';

% read optional arguments
narg = size(varargin,2);
arg  = 1;
while arg <= narg
    if ischar(varargin{arg})
        switch varargin{arg}
            case 'srate'
                if narg > arg && isscalar(varargin{arg+1}) && isnumeric(varargin{arg+1})
                    srate = varargin{arg+1};
                    arg = arg + 2;
                else 
                    error('inspect_events: ''srate'' argument should be followed by a scalar.');
                end
            case 'auto'
                if narg > arg && (strcmp(varargin{arg+1},'match') || strcmp(varargin{arg+1},'nonmatch'))
                    autoRun = true;
                    groupToDelete = varargin{arg+1};
                    arg = arg + 2;
                else
                    error('inspect_events: ''auto'' argument should be followed by either ''match'' or ''nonmatch''.');
                end
            case 'report'
                if nargin > arg && isscalar(varargin{arg+1}) && (isnumeric(varargin{arg+1}) || islogical(varargin{arg+1}))
                    printReport = logical(varargin{arg+1});
                    arg = arg + 2;
                else
                    error('inspect_events: ''report'' argument should be followed by true or false.');
                end
            case 'exp'
                if narg > arg && ischar(varargin{arg+1})
                    regExpString = varargin{arg+1};
                    arg = arg + 2;
                else
                    error('inspect_events: ''exp'' argument should be followed by a regular expression string.');
                end
            case '?'
                error('inspect_events: Character ''?'' is reserved for un-undentified events and cannot be set by user');
            otherwise
                if isscalar(varargin{arg})
                    if narg > arg && isvector(varargin{arg+1}) && isnumeric(varargin{arg+1})
                        inputCategoryNames{end+1} = varargin{arg};
                        inputCategoryLists{end+1} = varargin{arg+1};
                        arg = arg + 2;
                    else
                        error('inspect_events: A character defining a trigger category should be followed by a numeric vector listing the trigger values it includes.');
                    end
                else
                    error('inspect_events: Only single characters accepted as event symbols.');
                end
        end
    else 
        error(['inspect_events: Unknown argument: ' varargin{arg} '. To define a trigger category, use a single character.']);
    end
end

%% Initialize

% Set figure position according to FIGURE_PIXEL_SIZE:
screen_pos = get(0,'monitorposition');
figure_size_norm = [FIGURE_PIXEL_SIZE(1)/screen_pos(3) FIGURE_PIXEL_SIZE(2)/screen_pos(4)];
POS_FIGURE = [(1-figure_size_norm(1))/2 (1-figure_size_norm(2))/2 figure_size_norm(1) figure_size_norm(2)];

% Initialize handles structure
h = struct;

% Initialize event character string
event_symbol_string = repmat('?',1,length(event_values));

% Initialize tables
dataFrequencies = num2cell(ucount(event_values));

dataCategories = cell(length(inputCategoryNames),3);
dataCategories(:,1) = inputCategoryNames;
for c = 1:length(inputCategoryLists)
    dataCategories{c,2} = num2str(inputCategoryLists{c});
    dataCategories(c,3) = {[]};
end

dataMarkers = cell(length(event_timestamps),5);
dataMarkers(:,1) = num2cell(event_timestamps/srate);
dataMarkers(:,2) = num2cell([event_timestamps(1)/srate ; diff(event_timestamps/srate)]);
dataMarkers(:,3) = num2cell(event_values);
dataMarkers(:,4) = num2cell(event_symbol_string);
dataMarkers(:,5) = {'-'};
nMarkers = size(dataMarkers,1);

nCategories = size(dataCategories,1);

% Initialize regular-expression result vectors
regexpMatchVector = false(size(event_timestamps));
matchIndexes = 1:length(event_timestamps);
nonmatchIndexes = [];

% Decide whether to print report on termination
if isempty(printReport)
    if autoRun
        printReport = true;
    else
        printReport = false;
    end
end

% Initialize other variables
originalIndexes = 1:length(event_values);
numDeletedEvents = 0;
deleted_event_indexes = [];

%% Generate GUI

if ~autoRun
    % Table column names
    mrkColNames = {'Timestamp ','Time from Previous ','Event Value ','Category ','RegExp Match '};
    catColNames = {'Symbol ', 'Event Values ','Count '};
    freqColNames = {'Value ','Count '};
    
    % Figure
    h.fig = figure('units','normalized','position',POS_FIGURE,'toolbar','figure','DeleteFcn',@callback_figure_delete);

    % Labels
    h.FreqTableTitle = uicontrol('style','text','units','normalized','position',POS_TEXT_FREQ_TITLE,...
        'HorizontalAlignment','center','fontsize',9,'fontweight','bold','BackgroundColor',get(gcf,'color'),...
        'string','Event Frequencies');
    h.FreqTableTitle = uicontrol('style','text','units','normalized','position',POS_TEXT_CATEG_TITLE,...
        'HorizontalAlignment','center','fontsize',9,'fontweight','bold','BackgroundColor',get(gcf,'color'),...
        'string','Event Categories');
    h.MarkerTableTitle = uicontrol('style','text','units','normalized','position',POS_TEXT_EVENTS_TITLE,...
        'HorizontalAlignment','center','fontsize',9,'fontweight','bold','BackgroundColor',get(gcf,'color'),...
        'string','Event List');
    h.PlotTitle = uicontrol('style','text','units','normalized','position',POS_TEXT_PLOT_TITLE,...
        'HorizontalAlignment','center','fontsize',9,'fontweight','bold','BackgroundColor',get(gcf,'color'),...
        'string','Event Plot');
    
    % Event frequencies table
    h.tableFrequencies = uitable('units','normalized','position',POS_TABLE_FREQUENCIES,...
        'ColumnName',freqColNames,'ColumnFormat',{'char','char'},'fontsize',TEXT_FONT_SIZE,...
        'ColumnEditable',[false false],'ColumnWidth',TAB_FREQ_COL_WIDTHS,'ToolTip','List of event frequencies');    
    
    % Event categories table
    h.tableCategories = uitable('units','normalized','position',POS_TABLE_CATEGORIES,...
        'ColumnName',catColNames,'fontsize',TEXT_FONT_SIZE,'ColumnEditable',[true true false],...
    'ColumnFormat',{'char','char','numeric'},'ColumnWidth',TAB_CATEG_COL_WIDTHS,...
        'CellEditCallback',@callback_tableCateg_edit,'CellSelectionCallback',@callback_tableCateg_select,...
        'ToolTip','List of event categories');
    h.addCategButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_ADD_CATEGORY,...
        'string','Add Category','CallBack',@callback_button_addCateg);
    h.delCategButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_DEL_CATEGORY,...
        'string','Delete Category','CallBack',@callback_button_delCateg);
    h.CategHelpButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_CATEG_HELP,...
        'string','Help','CallBack',@callback_button_CategHelp);

    % Status string
    h.statusLabel = uicontrol('style','text','units','normalized','position',POS_TEXT_CATEGORY_SUMMARY,...
        'HorizontalAlignment','left','fontsize',9,'BackgroundColor',get(gcf,'color'));

    % Regular expression input - label, edit box, run button help buttons,
    % summary text
    h.regextLabel = uicontrol('style','text','units','normalized','position',POS_TEXT_REGEXP,...
        'HorizontalAlignment','left','string','Apply Regular Expression:','fontsize',9,'FontWeight','bold',...
        'BackgroundColor',get(gcf,'color'));
    h.regexpEdit = uicontrol('style','edit','units','normalized','position',POS_EDIT_REGEXP,...
        'HorizontalAlignment','left','BackgroundColor','w','string',{regExpString},'fontsize',12,...
        'CallBack',@callback_edit_regExp);
    h.runButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_RUN,...
        'string','Run','callback',@callback_button_runRegexp);
    h.helpButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_REGEXP_HELP,...
        'string','?','CallBack',@callback_button_regExpHelp);
    h.regExpSummary = uicontrol('style','text','units','normalized','position',POS_TEXT_REGEXP_SUMMARY,...
        'HorizontalAlignment','left','fontsize',9,'BackgroundColor',get(gcf,'color'));

    % Event navigation buttons
    h.prevMatchButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_PREV_M,...
        'string','Previous Match','enable','off','CallBack',@callback_button_prevMatch);
    h.nextMatchButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_NEXT_M,...
        'string','Next Match','enable','off','CallBack',@callback_button_nextMatch);
    h.prevNonmatchButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_PREV_NM,...
        'string','Previous Non-Match','enable','off','CallBack',@callback_button_prevNonMatch);
    h.nextNonmatchButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_NEXT_NM,...
        'string','Next Non-Match','enable','off','CallBack',@callback_button_nextNonMatch);

    % Events table
    h.tableMarkers = uitable('units','normalized','position',POS_TABLE_EVENTS,'ColumnName',mrkColNames,...
        'ColumnFormat',{'char','char','char','char','char'},'ColumnEditable',[true false true false],...
        'CellEditCallback',@callback_tableMarkers_edit,'CellSelectionCallback',@callback_tableMarkers_select,...
        'FontSize',TEXT_FONT_SIZE,'ColumnWidth',TAB_MARK_COL_WIDTHS,'ToolTip','List of events');

    % Event deletion buttons
    h.delSelectedButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_DEL_SELECTED,...
        'string','Delete Selected Event','enable','on','CallBack',@callback_button_deleteSelected);
    h.delMatchesButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_DEL_MATCH,...
        'string','Delete All Matches','enable','off','CallBack',@callback_button_deleteMatches);
    h.delNonMatchesButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_DEL_NONMATCH,...
        'string','Delete All Non-matches','enable','off','CallBack',@callback_button_deleteNonMatches);
    h.delRestoreButton = uicontrol('style','pushbutton','units','normalized','position',POS_BUTTON_RESTORE,...
        'string','Restore Original Events','enable','on','CallBack',@callback_button_restoreMarkers);

    % Axes 
    h.axes = axes('position',POS_AXES);

    % Get java object handles
    h.java.tableCategories = findjobj(h.tableCategories);
    h.java.tableCategories_scroll = h.java.tableCategories.getVerticalScrollBar;
    h.java.tableMarkers = findjobj(h.tableMarkers);
    h.java.tableMarkers_scroll = h.java.tableMarkers.getVerticalScrollBar;
end

%% Run 

% Update data
update_data;

% Update GUI
update_gui;

if autoRun
    switch groupToDelete
        case 'match'
            selected = find(regexpMatchVector);
            delete_markers(selected);
        case 'nonmatch'
            selected = find(~regexpMatchVector);
            delete_markers(selected);
        otherwise
            error('inspect_data: unexpected value for variable ''groupToDelete''.');
    end
    display_report;
elseif nargout > 0
    % If output requested, wait for figure to close
    waitfor(gcf);
end

out_timestamps = round(cell2mat(dataMarkers(:,1))*srate);
out_values = cell2mat(dataMarkers(:,3));

%% Nested functions

    function update_data
        % Convert event value vector to event symbol string
        v = cell2mat(dataMarkers(:,3));
        cSymbols = dataCategories(:,1);
        cLists = dataCategories(:,2);
        event_symbol_string = repmat('?',1,length(v));
        for c = nCategories:-1:1 % Starting from the end so that categories placed on top of the list will have the final word
            idx = ismember(v,str2num(cLists{c}));
            event_symbol_string(idx) = cSymbols{c};
            % update 3rd column
            dataCategories{c,3} = sum(idx);
        end
        
        % Run regular expression 
        regexpMatchVector(:) = false;
        if ~isempty(regExpString)
            [a, b] = regexp(event_symbol_string,regExpString);
            for i = 1:length(a)
                regexpMatchVector(a(i):b(i)) = true;
            end
        end
        matchIndexes = find(regexpMatchVector);
        nonmatchIndexes = find(~regexpMatchVector);
        
        % Update frequencies table
        dataFrequencies = num2cell(ucount(cell2mat(dataMarkers(:,3))));
        
        % Update markers table
        [~,idx] = sort(cell2mat(dataMarkers(:,1)));
        dataMarkers = dataMarkers(idx,:);
        if ~isempty(dataMarkers) % If all the markers were deleted, this could produce an error
            dataMarkers(:,2) = num2cell([dataMarkers{1,1} ; diff(cell2mat(dataMarkers(:,1)))]);
        end
        dataMarkers(:,4) = num2cell(event_symbol_string');
        for m=1:nMarkers
            if isempty(regExpString)
                dataMarkers{m,5} = '-';
            elseif regexpMatchVector(m)
                dataMarkers{m,5} = '<HTML><FONT color="green">yes</Font></html>';
            else
                dataMarkers{m,5} = '<HTML><FONT color="blue">no</Font></html>';
            end
        end        
    end

    function update_gui
        
        if ~autoRun
            % First get the current scroll locations so they can be restored:
            categCurrentLine = get_table_scroll_position(h.java.tableCategories_scroll,length(get(h.tableCategories,'Data')));
            markersCurrentLine = get_table_scroll_position(h.java.tableMarkers_scroll,length(get(h.tableMarkers,'Data')));

            % Update tables
            set(h.tableFrequencies,'Data',dataFrequencies);
            set(h.tableCategories,'Data',dataCategories);
            set(h.tableMarkers,'Data',dataMarkers);
            
            % Set status texts
            set(h.statusLabel,'string',[num2str(sum(event_symbol_string=='?')) ' uncategorized markers out of ' num2str(nMarkers) '.']);
            if ~isempty(regExpString)
                set(h.regExpSummary,'string',['Found ' num2str(sum(regexpMatchVector)) ' matches and ' ...
                    num2str(sum(~regexpMatchVector)) ' non-matches.']);
            else
                set(h.regExpSummary,'string','');
            end

            drawnow; % finish rendering first to avoid interference with the next java operations
            % Jump to previous scroll location in tables
            set_table_scroll_position(h.java.tableCategories_scroll,categCurrentLine,nCategories);
            set_table_scroll_position(h.java.tableMarkers_scroll,markersCurrentLine,nMarkers);
            drawnow;

            % Draw markers plot
            t = cell2mat(dataMarkers(:,1));
            v = cell2mat(dataMarkers(:,3));
            if isempty(regExpString)
                stem(h.axes,t,v,'b','linewidth',1,'MarkerSize',3);
            else
                stem(h.axes,t(~regexpMatchVector),v(~regexpMatchVector),'b','linewidth',1,'MarkerSize',3);
                hold on
                stem(h.axes,t(regexpMatchVector),v(regexpMatchVector),'g','linewidth',1,'MarkerSize',3);
                hold off
            end
            xlim([0 t(end)]);

            % Enable/disable GUI components
            if ~isempty(regExpString)
                % enable push buttons
                set(h.prevMatchButton,'enable','on');
                set(h.nextMatchButton,'enable','on');
                set(h.prevNonmatchButton,'enable','on');
                set(h.nextNonmatchButton,'enable','on');
                set(h.delMatchesButton,'enable','on');
                set(h.delNonMatchesButton,'enable','on');
            else
                %disable push buttons
                set(h.prevMatchButton,'enable','off');
                set(h.nextMatchButton,'enable','off');
                set(h.prevNonmatchButton,'enable','off');
                set(h.nextNonmatchButton,'enable','off');
                set(h.delMatchesButton,'enable','off');
                set(h.delNonMatchesButton,'enable','off');
            end
        end
    end

    function delete_markers(markerIndexes)
        dataMarkers(markerIndexes,:) = [];
        regexpMatchVector(markerIndexes) = [];
        nMarkers = nMarkers - length(markerIndexes);
        
        % These variables are for reporting:
        deleted_event_indexes = [deleted_event_indexes originalIndexes(markerIndexes)'];
        originalIndexes(markerIndexes) = [];
        numDeletedEvents = numDeletedEvents + length(markerIndexes);
        
        update_data;
        update_gui;
    end

    function display_report
        % Report shows marker categories; if none are defined it will show
        % marker frequencies
        if nCategories > 0 && ~strcmp(dataCategories{1,1},' ')
            numUncategorized = sum(event_symbol_string=='?');
            categorizedValues = [];
            for c = 1:nCategories
                categorizedValues = [categorizedValues str2num(dataCategories{c,2})];
            end
            uncategorizedValues = unique(cell2mat(dataMarkers(:,3)))';
            uncategorizedValues(ismember(uncategorizedValues,categorizedValues)) = [];
            
            Tcateg = table(dataCategories(:,1),cell2mat(dataCategories(:,3)),'VariableNames',{'Symbol','Count'});        
            lastRow = table({'Uncategorized'},numUncategorized,'VariableNames',{'Symbol','Count'});
            Tcateg = [Tcateg ; lastRow];
            
            disp('inspect_events Report:');
            disp('');
            disp(Tcateg);
            if numUncategorized > 0
                disp(['Uncategorized event values: ' num2str(uncategorizedValues) '.']);
            end
            disp(['Number of deleted events: ' num2str(numDeletedEvents) '.']);
            
        else
            Tfreq = table(cell2mat(dataFrequencies(:,1)),cell2mat(dataFrequencies(:,2)),'VariableNames',{'Value','Count'});
            disp('inspect_events Report:');
            disp('');
            disp(Tfreq);
            disp(['Number of deleted events: ' num2str(numDeletedEvents) '.']);
        end
    end

    function set_table_scroll_position(jobject,line,nLines)
        % Jave command
        try
            jobject.setValue(jobject.getMaximum*(line-1)/nLines);
            pause(0.001);
        catch
            warning('inspect_events: Java command error');
        end
    end

    function line = get_table_scroll_position(jobject,nLines)
        % Java command
        try
            line = round(jobject.getValue / jobject.getMaximum * nLines) + 1;
        catch 
            warning('inspect_events: Java command error');
            line = 1;
        end
    end

%% Graphical object callbaclk functions
    
    function callback_figure_delete(hObject, eventdata)
        if printReport
            display_report;
        end
    end

    function callback_tableCateg_edit(hObject, eventdata, handles)
        row = eventdata.Indices(1);
        col = eventdata.Indices(2);
        in = eventdata.NewData;
        switch col
            case 1
                if isempty(in)
                    dataCategories{row,1} = ' ';
                else
                    in = eventdata.NewData(1); % Take just the first characted
                    dataCategories{row,1} = in;
                end
            case 2
                if ~isempty(str2num(in))
                    dataCategories{row,2} = num2str(sort(unique(str2num(in))));
                else
                    errordlg('Only numeric vectors accepted');
                end
        end
        update_data;
        update_gui;
    end

    function callback_tableCateg_select(hObject, eventdata, handles)
        % Record the number of the selected row
        if ~isempty(eventdata.Indices)
            set(hObject,'UserData',eventdata.Indices(1)); % The "UserData" property will hold the selected row number
        else
            set(hObject,'UserData',[]);
        end
    end

    function callback_tableMarkers_edit(hObject, eventdata, handles)
        row = eventdata.Indices(1);
        col = eventdata.Indices(2);
        in = eventdata.NewData;
        switch col
            case 1
                if ~isempty(in)
                    if isscalar(in)
                        dataMarkers{row,1} = in;
                    else
                        errordlg('Only scalars accepted');
                    end
                end
            case 3
                if ~isempty(in)
                    if ~isnan(in) && isscalar(in)
                        dataMarkers{row,3} = floor(in);
                    else
                        errordlg('Only scalars accepted');
                    end
                end
        end
        update_data;
        update_gui;
    end

    function callback_tableMarkers_select(hObject, eventdata, handles)
        % Record the number of the selected row
        if ~isempty(eventdata.Indices)
            set(hObject,'UserData',eventdata.Indices(1)); % The "UserData" property will hold the selected row number
        else
            set(hObject,'UserData',[]);
        end
    end

    function callback_edit_regExp(hObject, eventdata, handles)
        callback_button_runRegexp();
    end

    function callback_button_addCateg(hObject, eventdata, handles)
        % Add another row only if there are none or if the current top row is not empty. 
        if isempty(dataCategories) || (~isempty(dataCategories{1,1}) && ~strcmp(dataCategories{1,1},' '));
        dataCategories(2:(end+1),:) = dataCategories(1:end,:); % Bump the table one row    
        dataCategories(1,:) = {' ','',''}; 
        nCategories = nCategories + 1;
        update_data;
        update_gui;
        end
    end

    function callback_button_delCateg(hObject, eventdata, handles)
        selectedRow = get(h.tableCategories,'userdata');
        if ~isempty(selectedRow)
            dataCategories(selectedRow,:) = [];
            nCategories = nCategories - 1;
            update_data;
            update_gui;
        end
    end

    function callback_button_CategHelp(hObject, eventdata, handles)
        
    end

    function callback_button_runRegexp(hObject, eventdata, handles)
        regExpString = get(h.regexpEdit,'string');
        regExpString = regExpString{1};
        update_data;
        update_gui;
    end

    function callback_button_prevMatch(hObject, eventdata, handles)
        currTableLine = get_table_scroll_position(h.java.tableMarkers_scroll,length(get(h.tableMarkers,'Data')));
        idx = find(matchIndexes < currTableLine,1,'last');
        jump = matchIndexes(idx);
        if ~isempty(jump)
            set_table_scroll_position(h.java.tableMarkers_scroll,jump,nMarkers);
        end
    end

    function callback_button_nextMatch(hObject, eventdata, handles)
        currTableLine = get_table_scroll_position(h.java.tableMarkers_scroll,nMarkers);
        idx = find(matchIndexes > currTableLine,1,'first');
        jump = matchIndexes(idx);
        if ~isempty(jump)
            set_table_scroll_position(h.java.tableMarkers_scroll,jump,nMarkers);
        end
    end

    function callback_button_prevNonMatch(hObject, eventdata, handles)
        currTableLine = get_table_scroll_position(h.java.tableMarkers_scroll,nMarkers);
        idx = find(nonmatchIndexes < currTableLine,1,'last');
        jump = nonmatchIndexes(idx);
        if ~isempty(jump)
            set_table_scroll_position(h.java.tableMarkers_scroll,jump,nMarkers);
        end
    end

    function callback_button_nextNonMatch(hObject, eventdata, handles)
        currTableLine = get_table_scroll_position(h.java.tableMarkers_scroll,nMarkers);
        ii = find(nonmatchIndexes > currTableLine,1,'first');
        jump = nonmatchIndexes(ii);
        if ~isempty(jump)
            set_table_scroll_position(h.java.tableMarkers_scroll,jump,nMarkers);
        end
    end

    function callback_button_regExpHelp(hObject, eventdata, handles)
        doc('regexp');
    end

    function callback_button_deleteSelected(hObject, eventdata, handles)
        selectedRow = get(h.tableMarkers,'userdata');
        if ~isempty(selectedRow)
            delete_markers(selectedRow);
        end
    end

    function callback_button_deleteMatches(hObject, eventdata, handles)
        selected = find(regexpMatchVector);
        choice = questdlg(['Delete ' num2str(length(selected)) ' markers?'],'Delete Markers','Yes','No','No');
        if strcmp(choice,'Yes')
            delete_markers(selected);
        end
    end

    function callback_button_deleteNonMatches(hObject, eventdata, handles)
        selected = find(~regexpMatchVector);
        choice = questdlg(['Delete ' num2str(length(selected)) ' events?'],'Delete Events','Yes','No','No');
        if strcmp(choice,'Yes')
            delete_markers(selected);
        end
    end

    function callback_button_restoreMarkers(hObject, eventdata, handles)
        choice = questdlg('Restore original events?','Restore Events','Yes','No','No');
        if strcmp(choice,'Yes')
            % Initialize marker and marker category tables
            dataMarkers = cell(length(event_timestamps),5);
            dataMarkers(:,1) = num2cell(event_timestamps/srate);
            dataMarkers(:,3) = num2cell(event_values);
            nMarkers = size(dataMarkers,1);
            
            % These variables are for reporting: 
            numDeletedEvents = 0;
            originalIndexes = 1:event_values;
            deleted_event_indexes = [];
            
            update_data;
            update_gui;
        end
    end

end

%% External functions

function c = ucount( v )
% ucount: shows how many occurances there are of each unique element in an array. 
% Returns an Nx2 matrix, where N is the number of unique elements in the matrix. c(:,1) is the list
% of unique elements and c(:,2) is their corresponding number of occurrences. 
%
% Written by Edden M. Gerber, lab of Leon Y. Deouell, April 2013
% Please send bug reports and requsts to edden.gerber@gmail.com
%
[u,~,ii] = unique(v);

n = length(u);

c = zeros(n,2);
c(:,1) = u;

for i = 1:n
    c(i,2) = sum(ii == i);
end

end
