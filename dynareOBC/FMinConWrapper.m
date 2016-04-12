function [ x, f ] = FMinConWrapper( OptiFunction, x, lb, ub, varargin )
    [ x, f ] = fmincon( OptiFunction, x, [], [], [], [], lb, ub, [], optimoptions( 'fmincon', 'Display', 'iter-detailed', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolCon', eps, 'TypicalX', x, 'UseParallel', true, 'ObjectiveLimit', -Inf ), varargin );
end

