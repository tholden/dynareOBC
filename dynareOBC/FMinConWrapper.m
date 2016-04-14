function [ x, f ] = FMinConWrapper( OptiFunction, x, LB, UB, varargin )
    TypicalX = abs( x );
    SelectFiniteLB = isfinite( LB );
    SelectFiniteUB = isfinite( UB );
    TypicalX( SelectFiniteLB ) = max( TypicalX( SelectFiniteLB ), abs( LB( SelectFiniteLB ) ) );
    TypicalX( SelectFiniteUB ) = max( TypicalX( SelectFiniteUB ), abs( UB( SelectFiniteUB ) ) );
    TypicalX = max( sqrt( eps ), TypicalX );
    SelectNegativeX = x < 0;
    TypicalX( SelectNegativeX ) = -TypicalX( SelectNegativeX );
    
    Options = optimoptions( 'fmincon', 'Display', 'iter-detailed', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolCon', eps, 'OptimalityTolerance', eps, 'TypicalX', TypicalX, 'UseParallel', true, 'ObjectiveLimit', -Inf );
    for i = 1 : 2 : length( varargin )
        Options.( varargin{ i } ) = varargin{ i + 1 };
    end
    [ x, f ] = fmincon( OptiFunction, x, [], [], [], [], LB, UB, [], Options );
end
