function [ oo, dynareOBC ] = RunStochasticSimulation( M, options, oo, dynareOBC )

    % derived from simult.m
    PositiveVarianceShocks = setdiff( 1:dynareOBC.OriginalNumVarExo, find( diag(M.Sigma_e) == 0 ) );
    NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
    
    ShockSequence = zeros( dynareOBC.OriginalNumVarExo, dynareOBC.SimulationPeriods );
    CholSigma_e = chol( M.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );

    ShockSequence( PositiveVarianceShocks, : ) = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, dynareOBC.SimulationPeriods );
    
    Simulation = SimulateModel( ShockSequence, M, options, oo, dynareOBC, true );
    
    oo.exo_simul = ShockSequence';
    oo.endo_simul = Simulation.total_with_bounds;
    dynareOBC.SimulationsWithoutBounds = Simulation.total;
	dynareOBC.Simulated_y = Simulation.bound;
    if dynareOBC.MLVSimulationMode > 0
        dynareOBC.MLVSimulationWithBounds = Simulation.MLVsWithBounds;
        dynareOBC.MLVSimulationWithoutBounds = Simulation.MLVsWithoutBounds;
    end
    
    DispMoments( M, options, oo, dynareOBC );
    
end