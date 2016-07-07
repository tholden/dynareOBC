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
        if isfinite( LB( i ) )
            LBTemp = LB( i ) + 2 * eps( LB( i ) );
            x( i ) = max( x( i ), LBTemp );
        else
            LBTemp = -Inf;
        end
        if isfinite( UB( i ) )
            UBTemp = UB( i ) - 2 * eps( UB( i ) );
            x( i ) = min( x( i ), UBTemp );
        else
            UBTemp = Inf;
        end
        if LBTemp > UBTemp
            x( i ) = 0.5 * ( LB( i ) + UB( i ) );
        end
    end
    
    Options = optimoptions( 'fmincon', 'Display', 'iter-detailed', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolCon', eps, 'TolFun', eps, 'TypicalX', TypicalX, 'UseParallel', true, 'ObjectiveLimit', -Inf );
    for i = 1 : 2 : length( varargin )
        Options.( varargin{ i } ) = varargin{ i + 1 };
    end
    [ x, f ] = fmincon( OptiFunction, x, [], [], [], [], LB, UB, [], Options );
end
