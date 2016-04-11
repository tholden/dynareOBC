function [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( Measurement, OldMean, OldRootCovariance, RootQ, RootMEVar, M, oo, dynareOBC, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock )
    Mean = [];
    RootCovariance = [];
    TwoNLogObservationLikelihood = NaN;
    
    NEndo = M.endo_nbr;
    NExo = dynareOBC.OriginalNumVarExo;
    Nm = size( OldMean, 2 );
    Nx = Nm + NExo;
    Observed = find( isfinite( Measurement ) );
    FiniteMeasurements = Measurement( Observed )';
    No = length( Observed );
    
    if dynareOBC.EstimationSparseCubatureDegree > 0
        CubatureOrder = ceil( 0.5 * ( dynareOBC.EstimationSparseCubatureDegree - 1 ) );
        [ Weights, pTmp, Mx ] = fwtpts( Nx, CubatureOrder );
        StateCubaturePoints = bsxfun( @plus, [ OldRootCovariance, zeros( NEndo, NExo ); zeros( NExo, Nm ), RootQ ] * pTmp, [ OldMean; zeros( NExo, 1 ) ] );
    else
        Mx = 2 * Nx;
        StateCubaturePoints = [ bsxfun( @plus, [ OldRootCovariance, -OldRootCovariance ] * sqrt( Nx ), OldMean ), repmat( OldMean, 1, 2 * NExo ); zeros( NExo, 2 * Nm ),  [ RootQ -RootQ ] * sqrt( Nx ) ];
    end
    NewStatePoints = zeros( Nm, Mx );
           
    % actual augmented state contains shock(+1), but we treat the shock(+1) component separately
    for i = 1 : Mx
        InitialFullState = GetFullStateStruct( StateCubaturePoints( 1:Nm, i ), NEndo, dynareOBC.Order, dynareOBC.Constant ); %#ok<*PFBNS>
        Simulation = SimulateModel( StateCubaturePoints( (Nm+1):end, i ), false, InitialFullState, true );
        if dynareOBC.Order == 1
            TempNewStatePoints = Simulation.first + Simulation.bound_offset;
        elseif dynareOBC.Order == 2
            TempNewStatePoints = [ Simulation.first; Simulation.second + Simulation.bound_offset ];
        else
            TempNewStatePoints = [ Simulation.first; Simulation.second; Simulation.third + Simulation.bound_offset; Simulation.first_sigma_2 ];
        end
        NewStatePoints( :, i ) = TempNewStatePoints( EndoSelectWithControls ); % TempNewStatePoints( EndoSelect );
        if any( ~isfinite( NewStatePoints( :, i ) ) )
            return
        end
    end
    
    if dynareOBC.EstimationSparseCubatureDegree > 0
        PredictedState = NewStatePoints * Weights';
        RootPredictedErrorCovariance = bsxfun( @minus, NewStatePoints, PredictedState );
        RootPredictedErrorCovariance = bsxfun( @times, RootPredictedErrorCovariance, Weights ) * RootPredictedErrorCovariance';
        [L,D] = mchol( RootPredictedErrorCovariance );
        RootPredictedErrorCovariance = L * diag( sqrt( max( 0, diag( D ) ) ) );
    else
        PredictedState = mean( NewStatePoints, 2 );
        RootPredictedErrorCovariance = Tria( 1 / sqrt( Mx ) * bsxfun( @minus, NewStatePoints, PredictedState ) );
    end
        
    Nxc = min( Nm, Mx ) + NExo;
    Mxc = 2 * Nxc;

    if No > 0
        MeasurementCubaturePoints = [ bsxfun( @plus, [ RootPredictedErrorCovariance, -RootPredictedErrorCovariance ] * sqrt( Nxc ), PredictedState ), repmat( PredictedState, 1, 2 * NExo ); zeros( NExo, 2 * min( Nm, Mx ) ),  [ RootQ -RootQ ] * sqrt( Nxc ) ];
        NewMeasurementPoints = zeros( No, Mxc );

        InitialFullState = GetFullStateStruct( OldMean, NEndo, dynareOBC.Order, dynareOBC.Constant );
        LagValuesWithBounds = InitialFullState.total_with_bounds( OriginalVarSelect );
        LagValuesWithBoundsLagIndices = LagValuesWithBounds( LagIndices );
        for i = 1 : Mxc
            Simulation = GetFullStateStruct( MeasurementCubaturePoints( :, i ), NEndo, dynareOBC.Order, dynareOBC.Constant );
            CurrentValuesWithBounds = Simulation.total_with_bounds( OriginalVarSelect );
            CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
            MLVValues = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ], NanShock, M.params, oo.dr.ys, 1 );
            NewMeasurementPoints( :, i ) = MLVValues( Observed );
            if any( ~isfinite( NewMeasurementPoints( :, i ) ) )
                return
            end
        end
        PredictedMeasurements = mean( NewMeasurementPoints, 2 );
        CurlyY = 1 / sqrt( Mxc ) * bsxfun( @minus, NewMeasurementPoints, PredictedMeasurements );
        RootPredictedInnovationCovariance = Tria( [ CurlyY, diag( RootMEVar ) ] );
        Error = RootPredictedInnovationCovariance \ ( FiniteMeasurements - PredictedMeasurements );
        TwoNLogObservationLikelihood = 2 * sum( log( diag( RootPredictedInnovationCovariance ) ) ) + Error' * Error;
        CurlyX = 1 / sqrt( Mxc ) * bsxfun( @minus, MeasurementCubaturePoints( SubEndoSelect, : ), PredictedState( SubEndoSelect ) );
        CrossCovariance = CurlyX * CurlyY';
        KalmanGain = ( CrossCovariance / RootPredictedInnovationCovariance' ) / RootPredictedInnovationCovariance;
        Mean = PredictedState( SubEndoSelect ) + KalmanGain * ( FiniteMeasurements - PredictedMeasurements );
        RootCovariance = Tria( [ CurlyX - KalmanGain * CurlyY, KalmanGain * diag( RootMEVar ) ] );
    else
        Mean = PredictedState( SubEndoSelect );
        RootCovariance = Tria( RootPredictedErrorCovariance( SubEndoSelect, : ) );
        TwoNLogObservationLikelihood = 0;
    end
end

function S = Tria( A )
    [ ~, R ] = qr( A', 0 );
    S = R';
    S = S * diag( 1 - 2 * ( diag( S ) < 0 ) );
end

function FullStateStruct = GetFullStateStruct( CurrentState, NEndo, Order, Constant )
    FullStateStruct = struct;
    FullStateStruct.first = CurrentState( 1:NEndo );
    total = FullStateStruct.first + Constant;
    if Order >= 2
        FullStateStruct.second = CurrentState( (NEndo+1):(2*NEndo) );
        total = total + FullStateStruct.second;
        if Order >= 3
            FullStateStruct.third = CurrentState( (2*NEndo+1):(3*NEndo) );
            FullStateStruct.first_sigma_2 = CurrentState( (3*NEndo+1):(4*NEndo) );
            total = total + FullStateStruct.third + FullStateStruct.first_sigma_2;
        end
    end
    FullStateStruct.bound_offset = zeros( NEndo, 1 );
    FullStateStruct.total = total;
    FullStateStruct.total_with_bounds = FullStateStruct.total;
end
