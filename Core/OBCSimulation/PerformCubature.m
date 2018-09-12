function [ y, GlobalVarianceShare ] = PerformCubature( UnconstrainedReturnPath, oo, dynareOBC, FirstOrderSimulation, DisableParFor, varargin )
   
    [ RootConditionalCovariance, GlobalVarianceShare ] = RetrieveConditionalCovariances( oo, dynareOBC, FirstOrderSimulation );
    
    if size( RootConditionalCovariance, 2 ) == 0
        y = SolveBoundsProblem( UnconstrainedReturnPath );
        return
    end
    
    if dynareOBC.ImportanceSampling
        
        ConditionalCovariance = RootConditionalCovariance * RootConditionalCovariance.';
        ConditionalStdDev = sqrt( diag( ConditionalCovariance ) );
        
        ZiCutOff = -UnconstrainedReturnPath ./ ConditionalStdDev;
        PDFZiCutOff = normpdf( ZiCutOff );
        CDFZiCutOff = normcdf( ZiCutOff );
        PDFCDFRatioZiCutOff = PDFZiCutOff ./ CDFZiCutOff;
        
        MeanXiRel = - ConditionalStdDev .* PDFCDFRatioZiCutOff;
        MeanXi = MeanXiRel + UnconstrainedReturnPath;
        VarXi = diag( ConditionalCovariance ) .* max( 0, 1 - ZiCutOff .* PDFCDFRatioZiCutOff - PDFCDFRatioZiCutOff .* PDFCDFRatioZiCutOff );
        
        CoordinateWeights = CDFZiCutOff;
        
        NPath = numel( UnconstrainedReturnPath );
        
        SamplingMean = zeros( NPath, 1 );
        SamplingCovariance = zeros( NPath, NPath );
        SamplingMeanCurrent = zeros( NPath, 1 );
        SamplingCovarianceCurrent = zeros( NPath, NPath );
        
        for i = 1 : NPath
            if ( CDFZiCutOff( i ) == 0 ) || ( ( ConditionalCovariance( i, i ) < eps ) && ( UnconstrainedReturnPath( i ) > 0 ) )
                CoordinateWeights( i ) = 0;
                continue
            end
            % XiRel = norminv( CDFZCutOff( i ) * Ui ) * ConditionalStdDev( i );
            % Xi = XiRel + UnconstrainedReturnPath( i );
            SelectMi = [ ( 1 : ( i - 1 ) ), ( ( i + 1 ) : NPath ) ];
            XiRelScaler = ConditionalCovariance( SelectMi, i ) / max( eps, ConditionalCovariance( i, i ) );
            MeanXMi = UnconstrainedReturnPath( SelectMi ) + XiRelScaler * MeanXiRel( i );
            VarXMi = VarXi( i ) * ( XiRelScaler * XiRelScaler.' ) + ConditionalCovariance( SelectMi, SelectMi ) - ( ConditionalCovariance( SelectMi, i ) * ConditionalCovariance( SelectMi, i ).' ) / max( eps, ConditionalCovariance( i, i ) );
            CovXMiXi = XiRelScaler * VarXi( i );
            
            SamplingMeanCurrent( i ) = MeanXi( i );
            SamplingMeanCurrent( SelectMi ) = MeanXMi;
            
            SamplingCovarianceCurrent( i, i ) = VarXi( i );
            SamplingCovarianceCurrent( SelectMi, SelectMi ) = VarXMi;
            SamplingCovarianceCurrent( SelectMi, i ) = CovXMiXi;
            SamplingCovarianceCurrent( i, SelectMi ) = CovXMiXi.';
            
            SamplingCovarianceCurrent = SamplingCovarianceCurrent + SamplingMeanCurrent * SamplingMeanCurrent.';

            SamplingMean = SamplingMean + CoordinateWeights( i ) * SamplingMeanCurrent;
            SamplingCovariance = SamplingCovariance + CoordinateWeights( i ) * SamplingCovarianceCurrent;
     
        end
        
        SumCoordinateWeights = sum( CoordinateWeights );
        SamplingMean = SamplingMean / SumCoordinateWeights;
        SamplingCovariance = SamplingCovariance / SumCoordinateWeights;
        SamplingCovariance = SamplingCovariance - SamplingMean * SamplingMean.';
        
        RootConditionalCovarianceProduct = RootConditionalCovariance.' * RootConditionalCovariance;
        
        SamplingRootCovariance = ObtainRootConditionalCovariance( SamplingCovariance, 0, size( SamplingCovariance, 2 ) );
        
        StandardizedSamplingRootCovariance = RootConditionalCovarianceProduct \ ( RootConditionalCovariance.' * SamplingRootCovariance );
        
        % StandardizedSamplingRootCovariance = U * D * V'
        % StandardizedSamplingRootCovariance * StandardizedSamplingRootCovariance.' = U * D * V' * V * D * U' = U * D * D * U'
        
        [ U, D ] = svd( StandardizedSamplingRootCovariance, 'econ' );
        if isreal( U )
            diagD = diag( D );
            max_diagD = max( diagD );
            diagD( diagD < dynareOBC.CubaturePruningCutOff * max_diagD ) = 0;
            diagD( 1 : end - dynareOBC.MaxCubatureDimension ) = 0;
            IDv = diagD > sqrt( eps );
            StandardizedSamplingRootCovariance = U( :, IDv ) * diag( diagD( IDv ) );
        else
            StandardizedSamplingRootCovariance = ObtainRootConditionalCovariance( StandardizedSamplingRootCovariance * StandardizedSamplingRootCovariance, dynareOBC.CubaturePruningCutOff, dynareOBC.MaxCubatureDimension );
        end
        
        if size( StandardizedSamplingRootCovariance, 2 ) == 0
            y = SolveBoundsProblem( UnconstrainedReturnPath );
            return
        end
        
        StandardizedSamplingMean = RootConditionalCovarianceProduct \ ( RootConditionalCovariance.' * ( SamplingMean - UnconstrainedReturnPath ) );
        
        % ProjectionMatrix = RootConditionalCovarianceProduct * ( RootConditionalCovarianceProduct \ ( RootConditionalCovariance.' ) );
        % UnconstrainedReturnPath + RootConditionalCovariance * ( StandardizedSamplingMean + StandardizedSamplingRootCovariance * z ) = UnconstrainedReturnPath + ProjectionMatrix * ( SamplingMean + SamplingRootCovariance * w - UnconstrainedReturnPath )
        
        % SamplingMean = UnconstrainedReturnPath + RootConditionalCovariance * StandardizedSamplingMean;
        SamplingRootCovariance = RootConditionalCovariance * StandardizedSamplingRootCovariance;
        
        CubatureOrder = dynareOBC.ImportanceSamplingAccuracy;
        CubatureOrderP1 = CubatureOrder + 1;
        
        NumPoints = 2 .^ CubatureOrderP1 - 1;
        CubaturePoints = SobolSequence( size( StandardizedSamplingRootCovariance, 2 ), NumPoints );
        
        StandardizedPoints = bsxfun( @plus, StandardizedSamplingMean, StandardizedSamplingRootCovariance * CubaturePoints );
        Points = bsxfun( @plus, UnconstrainedReturnPath, RootConditionalCovariance * StandardizedPoints );
        
        SamplingRootCovarianceProduct = SamplingRootCovariance.' * SamplingRootCovariance;
        
        AltStandardizedRootConditionalCovariance = [ sqrt( eps ) * eye( size( SamplingRootCovarianceProduct ) ), SamplingRootCovarianceProduct \ ( SamplingRootCovariance.' * RootConditionalCovariance ) ];
        
        % AltStandardizedRootConditionalCovariance.' = Q * R
        % AltStandardizedRootConditionalCovariance * AltStandardizedRootConditionalCovariance.' = R.' * Q.' * Q * R = R.' * R
        
        [ ~, R ] = qr( AltStandardizedRootConditionalCovariance.', 0 );
        
        AltStandardizedRootConditionalCovariance = R.';
        
        AltStandardizedUnconstrainedReturnPath = SamplingRootCovarianceProduct \ ( SamplingRootCovariance.' * ( - RootConditionalCovariance * StandardizedSamplingMean ) );
                
        BadPoints = all( Points > 0 );
        
        CubaturePoints( :, BadPoints ) = [];
        Points( :, BadPoints ) = [];
        
        % Points = UnconstrainedReturnPath + RootConditionalCovariance * StandardizedSamplingMean + SamplingRootCovariance * CubaturePoints
        % SamplingRootCovarianceProduct \ SamplingRootCovariance.' * ( Points - UnconstrainedReturnPath - RootConditionalCovariance * StandardizedSamplingMean ) = SamplingRootCovarianceProduct \ SamplingRootCovariance.' * SamplingRootCovariance * CubaturePoints = CubaturePoints
        % Transformed True Mean = SamplingRootCovarianceProduct \ SamplingRootCovariance.' * ( UnconstrainedReturnPath - UnconstrainedReturnPath - RootConditionalCovariance * StandardizedSamplingMean ) = AltStandardizedUnconstrainedReturnPath
        % Transformed True RootCov = SamplingRootCovarianceProduct \ SamplingRootCovariance.' * RootConditionalCovariance = AltStandardizedRootConditionalCovariance
        % Points ~ N( UnconstrainedReturnPath, RootConditionalCovariance * RootConditionalCovariance.' )
        % CubaturePoints ~ N( AltStandardizedUnconstrainedReturnPath, AltStandardizedRootConditionalCovariance * AltStandardizedRootConditionalCovariance.' )
        
        StandardizedCubaturePoints = AltStandardizedRootConditionalCovariance \ bsxfun( @minus, CubaturePoints, AltStandardizedUnconstrainedReturnPath );
        
        LLTrue = -0.5 * ( sum( log( eig( AltStandardizedRootConditionalCovariance * AltStandardizedRootConditionalCovariance.' ) ) ) + sum( StandardizedCubaturePoints .* StandardizedCubaturePoints ) );
        LLSampling = -0.5 * sum( CubaturePoints .* CubaturePoints );
        
        CubatureWeights = exp( LLTrue - LLSampling ) / NumPoints; % min( 1, exp( LLTrue - LLSampling ) / NumPoints );
        ConstraintProb  = sum( CubatureWeights );
        
        if ConstraintProb < sqrt( eps )
            y = SolveBoundsProblem( UnconstrainedReturnPath );
            return
        end
        
        CubatureWeights = CubatureWeights / ConstraintProb;
        
        SamplingMean = Points * CubatureWeights.';
        SamplingCovariance = bsxfun( @minus, Points, SamplingMean );
        SamplingCovariance = bsxfun( @times, SamplingCovariance, sqrt( CubatureWeights ) );
        SamplingCovariance = SamplingCovariance * SamplingCovariance.';
        
        SamplingRootCovariance = ObtainRootConditionalCovariance( SamplingCovariance, 0, size( SamplingCovariance, 2 ) );
        
        StandardizedSamplingRootCovariance = RootConditionalCovarianceProduct \ ( RootConditionalCovariance.' * SamplingRootCovariance );
        
        % StandardizedSamplingRootCovariance = U * D * V'
        % StandardizedSamplingRootCovariance * StandardizedSamplingRootCovariance.' = U * D * V' * V * D * U' = U * D * D * U'
        
        [ U, D ] = svd( StandardizedSamplingRootCovariance, 'econ' );
        if isreal( U )
            diagD = diag( D );
            max_diagD = max( diagD );
            diagD( diagD < dynareOBC.CubaturePruningCutOff * max_diagD ) = 0;
            diagD( 1 : end - dynareOBC.MaxCubatureDimension ) = 0;
            IDv = diagD > sqrt( eps );
            StandardizedSamplingRootCovariance = U( :, IDv ) * diag( diagD( IDv ) );
        else
            StandardizedSamplingRootCovariance = ObtainRootConditionalCovariance( StandardizedSamplingRootCovariance * StandardizedSamplingRootCovariance, dynareOBC.CubaturePruningCutOff, dynareOBC.MaxCubatureDimension );
        end
        
        if size( StandardizedSamplingRootCovariance, 2 ) == 0
            y = SolveBoundsProblem( UnconstrainedReturnPath );
            return
        end
        
        StandardizedSamplingMean = RootConditionalCovarianceProduct \ ( RootConditionalCovariance.' * ( SamplingMean - UnconstrainedReturnPath ) );
        
        % ProjectionMatrix = RootConditionalCovarianceProduct * ( RootConditionalCovarianceProduct \ ( RootConditionalCovariance.' ) );
        % UnconstrainedReturnPath + RootConditionalCovariance * ( StandardizedSamplingMean + StandardizedSamplingRootCovariance * z ) = UnconstrainedReturnPath + ProjectionMatrix * ( SamplingMean + SamplingRootCovariance * w - UnconstrainedReturnPath )
        
        % SamplingMean = UnconstrainedReturnPath + RootConditionalCovariance * StandardizedSamplingMean;
        SamplingRootCovariance = RootConditionalCovariance * StandardizedSamplingRootCovariance;
        
    else
        SamplingMean = UnconstrainedReturnPath;
        SamplingRootCovariance = RootConditionalCovariance;
    end
    
    d = size( SamplingRootCovariance, 2 );
    if d == 0
        y = SolveBoundsProblem( UnconstrainedReturnPath );
        return
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
    
    if dynareOBC.ImportanceSampling
        StandardizedPoints = bsxfun( @plus, StandardizedSamplingMean, StandardizedSamplingRootCovariance * CubaturePoints );
        Points = bsxfun( @plus, UnconstrainedReturnPath, RootConditionalCovariance * StandardizedPoints );
        
        SamplingRootCovarianceProduct = SamplingRootCovariance.' * SamplingRootCovariance;
        
        AltStandardizedRootConditionalCovariance = [ sqrt( eps ) * eye( size( SamplingRootCovarianceProduct ) ), SamplingRootCovarianceProduct \ ( SamplingRootCovariance.' * RootConditionalCovariance ) ];
        
        % AltStandardizedRootConditionalCovariance.' = Q * R
        % AltStandardizedRootConditionalCovariance * AltStandardizedRootConditionalCovariance.' = R.' * Q.' * Q * R = R.' * R
        
        [ ~, R ] = qr( AltStandardizedRootConditionalCovariance.', 0 );
        
        AltStandardizedRootConditionalCovariance = R.';
        
        AltStandardizedUnconstrainedReturnPath = SamplingRootCovarianceProduct \ ( SamplingRootCovariance.' * ( - RootConditionalCovariance * StandardizedSamplingMean ) );
                
        % Points = UnconstrainedReturnPath + RootConditionalCovariance * StandardizedSamplingMean + SamplingRootCovariance * CubaturePoints
        % SamplingRootCovarianceProduct \ SamplingRootCovariance.' * ( Points - UnconstrainedReturnPath - RootConditionalCovariance * StandardizedSamplingMean ) = SamplingRootCovarianceProduct \ SamplingRootCovariance.' * SamplingRootCovariance * CubaturePoints = CubaturePoints
        % Transformed True Mean = SamplingRootCovarianceProduct \ SamplingRootCovariance.' * ( UnconstrainedReturnPath - UnconstrainedReturnPath - RootConditionalCovariance * StandardizedSamplingMean ) = AltStandardizedUnconstrainedReturnPath
        % Transformed True RootCov = SamplingRootCovarianceProduct \ SamplingRootCovariance.' * RootConditionalCovariance = AltStandardizedRootConditionalCovariance
        % Points ~ N( UnconstrainedReturnPath, RootConditionalCovariance * RootConditionalCovariance.' )
        % CubaturePoints ~ N( AltStandardizedUnconstrainedReturnPath, AltStandardizedRootConditionalCovariance * AltStandardizedRootConditionalCovariance.' )
        
        StandardizedCubaturePoints = AltStandardizedRootConditionalCovariance \ bsxfun( @minus, CubaturePoints, AltStandardizedUnconstrainedReturnPath );
        
        LLTrue = -0.5 * ( sum( log( eig( AltStandardizedRootConditionalCovariance * AltStandardizedRootConditionalCovariance.' ) ) ) + sum( StandardizedCubaturePoints .* StandardizedCubaturePoints ) );
        LLSampling = -0.5 * sum( CubaturePoints .* CubaturePoints );
        
        WeightAdjustment = exp( LLTrue - LLSampling ); % min( 1, exp( LLTrue - LLSampling ) );
        CubatureWeights = bsxfun( @times, CubatureWeights, WeightAdjustment(:) );
    else
        Points = bsxfun( @plus, SamplingMean, SamplingRootCovariance * CubaturePoints );
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
                    yNew = SolveBoundsProblem( Points( :, j ) );
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
                    yNew = SolveBoundsProblem( Points( :, j ) );
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
