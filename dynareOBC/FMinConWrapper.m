function [ x, f ] = FMinConWrapper( OptiFunction, x, LB, UB, varargin )
    TypicalX = abs( x );
    SelectFiniteLB = isfinite( LB );
    SelectFiniteUB = isfinite( UB );
    TypicalX( SelectFiniteLB ) = max( TypicalX( SelectFiniteLB ), abs( LB( SelectFiniteLB ) ) );
    TypicalX( SelectFiniteUB ) = max( TypicalX( SelectFiniteUB ), abs( UB( SelectFiniteUB ) ) );
    TypicalX = max( sqrt( eps ), TypicalX );
    SelectNegativeX = x < 0;
    TypicalX( SelectNegativeX ) = -TypicalX( SelectNegativeX );
    
    for i = 1 : length( x )
        if isfinite( lb( i ) )
            lbTemp = lb( i ) + 2 * eps( lb( i ) );
            x( i ) = max( x( i ), lbTemp );
        else
            lbTemp = -Inf;
        end
        if isfinite( ub( i ) )
            ubTemp = ub( i ) - 2 * eps( ub( i ) );
            x( i ) = min( x( i ), ubTemp );
        else
            ubTemp = Inf;
        end
        if lbTemp > ubTemp
            x( i ) = 0.5 * ( lb( i ) + ub( i ) );
        end
    end
    
    Options = optimoptions( 'fmincon', 'Display', 'iter-detailed', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolCon', eps, 'OptimalityTolerance', eps, 'TypicalX', TypicalX, 'UseParallel', true, 'ObjectiveLimit', -Inf );
    for i = 1 : 2 : length( varargin )
        Options.( varargin{ i } ) = varargin{ i + 1 };
    end
    [ x, f ] = fmincon( OptiFunction, x, [], [], [], [], LB, UB, [], Options );
end
