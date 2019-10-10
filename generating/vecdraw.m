function vec = vecdraw (xLen, yScale)
% vecdraw: use the mouse cursor to freely draw a 1-D vector
% Usage:
% v = vecdraw         Open a figure and plot a vector using the mouse (keep
%                     left button pressed for continuous drawing). The 
%                     vector  will be returned to the output variable when  
%                     the figure is closed. 
% v = vecdraw(n)      Define the number of x-axis points (default: 100)
% v = vecdraw(n,yl)   Define the y-limits of the plot (default: [-1 1]);
% v = vecdraw(v1)     Where v1 is a vector, uses v1 as a starting vector
%
% Written by Edden Gerber, lab of Leon Y. Deouell, April 2014

if ~isscalar(xLen) && isvector(xLen)
    vec = xLen;
    xLen = length(vec);
    yScale = [min(vec) max(vec)];
else
    if nargin < 2 
        yScale = [-1 1];
    end
    if nargin < 1
        xLen = 100;
    end
    vec = zeros(xLen,1);
end

mouse_button_down = 0;
continuous_draw = 0;
last.x = 0;
last.y = 0;

h_f = figure;


set(gcf, 'WindowButtonMotionFcn', @mouseMove);
set(gcf, 'windowbuttondownfcn', @mouseDown);          
set(gcf, 'windowbuttonupfcn', @mouseUp);  

h_p = plot(1:xLen,vec);
xlim([1 xLen]);
ylim(yScale);

waitfor(h_f);

function mouseMove (object, eventdata)
    C = get (gca, 'CurrentPoint');
    x = C(1,1);
    y = C(1,2);
    if mouse_button_down
        x_ind = round(x);
        if x>xLen
            x_ind = xLen;
        elseif x<1
            x_ind = 1;
        end
        
        if continuous_draw
            % set value of vector
            vec(last.x:sign(x_ind-last.x):x_ind) = linspace(last.y,y,abs(last.x-x_ind)+1);
        else
            vec(x_ind) = y;
        end
        
        % refresh plot
        set(h_p,'ydata',vec);
        drawnow;
        
        continuous_draw = 1;
        last.x = x_ind;
        last.y = y;
    end
end
function mouseDown (object, eventdata)
    mouse_button_down = 1;
    continuous_draw = 0;
    mouseMove;
end
function mouseUp (object, eventdata)
    mouse_button_down = 0;
    continuous_draw = 0;
end


end
