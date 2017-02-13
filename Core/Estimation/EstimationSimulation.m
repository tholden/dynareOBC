function [ StateSimulation, ControlSimulation, MeasurementSimulation ] = EstimationSimulation( Parameters, PersistentState, ShockSequence )

    global M_ options_ oo_ dynareOBC_
    
    try
        StatDistSimulation = SimulateModel( ShockSequence, false, [], true, true );
    catch Error
        rethrow( Error );
    end

    if dynareOBC_.Order == 1
        StatDistPoints = StatDistSimulation.first + StatDistSimulation.bound_offset;
    elseif dynareOBC_.Order == 2
        StatDistPoints = [ StatDistSimulation.first; StatDistSimulation.second + StatDistSimulation.bound_offset ];
    else
        StatDistPoints = [ StatDistSimulation.first; StatDistSimulation.second; StatDistSimulation.first_sigma_2; StatDistSimulation.third + StatDistSimulation.bound_offset ];
    end
    
    StatDistPoints = StatDistPoints( SelectAugStateVariables, : );
    
    if any( ~isfinite( StatDistPoints ) )
        error( 'dynareOBC:EstimationNonFiniteSimultation', 'Non-finite values were encountered during simulation.' );
    end
        
end
