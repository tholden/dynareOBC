function [ alpha, exitflag, ReturnPath ] = PostProcessBoundsProblem( alpha, FoundValue, exitflag, M, V, dynareOBC_, IgnoreAllButConstraintViolation )

    if isempty( alpha )
        alpha = dynareOBC_.ZeroVecS;
    end
    
    if any( alpha ) < 0
        alpha = max( 0, alpha );
        FoundValue = [];
    end
    
    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
    Tolerance = dynareOBC_.Tolerance;
    
    ReturnPath = V + M * alpha;
    if any( ReturnPath < -2 * Tolerance )
        % Fudge so at least the constraint isn't violated, even if the CS condition is
        [ alpha_new, ~, ~, exitflag_new ] = lsqlin( eye( ns * Ts ), alpha, -M, V, [], [], dynareOBC_.ZeroVecS, [], alpha, dynareOBC_.LSqLinOptions );
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
            FoundValue = [];
        end

        ReturnPath = V + M * alpha;
    end
    
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
            FoundValue = V(dynareOBC_.SelectIndices)' * alpha + (1/2) * alpha' * dynareOBC_.MsMatrixSymmetric * alpha;
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

