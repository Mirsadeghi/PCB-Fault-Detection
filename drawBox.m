%% Drawing Box
% ----------------------------
function drawBox(x, varargin)
if numel(x) == 6
    r = x(1);
    c = x(2);
    w = x(6)*x(5);
    h = x(6);
else
    r = x(1);
    c = x(2);
    w = x(3);
    h = x(4);
end

    x1 = r;
    x2 = r + w;
    y1 = c;
    y2 = c + h;

    if nargin == 1
        line([x1 x1 x2 x2 x1], [y1 y2 y2 y1 y1], 'LineWidth', 1.5);
    else
        line([x1 x1 x2 x2 x1], [y1 y2 y2 y1 y1], 'Color', varargin{1}, 'LineWidth', 1.5);
    end
end