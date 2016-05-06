function [ y, GlobalVarianceShare ] = PerformCubature( y, UnconstrainedReturnPath, oo, dynareOBC, FirstOrderSimulation, DisableParFor, varargin )
   
    [ RootConditionalCovariance, GlobalVarianceShare ] = RetrieveConditionalCovariances( oo, dynareOBC, FirstOrderSimulation );
    d = size( RootConditionalCovariance, 2 );
    if d == 0
        return;
    end
    
    if dynareOBC.FastCubature
        NumPoints = 1 + 2 * d;
        CubatureWeights = ones( NumPoints, 1 ) * ( 1 / NumPoints );
        wTemp = 0.5 * sqrt( 2 * NumPoints );
        CubaturePoints = [ zeros( d, 1 ), eye( d ) * wTemp, eye( d ) * (-wTemp) ];
        CubatureOrder = 1;
    elseif dynareOBC.QuasiMonteCarloLevel > 0
        CubatureOrder = dynareOBC.QuasiMonteCarloLevel;
        NumPoints = 2 .^ ( 2 : ( 1 + CubatureOrder ) ) - 1;
        CubaturePoints = SobolSequence( d, NumPoints( end ) );
        CubatureWeights = zeros( NumPoints( end ), CubatureOrder );
        for i = 1 : CubatureOrder
            CubatureWeights( 1:NumPoints( i ), i ) = 1 ./ NumPoints( i );
        end
    else
        CubatureOrder = ceil( 0.5 * ( dynareOBC.MaxCubatureDegree - 1 ) );
        [ CubatureWeightsCurrent, CubaturePoints, NumPointsCurrent ] = fwtpts( d, CubatureOrder );
        CubatureWeights = zeros( NumPointsCurrent, CubatureOrder );
        CubatureWeights( :, end ) = CubatureWeightsCurrent;
        NumPoints = zeros( 1, CubatureOrder );
        NumPoints( end ) = NumPointsCurrent;
        for i = 1 : ( CubatureOrder - 1 )
            CubatureWeightsCurrent = fwtpts( d, i );
            NumPointsCurrent = length( CubatureWeightsCurrent );
            CubatureWeights( 1:NumPointsCurrent, i ) = CubatureWeightsCurrent;
            NumPoints( i ) = NumPointsCurrent;
        end
    end
    
    NumPoints = [ 1 NumPoints ];

    if nargin > 6
        p = TimedProgressBar( NumPoints( end ), 20, varargin{:} );
    else
        p = [];
    end

    yMatrix = y * CubatureWeights( 1, : );
    yPure = y;

    if ~isempty( p )
        p.progress;
    end
    
    CubatureSmoothing = dynareOBC.CubatureSmoothing;
    
    WarningGenerated = false;
    for i = 1 : CubatureOrder
    
        jv = ( NumPoints( i ) + 1 ) : NumPoints( i + 1 );
        if DisableParFor || length( jv ) <= 3
            for j = jv
                lastwarn( '' );
                WarningState = warning( 'off', 'all' );
                try
                    yNew = SolveBoundsProblem( UnconstrainedReturnPath + RootConditionalCovariance * CubaturePoints( :, j ) );
                    yMatrix = yMatrix + yNew * CubatureWeights( j, : );
                catch Error
                    warning( WarningState );
                    rethrow( Error );
                end
                warning( WarningState );
                WarningGenerated = WarningGenerated | ~isempty( lastwarn );
                if ~isempty( p )
                    p.progress;
                end
            end
        else
            parfor j = jv
                lastwarn( '' );
                WarningState = warning( 'off', 'all' );
                try
                    yNew = SolveBoundsProblem( UnconstrainedReturnPath + RootConditionalCovariance * CubaturePoints( :, j ) );
                    yMatrix = yMatrix + yNew * CubatureWeights( j, : );
                catch Error
                    warning( WarningState );
                    rethrow( Error );
                end
                warning( WarningState );
                WarningGenerated = WarningGenerated | ~isempty( lastwarn );
                if ~isempty( p )
                    p.progress;
                end
            end
        end
        
        yPureNew = yMatrix( :, i );
        if dynareOBC.FastCubature || ( CubatureSmoothing <= 0 ) || ( CubatureSmoothing >= 1 ) || ( dynareOBC.QuasiMonteCarloLevel > 0 )
            yNew = yPureNew;
        else
            yNew = ( 1 - CubatureSmoothing ) * yPureNew + CubatureSmoothing * yPure;
        end
        yPure = yPureNew;
        yError = max( abs( y - yNew ) );
        y = yNew;
        
        if yError < dynareOBC.CubatureTolerance
            break;
        end
    
    end

    if ~isempty( p )
        p.stop;
    end
    
    if WarningGenerated
        warning( 'dynareOBC:QuadratureWarnings', 'Warnings were generated in the inner quadrature loop; try increasing TimeToEscapeBounds.' );
    end

end
