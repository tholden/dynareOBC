function [ y, GlobalVarianceShare ] = PerformCubature( UnconstrainedReturnPath, oo, dynareOBC, FirstOrderSimulation, DisableParFor, varargin )
   
    [ RootConditionalCovariance, GlobalVarianceShare ] = RetrieveConditionalCovariances( oo, dynareOBC, FirstOrderSimulation );
    d = size( RootConditionalCovariance, 2 );
    if d == 0
        return;
    end
    
    if dynareOBC.FastCubature
        NumPoints = 2 * d;
        CubatureWeights = ones( NumPoints, 1 ) * ( 1 / NumPoints );
        wTemp = sqrt( d );
        CubaturePoints = [ eye( d ) * wTemp, eye( d ) * (-wTemp) ];
    elseif dynareOBC.QuasiMonteCarloLevel > 0
        CubatureOrder = dynareOBC.QuasiMonteCarloLevel;
        CubatureOrderP1 = CubatureOrder + 1;
        if dynareOBC.HigherOrderSobolDegree > 0
            CubaturePoints = HigherOrderSobol( d, CubatureOrderP1, dynareOBC.HigherOrderSobolDegree, false );
            NumPoints = size( CubaturePoints, 2 );
            CubatureWeights = ones( NumPoints, 1 ) * ( 1 / NumPoints );
        else
            NumPoints = 2 .^ ( 1 : CubatureOrderP1 ) - 1;
            CubaturePoints = SobolSequence( d, NumPoints( end ) );
            CubatureWeights = zeros( NumPoints( end ), CubatureOrderP1 );
            for i = 1 : CubatureOrderP1
                CubatureWeights( 1:NumPoints( i ), i ) = 1 ./ NumPoints( i );
            end
        end
    else
        CubatureOrder = ceil( 0.5 * ( dynareOBC.GaussianCubatureDegree - 1 ) );
        CubatureOrderP1 = CubatureOrder + 1;
        [ CubatureWeightsCurrent, CubaturePoints, NumPointsCurrent ] = fwtpts( d, CubatureOrder );
        CubatureWeights = zeros( NumPointsCurrent, CubatureOrderP1 );
        CubatureWeights( :, end ) = CubatureWeightsCurrent;
        NumPoints = zeros( 1, CubatureOrderP1 );
        NumPoints( end ) = NumPointsCurrent;
        for i = 1 : CubatureOrder
            CubatureWeightsCurrent = fwtpts( d, i - 1 );
            NumPointsCurrent = length( CubatureWeightsCurrent );
            CubatureWeights( 1:NumPointsCurrent, i ) = CubatureWeightsCurrent;
            NumPoints( i ) = NumPointsCurrent;
        end
    end
    
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
    
    if length( NumPoints ) == 1
        CubatureAcceleration = false;
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
    
    y = [];
    
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
                yMatrixTmp = yMatrix( :, 1 : i );
                yNew = max( min( yMatrixTmp, [], 2 ), min( max( yMatrixTmp, [], 2 ), WynnEpsilonTransformation( yMatrixTmp ) ) );
            else
                yNew = yMatrix( :, i );
            end

            if isempty( y )
                yError = Inf;
            else
                yError = max( abs( y - yNew ) );
            end
            
            y = yNew;

            if yError < CubatureTolerance
                break
            end
        else
            if CubatureAcceleration
                y = max( min( yMatrix, [], 2 ), min( max( yMatrix, [], 2 ), WynnEpsilonTransformation( yMatrix ) ) );
            else
                y = yMatrix( :, end );
            end
        end
        
    end

    if ~isempty( p )
        p.stop;
    end
    
    if WarningGenerated
        warning( 'dynareOBC:CubatureWarnings', 'Warnings were generated in the inner cubature loop; try increasing TimeToEscapeBounds.' );
    end

end
