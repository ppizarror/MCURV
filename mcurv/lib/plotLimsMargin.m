function x = plotLimsMargin(r)
% plotLimsMargin: Setea el margen del grafico en una proporcion
x = get(gca, 'xlim');
ux = abs(x(2) - x(1)) * r;
x = get(gca, 'ylim');
uy = abs(x(2) - x(1)) * r;

u = min(ux, uy);

x = get(gca, 'xlim');
if x(1) > 0
    x(1) = x(1) + u;
else
    x(1) = x(1) - u;
end
if x(2) > 0
    x(2) = x(2) - u;
else
    x(2) = x(2) + u;
end
xlim(x);

x = get(gca, 'ylim');
if x(1) > 0
    x(1) = x(1) + u;
else
    x(1) = x(1) - u;
end
if x(2) > 0
    x(2) = x(2) - u;
else
    x(2) = x(2) + u;
end
ylim(x);

end