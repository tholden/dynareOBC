function [ PersistentState, EndoSimulation, MeasurementSimulation ] = EstimationSimulation( ~, PersistentState, InitialStates, ShockSequence, ~ )

    global M_ oo_ dynareOBC_
    
    if isempty( InitialStates )
    
        try
            FullSimulationStruct = SimulateModel( ShockSequence, false, [], true, true );
        catch Error
            rethrow( Error );
        end

        if dynareOBC_.Order == 1
            EndoSimulation = FullSimulationStruct.first + FullSimulationStruct.bound_offset;
        elseif dynareOBC_.Order == 2
            EndoSimulation = [ FullSimulationStruct.first; FullSimulationStruct.second + FullSimulationStruct.bound_offset ];
        else
            EndoSimulation = [ FullSimulationStruct.first; FullSimulationStruct.second; FullSimulationStruct.first_sigma_2; FullSimulationStruct.third + FullSimulationStruct.bound_offset ];
        end

    else
        
        Constant = dynareOBC_.Constant;
        NEndo = length( Constant );
        Order = dynareOBC_.Order;
        NEndoMult = 2 .^ ( Order - 1 );

        NAugEndo = NEndo * NEndoMult;

        StateVariableIndices = PersistentState.StateVariableIndices;
        LagIndices = PersistentState.LagIndices;
        CurrentIndices = PersistentState.CurrentIndices;
        FutureValues = PersistentState.FutureValues;
        
        NSimulationPoints = size( InitialStates, 2 );

        OldAugEndoPoints = zeros( NAugEndo, NSimulationPoints );
        OldAugEndoPoints( StateVariableIndices, : ) = InitialStates;

        EndoSimulation = zeros( NAugEndo, NSimulationPoints );

        for i = 1 : NSimulationPoints
            InitialFullState = GetFullStateStruct( OldAugEndoPoints( :, i ), Order, Constant );
            try
                Simulation = SimulateModel( ShockSequence( :, i ), false, InitialFullState, true, true );
            catch Error
                rethrow( Error );
            end

            if Order == 1
                EndoSimulation( :, i ) = Simulation.first + Simulation.bound_offset;
            elseif Order == 2
                EndoSimulation( :, i ) = [ Simulation.first; Simulation.second + Simulation.bound_offset ];
            else
                EndoSimulation( :, i ) = [ Simulation.first; Simulation.second; Simulation.first_sigma_2; Simulation.third + Simulation.bound_offset ];
            end
        end

        if nargout > 2
            LagValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( OldAugEndoPoints, NEndo, NEndoMult, NSimulationPoints ), 2 ), NEndo, NSimulationPoints ), Constant );
            LagValuesWithBoundsLagIndices = LagValuesWithBoundsBig( LagIndices, : );

            CurrentValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( EndoSimulation, NEndo, NEndoMult, NSimulationPoints ), 2 ), NEndo, NSimulationPoints ), Constant );
            CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBoundsBig( CurrentIndices, : );

            MeasurementSimulation = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; repmat( FutureValues, 1, NSimulationPoints ) ], ShockSequence, M_.params, oo_.dr.ys( 1:dynareOBC_.OriginalNumVar ) );
        else
            MeasurementSimulation = zeros( 0, NSimulationPoints );
        end
    
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
