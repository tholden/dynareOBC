function [ alpha, exitflag, ReturnPath ] = PostProcessBoundsProblem( alpha, FoundValue, exitflag, M, V, dynareOBC, IgnoreAllButConstraintViolation )

    if isempty( alpha )
        alpha = dynareOBC.ZeroVecS;
    end
    
    if any( alpha ) < 0
        alpha = max( 0, alpha );
        FoundValue = [];
    end
    
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    Tolerance = dynareOBC.Tolerance;
    
    ReturnPath = V + M * alpha;
    if any( ReturnPath < -2 * Tolerance )
        % Fudge so at least the constraint isn't violated, even if the CS condition is
        [ alpha_new, ~, ~, exitflag_new ] = lsqlin( eye( ns * Ts ), alpha, -M, V, [], [], dynareOBC.ZeroVecS, [], alpha, dynareOBC.LSqLinOptions );
        if exitflag_new > 0
            alpha = alpha_new;
        end
    
        SelectNow = 1 + ( 0:T:(T*(ns-1)) );
        SelectNows = 1 + ( 0:Ts:(Ts*(ns-1)) );
        ConstraintNow = V( SelectNow ) + M( SelectNow, : ) * alpha;
        SelectError = ( ConstraintNow < -2 * Tolerance );

        % Force the constraint not to be violated in the first period.
        if any( SelectError )
            SelectNowError = SelectNow( SelectError );
            SelectNowsError = SelectNows( SelectError );
            alpha( SelectNowsError ) = alpha( SelectNowsError ) - M( SelectNowError, SelectNowsError ) \ ConstraintNow( SelectError );
        end

        ReturnPath = V + M * alpha;
        FoundValue = [];
    end
    ReturnPathPositive = ReturnPath( 1:Ts ) > 10 * Tolerance;
    alphaAlt = alpha;
    alphaAlt( ReturnPathPositive ) = 0;
    ReturnPath = max( 0, V + M * alphaAlt );
    
    if exitflag <= 0
        FoundValue = [];
    end
    
    WarningId = '';
    WarningMessage = '';
    
    if ~IgnoreAllButConstraintViolation
        if alpha( end ) > 10 * Tolerance
            WarningId = 'dynareOBC:Inaccuracy';
            WarningMessage = sprintf( 'The final component of alpha is equal to %e > 0. This is indicative of timetoescapebounds being too small.', alpha( end ) );
            exitflag = min( exitflag, 0 );
        end

        if isempty( FoundValue )
            FoundValue = V(dynareOBC.SelectIndices)' * alpha + (1/2) * alpha' * dynareOBC.MsMatrixSymmetric * alpha;
        end

        if abs( FoundValue ) >= 10 * Tolerance
            WarningId = 'dynareOBC:NonZeroSolution';
            WarningMessage = ( 'Failed to find a zero solution to the quadratic programming problem. Try increasing timetoescapebounds.' );
            exitflag = min( exitflag, -100 );
        end
    end

    if min( V + M * alpha ) < -10 * Tolerance
        WarningId = 'dynareOBC:ViolatedConstraints';
        WarningMessage = ( 'The found solution to the quadratic programming problem violated the constraints.' );
        exitflag = min( -200, exitflag );
    end
    
    if ~isempty( WarningMessage )
        warning( WarningId, WarningMessage );
    end

end

