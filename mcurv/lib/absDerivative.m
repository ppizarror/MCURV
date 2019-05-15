function y = absDerivative(x)
% absDerivative: Calcula la derivada de x
if x > 0
    y = 1;
elseif x < 0
    y = -1;
else
    y = Inf;
end
end