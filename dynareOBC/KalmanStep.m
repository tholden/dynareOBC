function [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( Measurement, EndoSelectWithControls, EndoSelect, FullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M, options, oo, dynareOBC, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock )
    NEndo = M.endo_nbr;
    NExo = dynareOBC.OriginalNumVarExo;
    Nm = length( OldMean );
    Nx = Nm + NExo;
    Observed = find( isfinite( Measurement ) );
    FiniteMeasurements = Measurement( Observed );
    No = length( Observed );
    Mx = 2 * Nx;
    Nmc = sum( EndoSelectWithControls );
    Nxc = min( Nmc, Mx ) + NExo;
    Mxc = 2 * Nxc;
    
    StateCubaturePoints = [ bsxfun( @plus, [ OldRootCovariance, -OldRootCovariance ] * sqrt( Nx ), OldMean ), repmat( OldMean, 1, 2 * NExo ); zeros( NExo, 2 * Nm ),  [ RootQ -RootQ ] * sqrt( Nx ) ];
    NewStatePoints = zeros( Nmc, Mx );
           
    % actual augmented state contains shock(+1), but we treat the shock(+1) component separately
    parfor i = 1 : Mx
        InitialFullState = GetFullStateStruct( StateCubaturePoints( 1:Nm, i ), NEndo, EndoSelect, FullMean, dynareOBC.Order, dynareOBC.Constant ); %#ok<*PFBNS>
        Simulation = SimulateModel( StateCubaturePoints( (Nm+1):end, i ), M, options, oo, dynareOBC, false, InitialFullState, true );
        if dynareOBC.Order == 1
            TempNewStatePoints = [ Simulation.first; Simulation.bound ];
        elseif dynareOBC.Order == 2
            TempNewStatePoints = [ Simulation.first; Simulation.second; Simulation.bound ];
        else
            TempNewStatePoints = [ Simulation.first; Simulation.second; Simulation.third; Simulation.first_sigma_2; Simulation.bound ];
        end
        NewStatePoints( :, i ) = TempNewStatePoints( EndoSelectWithControls ); % TempNewStatePoints( EndoSelect );
    end
    PredictedState = mean( NewStatePoints, 2 );
    RootPredictedErrorCovariance = Tria( 1 / sqrt( Mx ) * bsxfun( @minus, NewStatePoints, PredictedState ) );
    
    SubEndoSelect = EndoSelect( EndoSelectWithControls );
    if No > 0
        MeasurementCubaturePoints = [ bsxfun( @plus, [ RootPredictedErrorCovariance, -RootPredictedErrorCovariance ] * sqrt( Nxc ), PredictedState ), repmat( PredictedState, 1, 2 * NExo ); zeros( NExo, 2 * min( Nmc, Mx ) ),  [ RootQ -RootQ ] * sqrt( Nxc ) ];
        NewMeasurementPoints = zeros( No, Mxc );

        InitialFullState = GetFullStateStruct( OldMean, NEndo, EndoSelect, FullMean, dynareOBC.Order, dynareOBC.Constant );
        LagValuesWithBounds = InitialFullState.total_with_bounds( OriginalVarSelect );
        LagValuesWithBoundsLagIndices = LagValuesWithBounds( LagIndices );
        parfor i = 1 : Mxc
            Simulation = GetFullStateStruct( MeasurementCubaturePoints( 1:Nmc, i ), NEndo, EndoSelectWithControls, FullMean, dynareOBC.Order, dynareOBC.Constant );
            CurrentValuesWithBounds = Simulation.total_with_bounds( OriginalVarSelect );
            CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
            MLVs = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ], NanShock, M.params, oo.dr.ys, 1 );
            for j = 1 : No
                NewMeasurementPoints( j, i ) = MLVs.( dynareOBC.VarList{ Observed( j ) } );
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
