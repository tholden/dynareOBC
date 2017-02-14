function [ PersistentState, StateSimulation, FullSimulation, MeasurementSimulation ] = EstimationSimulation( Parameters, PersistentState, ShockSequence, ~ )

    global M_ options_ oo_ dynareOBC_
    
    SelectAugStateVariables = PersistentState.SelectAugStateVariables;
    
    try
        FullSimulationStruct = SimulateModel( ShockSequence, false, [], true, true );
    catch Error
        rethrow( Error );
    end

    if dynareOBC_.Order == 1
        FullSimulation = FullSimulationStruct.first + FullSimulationStruct.bound_offset;
    elseif dynareOBC_.Order == 2
        FullSimulation = [ FullSimulationStruct.first; FullSimulationStruct.second + FullSimulationStruct.bound_offset ];
    else
        FullSimulation = [ FullSimulationStruct.first; FullSimulationStruct.second; FullSimulationStruct.first_sigma_2; FullSimulationStruct.third + FullSimulationStruct.bound_offset ];
    end
    
    StateSimulation = FullSimulation( SelectAugStateVariables, : );
    
    if any( ~isfinite( FullSimulation ) )
        error( 'dynareOBC:EstimationNonFiniteSimultation', 'Non-finite values were encountered during simulation.' );
    end
        
end
