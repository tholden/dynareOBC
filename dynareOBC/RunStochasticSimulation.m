function [ oo, dynareOBC ] = RunStochasticSimulation( M, options, oo, dynareOBC )

    % derived from simult.m
    PositiveVarianceShocks = setdiff( 1:dynareOBC.OriginalNumVarExo, find( diag(M.Sigma_e) < eps ) );
    NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
    
    CholSigma_e = chol( M.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );

    if dynareOBC.SimulateOnGridPoints
        [U,D] = schur( dynareOBC.Var_z1, 'complex' );
        % assert( isreal( U ) );
        diagD = diag( D );
        % assert( isreal( diagD ) );
        RootD = sqrt( diagD );
        IDv = RootD > sqrt( eps );
        RootVar_z1 = U( :, IDv ) * diag( RootD( IDv ) );
        NumberOfPositiveVarianceVariables = size( RootVar_z1, 2 );
        QMCDraws = SobolSequence( NumberOfPositiveVarianceVariables + NumberOfPositiveVarianceShocks, SimulationLength );
        ShockSequence = zeros( max( dynareOBC.OriginalNumVarExo, nEndo ), 2 * dynareOBC.SimulationPeriods );
        Z1Offsets = RootVar_z1 * QMCDraws( 1 : NumberOfPositiveVarianceVariables, : );
        ShockSequence( 1:nEndo, 1:2:end ) = Z1Offsets( oo.dr.inv_order_var, : );
        ShockSequence( PositiveVarianceShocks, 2:2:end ) = CholSigma_e' * QMCDraws( (NumberOfPositiveVarianceVariables+1):end, : );
    else
        ShockSequence = zeros( dynareOBC.OriginalNumVarExo, dynareOBC.SimulationPeriods );
        ShockSequence( PositiveVarianceShocks, : ) = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, dynareOBC.SimulationPeriods );
    end
    
    Simulation = SimulateModel( ShockSequence, true );
    
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