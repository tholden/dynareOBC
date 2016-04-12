function [ x, f ] = FMinConWrapper( OptiFunction, x, lb, ub, varargin )
    Options = optimoptions( 'fmincon', 'Display', 'iter-detailed', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolCon', eps, 'OptimalityTolerance', eps, 'TypicalX', x, 'UseParallel', true, 'ObjectiveLimit', -Inf );
    for i = 1 : 2 : length( varargin )
        Options.( varargin{ i } ) = varargin{ i + 1 };
    end
    [ x, f ] = fmincon( OptiFunction, x, [], [], [], [], lb, ub, [], Options );
end
