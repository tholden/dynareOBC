function [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( Measurement, OldMean, OldRootCovariance, RootQ, MEVar, MParams, OoDrYs, dynareOBC, RequiredForMeasurementSelect, LagIndices, MeasurementLHSSelect, MeasurementRHSSelect, FutureValues, NanShock, AugStateVariables, SelectStateFromStateAndControls )
    Mean = [];
    RootCovariance = [];
    TwoNLogObservationLikelihood = NaN;
    
    NAugState1 = size( OldRootCovariance, 1 );
    NAugState2 = size( OldRootCovariance, 2 );
    NExo1 = size( RootQ, 1 );
    NExo2 = size( RootQ, 2 );
    
    PredictIntDim = NAugState2 + NExo2;
    
    if dynareOBC.EstimationPredictSparseCubatureDegree > 0
        PredictCubatureOrder = ceil( 0.5 * ( dynareOBC.EstimationPredictSparseCubatureDegree - 1 ) );
        [ PredictWeights, pTmp, PredictNumPoints ] = fwtpts( PredictIntDim, PredictCubatureOrder );
        PredictCubaturePoints = bsxfun( @plus, [ OldRootCovariance, zeros( NAugState1, NExo2 ); zeros( NExo1, NAugState2 ), RootQ ] * pTmp, [ OldMean; zeros( NExo1, 1 ) ] );
    else
        PredictNumPoints = 2 * PredictIntDim;
        PredictCubaturePoints = [ bsxfun( @plus, [ OldRootCovariance, -OldRootCovariance ] * sqrt( PredictIntDim ), OldMean ), repmat( OldMean, 1, 2 * NExo2 ); zeros( NExo1, 2 * NAugState2 ),  [ RootQ -RootQ ] * sqrt( PredictIntDim ) ];
        PredictWeights = 1 / PredictNumPoints;
    end
    
    Constant = dynareOBC.Constant;
    NEndo = length( Constant );
    NEndoMult = 2 .^ ( dynareOBC.Order - 1 );
    
    NAugEndo = NEndo * NEndoMult;
           
    AugPredictCubaturePoints = zeros( NAugEndo, PredictNumPoints );
    AugPredictCubaturePoints( AugStateVariables, : ) = PredictCubaturePoints( 1:NAugState1, : );

    Observed = find( isfinite( Measurement ) );
    FiniteMeasurements = Measurement( Observed )';
    NObs = length( Observed );
    
    if NObs > 0
        RequiredFromPredict = RequiredForMeasurementSelect;
    else
        RequiredFromPredict = AugStateVariables;
    end
    NAugRequiredFromPredict = sum( RequiredFromPredict );
    
    NRequiredFromPredict = NAugRequiredFromPredict / NEndoMult;
    
    NewStateAndControlPoints = zeros( NAugRequiredFromPredict, PredictNumPoints );

    for i = 1 : PredictNumPoints
        InitialFullState = GetFullStateStruct( AugPredictCubaturePoints( :, i ), dynareOBC.Order, Constant ); %#ok<*PFBNS>
        Simulation = SimulateModel( PredictCubaturePoints( (NAugState1+1):end, i ), false, InitialFullState, true, true );
        if dynareOBC.Order == 1
            TempNewStateAndControlPoints = Simulation.first + Simulation.bound_offset;
        elseif dynareOBC.Order == 2
            TempNewStateAndControlPoints = [ Simulation.first; Simulation.second + Simulation.bound_offset ];
        else
            TempNewStateAndControlPoints = [ Simulation.first; Simulation.second; Simulation.first_sigma_2; Simulation.third + Simulation.bound_offset ];
        end
        NewStateAndControlPoints( :, i ) = TempNewStateAndControlPoints( RequiredFromPredict );
        if any( ~isfinite( NewStateAndControlPoints( :, i ) ) )
            return
        end
    end

    EstimationStdDevThreshold = dynareOBC.EstimationStdDevThreshold;

    PredictedStateAndControl = sum( bsxfun( @times, NewStateAndControlPoints, PredictWeights ), 2 );
    DemeanedNewStateAndControlPoints = bsxfun( @minus, NewStateAndControlPoints, PredictedStateAndControl );
    PredictedErrorCovariance = bsxfun( @times, DemeanedNewStateAndControlPoints, PredictWeights ) * DemeanedNewStateAndControlPoints';
    RootPredictedErrorCovariance = ObtainEstimateRootCovariance( PredictedErrorCovariance, EstimationStdDevThreshold );
        
    if NObs > 0
        NEndo3 = size( RootPredictedErrorCovariance, 2 );
        
        UpdateIntDim = NEndo3;

        if dynareOBC.EstimationUpdateSparseCubatureDegree > 0
            UpdateCubatureOrder = ceil( 0.5 * ( dynareOBC.EstimationUpdateSparseCubatureDegree - 1 ) );
            [ UpdateWeights, pTmp, UpdateNumPoints ] = fwtpts( UpdateIntDim, UpdateCubatureOrder );
            DemeanedUpdateCubaturePoints = RootPredictedErrorCovariance * pTmp;
        else
            UpdateNumPoints = 2 * UpdateIntDim;
            DemeanedUpdateCubaturePoints = [ RootPredictedErrorCovariance, -RootPredictedErrorCovariance ] * sqrt( UpdateIntDim );
            UpdateWeights = 1 / UpdateNumPoints;
        end
        UpdateCubaturePoints = bsxfun( @plus, DemeanedUpdateCubaturePoints, PredictedStateAndControl );
        
        OldMeanBig = zeros( NAugEndo, 1 );
        OldMeanBig( AugStateVariables ) = OldMean;
        LagValuesWithBoundsBig = sum( reshape( OldMeanBig, NEndo, NEndoMult ), 2 ) + Constant;
        LagValuesWithBoundsLagIndices = LagValuesWithBoundsBig( LagIndices );
        
        CurrentValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( UpdateCubaturePoints, NRequiredFromPredict, NEndoMult, UpdateNumPoints ), 2 ), NRequiredFromPredict, UpdateNumPoints ), Constant( RequiredFromPredict( 1:NEndo ) ) );
        CurrentValuesWithBoundsCurrentIndices = NaN( length( MeasurementLHSSelect ), UpdateNumPoints );
        CurrentValuesWithBoundsCurrentIndices( MeasurementLHSSelect, : ) = CurrentValuesWithBoundsBig( MeasurementRHSSelect, : );
        MLVValues = dynareOBCTempGetMLVs( [ repmat( LagValuesWithBoundsLagIndices, 1, UpdateNumPoints ); CurrentValuesWithBoundsCurrentIndices; repmat( FutureValues, 1, UpdateNumPoints ) ], NanShock, MParams, OoDrYs, 1 );
        NewMeasurementPoints = MLVValues( Observed, : );
        if any( any( ~isfinite( NewMeasurementPoints ) ) )
            return
        end
        
        PredictedMeasurements = sum( bsxfun( @times, NewMeasurementPoints, UpdateWeights ), 2 );
        DemeanedPredictedMeasurements = bsxfun( @minus, NewMeasurementPoints, PredictedMeasurements );
        
        PredictedInnovationCovariance = bsxfun( @times, DemeanedPredictedMeasurements, UpdateWeights ) * DemeanedPredictedMeasurements' + diag( MEVar );       
        CrossCovariance = bsxfun( @times, DemeanedUpdateCubaturePoints, UpdateWeights ) * DemeanedPredictedMeasurements';
        
        KalmanGain = CrossCovariance / PredictedInnovationCovariance;
        
        Mean = PredictedStateAndControl + KalmanGain * ( FiniteMeasurements - PredictedMeasurements );
        Covariance = PredictedErrorCovariance - KalmanGain * PredictedInnovationCovariance * KalmanGain';
        
        Mean = Mean( SelectStateFromStateAndControls );
        RootCovariance = ObtainEstimateRootCovariance( Covariance( SelectStateFromStateAndControls, SelectStateFromStateAndControls ), EstimationStdDevThreshold );
        
        TwoNLogObservationLikelihood = log( det( PredictedInnovationCovariance ) ) + ( FiniteMeasurements - PredictedMeasurements )' * ( PredictedInnovationCovariance \ ( FiniteMeasurements - PredictedMeasurements ) ) + NObs * 1.8378770664093454836;
    else
        Mean = PredictedStateAndControl;
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
