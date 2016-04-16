function [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( Measurement, OldMean, OldRootCovariance, RootQ, MEVar, MParams, OoDrYs, dynareOBC, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock )
    Mean = [];
    RootCovariance = [];
    TwoNLogObservationLikelihood = NaN;
    
    NAugEndo1 = size( OldRootCovariance, 1 );
    NAugEndo2 = size( OldRootCovariance, 2 );
    NExo1 = size( RootQ, 1 );
    NExo2 = size( RootQ, 2 );
    
    PredictIntDim = NAugEndo2 + NExo2;
    
    if dynareOBC.EstimationPredictSparseCubatureDegree > 0
        PredictCubatureOrder = ceil( 0.5 * ( dynareOBC.EstimationPredictSparseCubatureDegree - 1 ) );
        [ PredictWeights, pTmp, PredictNumPoints ] = fwtpts( PredictIntDim, PredictCubatureOrder );
        PredictCubaturePoints = bsxfun( @plus, [ OldRootCovariance, zeros( NAugEndo1, NExo2 ); zeros( NExo1, NAugEndo2 ), RootQ ] * pTmp, [ OldMean; zeros( NExo1, 1 ) ] );
    else
        PredictNumPoints = 2 * PredictIntDim;
        PredictCubaturePoints = [ bsxfun( @plus, [ OldRootCovariance, -OldRootCovariance ] * sqrt( PredictIntDim ), OldMean ), repmat( OldMean, 1, 2 * NExo2 ); zeros( NExo1, 2 * NAugEndo2 ),  [ RootQ -RootQ ] * sqrt( PredictIntDim ) ];
        PredictWeights = 1 / PredictNumPoints;
    end
    
    NewStatePoints = zeros( NAugEndo1, PredictNumPoints );
    Constant = dynareOBC.Constant;
    NEndo = length( Constant );
    NEndoMult = 2 .^ ( dynareOBC.Order - 1 );
           
    for i = 1 : PredictNumPoints
        InitialFullState = GetFullStateStruct( PredictCubaturePoints( 1:NAugEndo1, i ), dynareOBC.Order, Constant ); %#ok<*PFBNS>
        Simulation = SimulateModel( PredictCubaturePoints( (NAugEndo1+1):end, i ), false, InitialFullState, true, true );
        if dynareOBC.Order == 1
            TempNewStatePoints = Simulation.first + Simulation.bound_offset;
        elseif dynareOBC.Order == 2
            TempNewStatePoints = [ Simulation.first; Simulation.second + Simulation.bound_offset ];
        else
            TempNewStatePoints = [ Simulation.first; Simulation.second; Simulation.first_sigma_2; Simulation.third + Simulation.bound_offset ];
        end
        NewStatePoints( :, i ) = TempNewStatePoints;
        if any( ~isfinite( NewStatePoints( :, i ) ) )
            return
        end
    end

    EstimationStdDevThreshold = dynareOBC.EstimationStdDevThreshold;

    PredictedState = sum( bsxfun( @times, NewStatePoints, PredictWeights ), 2 );
    DemeanedNewStatePoints = bsxfun( @minus, NewStatePoints, PredictedState );
    PredictedErrorCovariance = bsxfun( @times, DemeanedNewStatePoints, PredictWeights ) * DemeanedNewStatePoints';
    RootPredictedErrorCovariance = ObtainEstimateRootCovariance( PredictedErrorCovariance, EstimationStdDevThreshold );
        
    Observed = find( isfinite( Measurement ) );
    FiniteMeasurements = Measurement( Observed )';
    NObs = length( Observed );
    
    if NObs > 0
        NEndo3 = size( RootPredictedErrorCovariance, 2 );
        
        UpdateIntDim = NEndo3; % + NExo2;

        if dynareOBC.EstimationUpdateSparseCubatureDegree > 0
            UpdateCubatureOrder = ceil( 0.5 * ( dynareOBC.EstimationUpdateSparseCubatureDegree - 1 ) );
            [ UpdateWeights, pTmp, UpdateNumPoints ] = fwtpts( UpdateIntDim, UpdateCubatureOrder );
            DemeanedUpdateCubaturePoints = RootPredictedErrorCovariance * pTmp;
            % DemeanedUpdateCubaturePoints = [ RootPredictedErrorCovariance, zeros( NEndo1, NExo2 ); zeros( NExo1, NEndo3 ), RootQ ] * pTmp;
        else
            UpdateNumPoints = 2 * UpdateIntDim;
            DemeanedUpdateCubaturePoints = [ RootPredictedErrorCovariance, -RootPredictedErrorCovariance ] * sqrt( UpdateIntDim );
            % DemeanedUpdateCubaturePoints = [ [ RootPredictedErrorCovariance, -RootPredictedErrorCovariance ] * sqrt( UpdateIntDim ), zeros( NEndo1, 2 * NExo2 ); zeros( NExo1, 2 * NEndo3 ),  [ RootQ -RootQ ] * sqrt( UpdateIntDim ) ];
            UpdateWeights = 1 / UpdateNumPoints;
        end
        UpdateCubaturePoints = bsxfun( @plus, DemeanedUpdateCubaturePoints, PredictedState );
        % UpdateCubaturePoints = bsxfun( @plus, DemeanedUpdateCubaturePoints, [ PredictedState; zeros( NExo1, 1 ) ] );
        
        NewMeasurementPoints = zeros( NObs, UpdateNumPoints );

        LagValuesWithBoundsBig = sum( reshape( OldMean, NEndo, NEndoMult ), 2 ) + Constant;
        LagValuesWithBounds = LagValuesWithBoundsBig( OriginalVarSelect );
        LagValuesWithBoundsLagIndices = LagValuesWithBounds( LagIndices );
        for i = 1 : UpdateNumPoints
            CurrentValuesWithBoundsBig = sum( reshape( UpdateCubaturePoints( :, i ), NEndo, NEndoMult ), 2 ) + Constant;
            % CurrentValuesWithBoundsBig = sum( reshape( UpdateCubaturePoints( 1:NEndo1, i ), NEndo, NEndoMult ), 2 ) + Constant;
            CurrentValuesWithBounds = CurrentValuesWithBoundsBig( OriginalVarSelect );
            CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
            MLVValues = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ], NanShock, MParams, OoDrYs, 1 );
            % MLVValues = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ], UpdateCubaturePoints( (NEndo1+1):end, i ), MParams, OoDrYs, 1 );
            NewMeasurementPoints( :, i ) = MLVValues( Observed );
            if any( ~isfinite( NewMeasurementPoints( :, i ) ) )
                return
            end
        end
        
        PredictedMeasurements = sum( bsxfun( @times, NewMeasurementPoints, UpdateWeights ), 2 );
        DemeanedPredictedMeasurements = bsxfun( @minus, NewMeasurementPoints, PredictedMeasurements );
        
        PredictedInnovationCovariance = bsxfun( @times, DemeanedPredictedMeasurements, UpdateWeights ) * DemeanedPredictedMeasurements' + diag( MEVar );       
        CrossCovariance = bsxfun( @times, DemeanedUpdateCubaturePoints, UpdateWeights ) * DemeanedPredictedMeasurements';
        
        KalmanGain = CrossCovariance / PredictedInnovationCovariance;
        
        Mean = PredictedState + KalmanGain * ( FiniteMeasurements - PredictedMeasurements );
        Covariance = PredictedErrorCovariance - KalmanGain * PredictedInnovationCovariance * KalmanGain';
        
        RootCovariance = ObtainEstimateRootCovariance( Covariance, EstimationStdDevThreshold );
        
        TwoNLogObservationLikelihood = log( det( PredictedInnovationCovariance ) ) + ( FiniteMeasurements - PredictedMeasurements )' * ( PredictedInnovationCovariance \ ( FiniteMeasurements - PredictedMeasurements ) ) + NObs * 1.8378770664093454836;
    else
        Mean = PredictedState;
        RootCovariance = RootPredictedErrorCovariance;
        TwoNLogObservationLikelihood = 0;
    end
end

function FullStateStruct = GetFullStateStruct( CurrentState, Order, Constant )
    NEndo = length( Constant );
    FullStateStruct = struct;
    FullStateStruct.first = CurrentState( 1:NEndo );
    total = FullStateStruct.first + Constant;
    if Order >= 2
        FullStateStruct.second = CurrentState( (NEndo+1):(2*NEndo) );
        total = total + FullStateStruct.second;
        if Order >= 3
            FullStateStruct.first_sigma_2 = CurrentState( (2*NEndo+1):(3*NEndo) );
            FullStateStruct.third = CurrentState( (3*NEndo+1):(4*NEndo) );
            total = total + FullStateStruct.first_sigma_2 + FullStateStruct.third;
        end
    end
    FullStateStruct.bound_offset = zeros( NEndo, 1 );
    FullStateStruct.total = total;
    FullStateStruct.total_with_bounds = FullStateStruct.total;
end
