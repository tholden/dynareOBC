function [ y, GlobalVarianceShare ] = PerformCubature( UnconstrainedReturnPath, oo, dynareOBC, FirstOrderSimulation, DisableParFor, varargin )
   
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
    
    CubatureWeights = [ [ 1; zeros( NumPoints( end ) - 1, 1 ) ], CubatureWeights ];
    NumPoints = [ 1 NumPoints ];

    if nargin > 6
        p = TimedProgressBar( NumPoints( end ), 20, varargin{:} );
    else
        p = [];
    end

    yMatrix = zeros( dynareOBC.TimeToEscapeBounds * dynareOBC.NumberOfMax, size( CubatureWeights, 2 ) );

    if ~isempty( p )
        p.progress;
    end
    
    CubatureAcceleration = dynareOBC.CubatureAcceleration;
    CubatureTolerance = dynareOBC.CubatureTolerance;
    if dynareOBC.FastCubature
        CubatureTolerance = 0;
    end
    PositiveCubatureTolerance = CubatureTolerance > 0;
    MaxCubatureSerialLoop = dynareOBC.MaxCubatureSerialLoop;
    
    global MatlabPoolSize
    if DisableParFor || isempty( MatlabPoolSize )
        LocalMatlabPoolSize = 1;
    else
        LocalMatlabPoolSize = MatlabPoolSize;
    end
    CumNumPoints = cumsum( NumPoints );
    CumNumPoints( end ) = LocalMatlabPoolSize;
    iMin = find( CumNumPoints >= LocalMatlabPoolSize, 1 );
    
    if PositiveCubatureTolerance
        iMax = length( NumPoints );
    else
        iMin = 1;
        iMax = 1;
    end
    
    WarningGenerated = false;
    for i = iMin : iMax
    
        if PositiveCubatureTolerance
            if i == iMin
                jv = 1 : NumPoints( i );
            else
                jv = ( NumPoints( i - 1 ) + 1 ) : NumPoints( i );
            end
        else
            jv = 1 : NumPoints( end );
        end
        if DisableParFor || length( jv ) <= MaxCubatureSerialLoop
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

        if PositiveCubatureTolerance 
            if CubatureAcceleration
                yNew = WynnEpsilonTransformation( yMatrix( :, 1 : i ) );
            else
                yNew = yMatrix( :, i );
            end

            yError = max( abs( y - yNew ) );
            y = yNew;

            if yError < CubatureTolerance
                break
            end
        else
            if CubatureAcceleration
                y = max( 0, WynnEpsilonTransformation( yMatrix ) );
            else
                y = yMatrix( :, end );
            end
        end    
    end

    if ~isempty( p )
        p.stop;
    end
    
    if WarningGenerated
        warning( 'dynareOBC:QuadratureWarnings', 'Warnings were generated in the inner quadrature loop; try increasing TimeToEscapeBounds.' );
    end

end
