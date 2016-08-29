function [ TwoNLogObservationLikelihood, UpdatedX, RootUpdatedXVariance, InvRootUpdatedXVariance, UpdatedW, RootUpdatedWVariance, SmootherGain, PredictedX, RootPredictedXVariance ] = ...
    KalmanStep( Measurement, OldX, RootOldXVariance, InvRootOldXVariance, RootOldWVariance, RootQ, MEVar, TDoF, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables, Smoothing )

    TwoNLogObservationLikelihood = NaN;
    UpdatedX = [];
    RootUpdatedXVariance = [];
    InvRootUpdatedXVariance = [];
    UpdatedW = [];
    RootUpdatedWVariance = [];
    SmootherGain = [];
    PredictedX = [];
    RootPredictedXVariance = [];
    
    NAugState1 = size( RootOldXVariance, 1 );
    NAugState2 = size( RootOldXVariance, 2 );
    NExo1 = size( RootQ, 1 );
    NExo2 = size( RootQ, 2 );
    
    IntDim = NAugState2 + NExo2;
    
    if dynareOBC.FilterCubatureDegree > 0
        CubatureOrder = ceil( 0.5 * ( dynareOBC.FilterCubatureDegree - 1 ) );
        [ CubatureWeights, pTmp, NCubaturePoints ] = fwtpts( IntDim, CubatureOrder );
        CubaturePoints = bsxfun( @plus, [ RootOldXVariance, zeros( NAugState1, NExo2 ); zeros( NExo1, NAugState2 ), RootQ ] * pTmp, [ OldX; zeros( NExo1, 1 ) ] );
    else
        NCubaturePoints = 2 * IntDim + 1;
        wTemp = 0.5 * sqrt( 2 * NCubaturePoints );
        CubaturePoints = [ OldX, bsxfun( @plus, [ RootOldXVariance, -RootOldXVariance ] * wTemp, OldX ), repmat( OldX, 1, 2 * NExo2 ); zeros( NExo1, 1 + 2 * NAugState2 ),  [ RootQ -RootQ ] * wTemp ];
        CubatureWeights = 1 / NCubaturePoints;
    end
    
    Constant = dynareOBC.Constant;
    NEndo = length( Constant );
    NEndoMult = 2 .^ ( dynareOBC.Order - 1 );
    
    NAugEndo = NEndo * NEndoMult;

    StatePoints = CubaturePoints( 1:NAugState1, : );
    ExoPoints = CubaturePoints( (NAugState1+1):end, : );

    OldAugEndoPoints = zeros( NAugEndo, NCubaturePoints );
    OldAugEndoPoints( SelectAugStateVariables, : ) = StatePoints;
    
    Observed = find( isfinite( Measurement ) );
    FiniteMeasurements = Measurement( Observed )';
    NObs = length( Observed );
       
    NewAugEndoPoints = zeros( NAugEndo, NCubaturePoints );
    
    for i = 1 : NCubaturePoints
        InitialFullState = GetFullStateStruct( OldAugEndoPoints( :, i ), dynareOBC.Order, Constant ); %#ok<*PFBNS>
        try
            Simulation = SimulateModel( ExoPoints( :, i ), false, InitialFullState, true, true );
        catch
            return
        end
        
        if dynareOBC.Order == 1
            NewAugEndoPoints( :, i ) = Simulation.first + Simulation.bound_offset;
        elseif dynareOBC.Order == 2
            NewAugEndoPoints( :, i ) = [ Simulation.first; Simulation.second + Simulation.bound_offset ];
        else
            NewAugEndoPoints( :, i ) = [ Simulation.first; Simulation.second; Simulation.first_sigma_2; Simulation.third + Simulation.bound_offset ];
        end
        if any( ~isfinite( NewAugEndoPoints( :, i ) ) )
            return
        end
    end
    
    if NObs > 0
        LagValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( OldAugEndoPoints, NEndo, NEndoMult, NCubaturePoints ), 2 ), NEndo, NCubaturePoints ), Constant );
        LagValuesWithBoundsLagIndices = LagValuesWithBoundsBig( LagIndices, : );
        
        CurrentValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( NewAugEndoPoints, NEndo, NEndoMult, NCubaturePoints ), 2 ), NEndo, NCubaturePoints ), Constant );
        CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBoundsBig( CurrentIndices, : );
        
        MLVValues = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; repmat( FutureValues, 1, NCubaturePoints ) ], ExoPoints, MParams, OoDrYs );
        NewMeasurementPoints = MLVValues( Observed, : );
        if any( any( ~isfinite( NewMeasurementPoints ) ) )
            return
        end
    else
        NewMeasurementPoints = zeros( 0, NCubaturePoints );
    end

    StdDevThreshold = dynareOBC.StdDevThreshold;

    WM = [ NewAugEndoPoints; ExoPoints; zeros( NObs, NCubaturePoints ); NewMeasurementPoints ];
    
    NWM = size( WM, 1 );
    
    PredictedWM = sum( bsxfun( @times, WM, CubatureWeights ), 2 );
    DemeanedWM = bsxfun( @minus, WM, PredictedWM );
    WeightedDemeanedWM = bsxfun( @times, DemeanedWM, CubatureWeights );
    
    PredictedWMVariance = zeros( NWM, NWM );
    ZetaBlock = ( NWM - 2 * NObs + 1 ) : NWM;
    diagMEVar = diag( MEVar );
    PredictedWMVariance( ZetaBlock, ZetaBlock ) = [ diagMEVar, diagMEVar; diagMEVar, diagMEVar ];
    
    PredictedWMVariance = PredictedWMVariance + DemeanedWM' * WeightedDemeanedWM;
    PredictedWMVariance = 0.5 * ( PredictedWMVariance + PredictedWMVariance' );
    
    if Smoothing
        CovOldNewX = StatePoints' * WeightedDemeanedWM( SelectAugStateVariables, : ); % C_{t|t-1} in the paper
    end
    
    WBlock = 1 : ( NAugEndo + NExo + NObs );
    PredictedW = PredictedWM( WBlock );                                           % w_{t|t-1} in the paper
    PredictedWVariance = PredictedWMVariance( WBlock, WBlock );                   % V_{t|t-1} in the paper
    
    MBlock = ( NWM - NObs + 1 ) : NWM;
    PredictedM = PredictedWM( MBlock );                                           % m_{t|t-1} in the paper
    PredictedMVariance = PredictedWMVariance( MBlock, MBlock );                   % Q_{t|t-1} in the paper
    PredictedWMCovariance = PredictedWMVariance( WBlock, MBlock );                % R_{t|t-1} in the paper
    
    if dynareOBC.NoSkewLikelihood
        LocationM = PredictedM;
    else
        LocationM = WM( MBlock, 1 );
    end
    
    if NObs > 0
    
        [ ~, InvRootPredictedMVariance, LogDetPredictedMVariance ] = ObtainEstimateRootCovariance( PredictedMVariance, 0 );
        ScaledPredictedWMCovariance = PredictedWMCovariance * InvRootPredictedMVariance';
        ScaledResiduals = InvRootPredictedMVariance * ( FiniteMeasurements - PredictedM );

        UpdatedW = PredictedW + ScaledPredictedWMCovariance * ScaledResiduals;                              % w_{t|t} in the paper
        UpdatedWVariance = PredictedWVariance - ScaledPredictedWMCovariance * ScaledPredictedWMCovariance'; % V_{t|t} in the paper

        UpdatedX = UpdatedW( SelectAugStateVariables );                                                     % x_{t|t} in the paper
        UpdatedXVariance = UpdatedWVariance( SelectAugStateVariables, SelectAugStateVariables );            % P_{t|t} in the paper
    
        TwoNLogObservationLikelihood = LogDetPredictedMVariance + ScaledResiduals' * ScaledResiduals + NObs * 1.8378770664093454836;

    else
        
        UpdatedW = PredictedW;
        UpdatedWVariance = PredictedWVariance;

        UpdatedX = PredictedW( SelectAugStateVariables );
        UpdatedXVariance = PredictedWVariance( SelectAugStateVariables, SelectAugStateVariables );
        
        TwoNLogObservationLikelihood = 0;
        
    end
    
    
    if Smoothing
        [ RootUpdatedXVariance, InvRootUpdatedXVariance ] = ObtainEstimateRootCovariance( UpdatedXVariance, StdDevThreshold );
        RootUpdatedWVariance = ObtainEstimateRootCovariance( UpdatedWVariance, 0 );
        SmootherGain = ( RootOldWVariance * RootOldWVariance( 1:NAugState1, : )' ) * ( InvRootOldXVariance' * InvRootOldXVariance ) * CovOldNewX * ( InvRootUpdatedXVariance' * InvRootUpdatedXVariance ); % B_{t|t-1} * S_{t|t-1}^- in the paper
        PredictedX = PredictedW( SelectAugStateVariables );
        RootPredictedXVariance = ObtainEstimateRootCovariance( PredictedWVariance( SelectAugStateVariables, SelectAugStateVariables ), 0 );
    else
        RootUpdatedXVariance = ObtainEstimateRootCovariance( UpdatedXVariance, StdDevThreshold );
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
