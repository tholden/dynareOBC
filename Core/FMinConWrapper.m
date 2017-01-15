function [ x, f, PersistentState ] = FMinConWrapper( OptiFunction, x, LB, UB, OldPersistentState, varargin )

    TypicalAbsX = abs( x );
    SelectFiniteLB = isfinite( LB );
    SelectFiniteUB = isfinite( UB );
    TypicalAbsX( SelectFiniteLB ) = max( TypicalAbsX( SelectFiniteLB ), abs( LB( SelectFiniteLB ) ) );
    TypicalAbsX( SelectFiniteUB ) = max( TypicalAbsX( SelectFiniteUB ), abs( UB( SelectFiniteUB ) ) );
    TypicalAbsX = max( sqrt( eps ), TypicalAbsX );
    
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
    
    Options = optimoptions( 'fmincon', 'Display', 'iter-detailed', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolCon', eps, 'TolFun', eps, 'TypicalX', TypicalAbsX, 'UseParallel', false, 'ObjectiveLimit', -Inf, 'SpecifyObjectiveGradient', true );
    
    for i = 1 : 2 : length( varargin )
        Options.( varargin{ i } ) = varargin{ i + 1 };
    end
    
    global WrappedOptiFunctionPersistentState
    WrappedOptiFunctionPersistentState = [];
    
    [ x, f ] = fmincon( @( x ) WrappedOptiFunction( x, OptiFunction, OldPersistentState, TypicalAbsX ), x, [], [], [], [], LB, UB, [], Options );
    
    x = max( lb, min( ub, x ) );
    
    PersistentState = WrappedOptiFunctionPersistentState;
    WrappedOptiFunctionPersistentState = [];
    
end

function [ f, df ] = WrappedOptiFunction( x, OptiFunction, OldPersistentState, TypicalAbsX )
    global WrappedOptiFunctionPersistentState
    
    if isempty( WrappedOptiFunctionPersistentState )
        WrappedOptiFunctionPersistentState = OldPersistentState;
    end
    
    if nargout <= 1
        [ f, TmpPersistentState ] = ParallelWrapper( @( X ) OptiFunction( X, WrappedOptiFunctionPersistentState ), x, 1, Inf );
        if ~isempty( TmpPersistentState )
            WrappedOptiFunctionPersistentState = TmpPersistentState;
        end
    else
        h = sqrt( eps ) * max( abs( x ), TypicalAbsX );
        n = length( x );
        XV = repmat( x, 1, n + 1 );
        for i = 1 : n
            XV( i, i + 1 ) = XV( i, i + 1 ) + h( i );
        end
        [ RV, TmpPersistentState ] = ParallelWrapper( @( X ) OptiFunction( X, WrappedOptiFunctionPersistentState ), XV, n + 1, Inf );
        if ~isempty( TmpPersistentState )
            WrappedOptiFunctionPersistentState = TmpPersistentState;
        end
        f = RV( 1 );
        df = ( RV( 2 : end ) - f ) ./ h;
    end
end
