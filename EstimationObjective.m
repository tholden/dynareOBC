function TwoNLogLikelihood = EstimationObjective( p, M_Internal, options_, oo_Internal, dynareOBC_ )
    TwoNLogLikelihood = Inf;
    [ T, N ] = size( dynareOBC_.EstimationData );
       
    M_Internal.params( dynareOBC_.EstimationParameterSelect ) = p( 1 : length( dynareOBC_.EstimationParameterSelect ) );
    RootMEVar = p( ( length( dynareOBC_.EstimationParameterSelect ) + 1 ):end );
    % temporary work around for warning in dates object.
    options_.initial_period = [];
    options_.dataset = [];
    [ Info, M_Internal, options_, oo_Internal, dynareOBC_ ] = ModelSolution( 1, M_Internal, options_, oo_Internal, dynareOBC_, false );
    if Info ~= 0
        return
    end
    
    NEndo = M_Internal.endo_nbr;
    NExo = dynareOBC_.OriginalNumVarExo;

    dr = oo_Internal.dr;
    if dynareOBC_.Order == 1
        OldMean = dynareOBC_.Mean_z( dr.inv_order_var );
        OldRootCovariance = chol( dynareOBC_.Var_z1( dr.inv_order_var, dr.inv_order_var ) + sqrt( eps ) * eye( NEndo ), 'lower' );
    else
        doubleInvOrderVar = [ dr.inv_order_var; dr.inv_order_var ];
        OldMean = dynareOBC_.Mean_z( doubleInvOrderVar );
        OldRootCovariance = chol( dynareOBC_.Var_z2( doubleInvOrderVar, doubleInvOrderVar ) + sqrt( eps ) * eye( 2 * NEndo ), 'lower' );
    end
    [ ti, tj, ts ] = find( OldMean );
    OldMean = sparse( ti, tj, ts, ( ( 2 .^ ( dynareOBC_.Order - 1 ) ) + 1 ) * NEndo, 1 );
    [ ti, tj, ts ] = find( OldRootCovariance );
    OldRootCovariance = sparse( ti, tj, ts, length( OldMean ), length( OldMean ) );
    
    RootQ = sparse( chol( M_Internal.Sigma_e( 1:NExo, 1:NExo ), 'lower' ) );

    OriginalVarSelect = false( NEndo );
    OriginalVarSelect( 1:dynareOBC_.OriginalNumVar ) = true;
    LagIndices = dynareOBC_.OriginalLeadLagIncidence( 1, : ) > 0;
    CurrentIndices = dynareOBC_.OriginalLeadLagIncidence( 2, : ) > 0;
    LeadIndices = dynareOBC_.OriginalLeadLagIncidence( 3, : ) > 0;
    FutureValues = nan( sum( LeadIndices ), 1 );
    NanShock = nan( NExo, 1 );
    
    FullMean = OldMean;
    EndoSelect = true( size( OldMean ) );
    for t = 1:dynareOBC_.EstimationFixedPointMaxIterations
        [ Mean, RootCovariance ] = KalmanStep( nan( 1, N ), EndoSelect, FullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M_Internal, options_, oo_Internal, dynareOBC_, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock );
        Error = max( max( abs( Mean - OldMean ) ), max( max( abs( RootCovariance * RootCovariance' - OldRootCovariance * OldRootCovariance' ) ) ) );
        OldMean = Mean; % 0.5 * Mean + 0.5 * OldMean;
        OldRootCovariance = RootCovariance; % 0.5 * RootCovariance + 0.5 * OldRootCovariance;
        if Error < 1e-4
            break;
        end
    end
    
    EndoSelect = diag( OldRootCovariance * OldRootCovariance' ) > sqrt( eps );
    FullMean = full( OldMean );
    OldMean = FullMean( EndoSelect );
    OldRootCovariance = OldRootCovariance( EndoSelect, EndoSelect );
    
    for t = 1:dynareOBC_.EstimationFixedPointMaxIterations
        [ Mean, RootCovariance ] = KalmanStep( nan( 1, N ), EndoSelect, FullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M_Internal, options_, oo_Internal, dynareOBC_, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock );
        Error = max( max( abs( Mean - OldMean ) ), max( max( abs( RootCovariance * RootCovariance' - OldRootCovariance * OldRootCovariance' ) ) ) );
        OldMean = Mean; % 0.5 * Mean + 0.5 * OldMean;
        OldRootCovariance = RootCovariance; % 0.5 * RootCovariance + 0.5 * OldRootCovariance;
        if Error < 1e-4
            break;
        end
    end
    
    TwoNLogLikelihood = 0;
    for t = 1:T
        [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( dynareOBC_.EstimationData( t, : ), EndoSelect, FullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M_Internal, options_, oo_Internal, dynareOBC_, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock );
        OldMean = Mean;
        OldRootCovariance = RootCovariance;
        TwoNLogLikelihood = TwoNLogLikelihood + TwoNLogObservationLikelihood;
    end
end

function [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( Measurement, EndoSelect, FullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M_Internal, options_, oo_Internal, dynareOBC_, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock )
    NEndo = M_Internal.endo_nbr;
    NExo = dynareOBC_.OriginalNumVarExo;
    Nm = length( OldMean );
    Nx = Nm + NExo;
    Observed = find( isfinite( Measurement ) );
    FiniteMeasurements = Measurement( Observed );
    No = length( Observed );
    Mx = 2 * Nx;
    
    StateCubaturePoints = [ bsxfun( @plus, [ OldRootCovariance, -OldRootCovariance ] * sqrt( Nx ), OldMean ), repmat( OldMean, 1, 2 * NExo ); zeros( NExo, 2 * Nm ),  [ RootQ -RootQ ] * sqrt( Nx ) ];
    NewStatePoints = zeros( Nm, Mx );
           
    % actual augmented state contains shock(+1), but we treat the shock(+1) component separately
    parfor i = 1 : Mx
        InitialFullState = GetFullStateStruct( StateCubaturePoints( 1:Nm, i ), NEndo, EndoSelect, FullMean, dynareOBC_.Order, dynareOBC_.Constant ); %#ok<*PFBNS>
        Simulation = SimulateModel( StateCubaturePoints( (Nm+1):end, i ), M_Internal, options_, oo_Internal, dynareOBC_, false, InitialFullState, true );
        if dynareOBC_.Order == 1
            TempNewStatePoints = [ Simulation.first; Simulation.bound ];
        elseif dynareOBC_.Order == 2
            TempNewStatePoints = [ Simulation.first; Simulation.second; Simulation.bound ];
        else
            TempNewStatePoints = [ Simulation.first; Simulation.second; Simulation.third; Simulation.first_sigma_2; Simulation.bound ];
        end
        NewStatePoints( :, i ) = TempNewStatePoints( EndoSelect );
    end
    PredictedState = mean( NewStatePoints, 2 );
    RootPredictedErrorCovariance = Tria( 1 / sqrt( Mx ) * bsxfun( @minus, NewStatePoints, PredictedState ) );
    
    if No > 0
        MeasurementCubaturePoints = [ bsxfun( @plus, [ RootPredictedErrorCovariance, -RootPredictedErrorCovariance ] * sqrt( Nx ), PredictedState ), repmat( PredictedState, 1, 2 * NExo ); zeros( NExo, 2 * Nm ),  [ RootQ -RootQ ] * sqrt( Nx ) ];
        NewMeasurementPoints = zeros( No, Mx );

        InitialFullState = GetFullStateStruct( OldMean, NEndo, EndoSelect, FullMean, dynareOBC_.Order, dynareOBC_.Constant );
        LagValuesWithBounds = InitialFullState.total_with_bounds( OriginalVarSelect );
        LagValuesWithBoundsLagIndices = LagValuesWithBounds( LagIndices );
        parfor i = 1 : Mx
            Simulation = GetFullStateStruct( MeasurementCubaturePoints( 1:Nm, i ), NEndo, EndoSelect, FullMean, dynareOBC_.Order, dynareOBC_.Constant );
            CurrentValuesWithBounds = Simulation.total_with_bounds( OriginalVarSelect );
            CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
            MLVs = dynareOBCtemp2_GetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ], NanShock, M_Internal.params, oo_Internal.dr.ys, 1 );
            for j = 1 : No
                NewMeasurementPoints( j, i ) = MLVs.( dynareOBC_.VarList{ Observed( j ) } );
            end
        end
        PredictedMeasurements = mean( NewMeasurementPoints, 2 );
        CurlyY = 1 / sqrt( Mx ) * bsxfun( @minus, NewMeasurementPoints, PredictedMeasurements );
        RootPredictedInnovationCovariance = Tria( [ CurlyY, diag( RootMEVar ) ] );
        Error = RootPredictedInnovationCovariance \ ( FiniteMeasurements - PredictedMeasurements );
        TwoNLogObservationLikelihood = 2 * sum( log( diag( RootPredictedInnovationCovariance ) ) ) + Error' * Error;
        CurlyX = 1 / sqrt( Mx ) * bsxfun( @minus, MeasurementCubaturePoints( 1:Nm, : ), PredictedState );
        CrossCovariance = CurlyX * CurlyY';
        KalmanGain = ( CrossCovariance / RootPredictedInnovationCovariance' ) / RootPredictedInnovationCovariance;
        Mean = PredictedState + KalmanGain * ( FiniteMeasurements - PredictedMeasurements );
        RootCovariance = Tria( [ CurlyX - KalmanGain * CurlyY, KalmanGain * diag( RootMEVar ) ] );
    else
        Mean = PredictedState;
        RootCovariance = RootPredictedErrorCovariance;
        TwoNLogObservationLikelihood = 0;
    end
end

function S = Tria( A )
    [ ~, R ] = qr( A', 0 );
    S = R';
    S = S * diag( 1 - 2 * ( diag( S ) < 0 ) );
end

function FullStateStruct = GetFullStateStruct( PartialState, NEndo, EndoSelect, FullMean, Order, Constant )
    CurrentState = FullMean;
    CurrentState( EndoSelect ) = PartialState;
    FullStateStruct = struct;
    FullStateStruct.first = CurrentState( 1:NEndo );
    FullStateStruct.total = FullStateStruct.first + Constant;
    if Order >= 2
        FullStateStruct.second = CurrentState( (NEndo+1):(2*NEndo) );
        FullStateStruct.total = FullStateStruct.second + FullStateStruct.second;
        if Order >= 3
            FullStateStruct.third = CurrentState( (2*NEndo+1):(3*NEndo) );
            FullStateStruct.first_sigma_2 = CurrentState( (3*NEndo+1):(4*NEndo) );
            FullStateStruct.total = FullStateStruct.total + FullStateStruct.third + FullStateStruct.first_sigma_2;
            FullStateStruct.bound = CurrentState( (4*NEndo+1):end );
        else
            FullStateStruct.bound = CurrentState( (2*NEndo+1):end );
        end
    else
        FullStateStruct.bound = CurrentState( (NEndo+1):end );
    end
    FullStateStruct.total_with_bounds = FullStateStruct.total + FullStateStruct.bound;
end

