%% Cosine of two vectors
%
% Ruiqi Chen, 04/16/2020
%
% Same interface as the official DOT() function (vectorized).

function cosV = cosVal(a, b, d)
    if nargin < 3
        d = find(size(a) > 1, 1);
        if isempty(d)
            d = 1;
        end
    end
    denom = sqrt(dot(a, a, d) .* dot(b, b, d));
    cosV = dot(a, b, d) ./ denom;
    cosV(denom == 0) = 0;  % fix 0/0 (when one vector is \vec_0)
end