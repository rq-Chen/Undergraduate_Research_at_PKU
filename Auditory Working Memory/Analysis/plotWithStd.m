function ax = plotWithStd(x, y, std)

if iscolumn(x)
    x = x';
end
if size(y, 2) ~= size(x, 2)
    y = y';
end
if size(std, 2) ~= size(x, 2)
    std = std';
end
ax = plot(x, y);

hold on;
for i = 1:length(ax)
    fill([x, x(end:-1:1)], [y(i, :) - std(i, :), ...
        y(i, end:-1:1) + std(i, end:-1:1)], ...
        ax(i).Color, 'EdgeColor', 'none', 'FaceAlpha', 0.15);
end
hold off;

end