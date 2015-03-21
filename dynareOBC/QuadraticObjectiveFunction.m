function [ Value, Gradient, Hessian ] = QuadraticObjectiveFunction( x, f, H )
    Value = f'*x + 0.5 * x' * H * x;
    if nargout > 1
        Gradient = f + H * x;
        if nargout > 2
            Hessian = H;
        end
    end
end

