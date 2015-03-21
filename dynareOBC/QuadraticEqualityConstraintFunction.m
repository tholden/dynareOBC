function [ c, ceq, Gc, Gceq ] = QuadraticEqualityConstraintFunction( x, f, H )
    c = [];    
    if nargout > 1
        ceq = f'*x + 0.5 * x' * H * x;
        if nargout > 2
            Gc = [];
            if nargout > 3
                Gceq = f + H * x;
            end
        end
    end
end

