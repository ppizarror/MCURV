function y = isCellMember(a, b)
% ISARRAYMEMBER Check if b exists in cell a
if isempty(a)
    y = 0;
    return;
end
y = max(ismember(a, b)) == 1;
end