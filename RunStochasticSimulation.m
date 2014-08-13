function [ oo_, dynareOBC_ ] = RunStochasticSimulation( M_, options_, oo_, dynareOBC_ )

    % derived from simult.m
    PositiveVarianceShocks = setdiff( 1:dynareOBC_.OriginalNumVarExo, find( diag(M_.Sigma_e) == 0 ) );
    NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
    
    ShockSequence = zeros( dynareOBC_.OriginalNumVarExo, dynareOBC_.SimulationPeriods );
    CholSigma_e = chol( M_.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );

    ShockSequence( PositiveVarianceShocks, : ) = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, dynareOBC_.SimulationPeriods );
    
    Simulation = SimulateModel( ShockSequence, M_, options_, oo_, dynareOBC_, true );
    
    oo_.exo_simul = [ ShockSequence; Simulation.shadow_shocks ]';
    oo_.endo_simul = Simulation.total_with_bounds;
    dynareOBC_.SimulationsWithoutBounds = Simulation.total;
    dynareOBC_.MLVSimulationWithBounds = Simulation.MLVsWithBounds;
    dynareOBC_.MLVSimulationWithoutBounds = Simulation.MLVsWithoutBounds;
    
    DispMoments( M_, options_, oo_, dynareOBC_ );
    
end