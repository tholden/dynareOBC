function alpha = PerformCubature( alpha, V, ReturnPath, options_, oo_, dynareOBC_, FirstOrderSimulation, varargin )

    if dynareOBC_.MaxCubatureDimension == 0 || ( ( ~dynareOBC_.AvoidNegativeCubatureWeights ) && dynareOBC_.CubatureDegree <= 1 )
        return;
    end
    
    RootConditionalCovariance = RetrieveConditionalCovariances( options_, oo_, dynareOBC_, FirstOrderSimulation );
    d = size( RootConditionalCovariance, 2 );
    if d == 0
        return;
    end
    
    if dynareOBC_.AvoidNegativeCubatureWeights
        NumPoints = 1 + 2 * d;
        CubatureWeights = ones( NumPoints, 1 ) * ( 1 / NumPoints );
        wTemp = 0.5 * sqrt( 2 * NumPoints );
        CubaturePoints = [ zeros( d, 1 ), eye( d ) * wTemp, eye( d ) * (-wTemp) ];
    else
        [ CubatureWeights, CubaturePoints, NumPoints ] = fwtpts( d, ceil( 0.5 * ( dynareOBC_.CubatureDegree - 1 ) ) );
    end
    CubatureWeights = CubatureWeights / sum( CubatureWeights );

    alpha = CubatureWeights( 1 ) * alpha;
    ReturnPath = CubatureWeights( 1 ) * ReturnPath;

    if nargin > 7
        p = TimedProgressBar( NumPoints, 20, varargin{:} );
        p.progress;
    else
        p = [];
    end

    exitflag = Inf;
    
    OpenPool;
    parfor j = 2 : NumPoints
        WarningState = warning( 'off', 'all' );
        try
            [ alpha_new, exitflag_new, ReturnPath_new ] = SolveBoundsProblem( V + RootConditionalCovariance * CubaturePoints( :, j ), dynareOBC_ );
            exitflag = min( exitflag, exitflag_new );
            alpha = alpha + CubatureWeights( j ) * alpha_new;
            ReturnPath = ReturnPath + CubatureWeights( j ) * ReturnPath_new;
        catch Error
            warning( WarningState );
            rethrow( Error );
        end
        warning( WarningState );
        if ~isempty( p )
            p.progress;
        end
    end

    if ~isempty( p )
        p.stop;
    end
    
    M = dynareOBC_.MMatrix;
    
    [ alpha, ~, ~, exitflag_new ] = lsqlin( M, ReturnPath - V, -M, V, [], [], [], [], alpha, dynareOBC_.LSqLinOptions );
    exitflag = min( exitflag, exitflag_new );
%     figure;
%     hold on;
%     plot( ReturnPath );
%     plot( V + M * alpha );
    
    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
    Tolerance = dynareOBC_.Tolerance;
    
    SelectNow = 1 + ( 0:T:(T*(ns-1)) );
    SelectNows = 1 + ( 0:Ts:(Ts*(ns-1)) );
    ConstraintNow = V( SelectNow ) + M( SelectNow, : ) * alpha;
    SelectError = ( ConstraintNow < -2 * Tolerance );

    % Force the constraint not to be violated in the first period.
    if any( SelectError )
        SelectNowError = SelectNow( SelectError );
        SelectNowsError = SelectNows( SelectError );
        alpha( SelectNowsError ) = alpha( SelectNowsError ) - M( SelectNowError, SelectNowsError ) \ ConstraintNow( SelectError );
        exitflag = -1;
    end
%     plot( V + M * alpha );
%     hold off;
    
    if exitflag < 0
        warning( 'dynareOBC:QuadratureWarnings', 'Critical warnings were generated in the inner quadrature loop; accuracy may be compromised.' );
    end

end

