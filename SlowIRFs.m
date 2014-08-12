function [ oo_, dynareOBC_ ] = SlowIRFs( M_, options_, oo_, dynareOBC_ )
% derived from nlma_irf.m
    
    IRFOffsets = struct;
    IRFsWithoutBounds = struct;
    Drop = dynareOBC_.SimulationDrop;
    T2 = dynareOBC_.IRFPeriods;
    T = Drop + T2;
    Replications = dynareOBC_.Replications;
    OriginalNumVarExo = dynareOBC_.OriginalNumVarExo;
    
    ShockSequence = zeros( dynareOBC_.OriginalNumVarExo, T2, Replications );
    
    RunWithBoundsWithoutShock = zeros( M_.endo_nbr, T2, Replications );
    RunWithoutBoundsWithoutShock = zeros( M_.endo_nbr, T2, Replications );
    
    RunWithBoundsWithShock = zeros( M_.endo_nbr, T2, Replications );
    RunWithoutBoundsWithShock = zeros( M_.endo_nbr, T2, Replications );
    
    IRFIndices = ( Drop + 1 ) : T;
    
    StatePreShock( Replications ) = struct; % pre-allocate
    
    PositiveVarianceShocks = setdiff( 1:dynareOBC_.OriginalNumVarExo, find( diag(M_.Sigma_e) == 0 ) );
    NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
    
    CholSigma_e = chol( M_.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );

    % temporary work around for warning in dates object.
    options_.initial_period = [];
    options_.dataset = [];
    
    OpenPool;
    
    p = TimedProgressBar( Replications, 20, 'Computing base path for average IRFs. Please wait for around ', '. Progress: ', 'Computing base path for average IRFs. Completed in ' );
    
    WarningGenerated = 0;
    parfor j = 1: Replications
        lastwarn( '' );
        WarningState = warning( 'off', 'all' );
        try
            TempShockSequence = zeros( OriginalNumVarExo, T );
            TempShockSequence( PositiveVarianceShocks, : ) = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, T );
            ShockSequence( :, :, j ) = TempShockSequence( :, IRFIndices );

            Simulation = SimulateModel( TempShockSequence, M_, options_, oo_, dynareOBC_, false );

            RunWithBoundsWithoutShock( :, :, j ) = Simulation.total_with_bounds( :, IRFIndices );
            RunWithoutBoundsWithoutShock( :, :, j ) = Simulation.total( :, IRFIndices );

            SimulationFieldNames = setdiff( fieldnames( Simulation ), 'constant' );
            for k = 1 : length( SimulationFieldNames )
                StatePreShock( j ).( SimulationFieldNames{k} ) = Simulation.( SimulationFieldNames{k} )( :, Drop );
            end
        catch Error
            warning( WarningState );
            rethrow( Error );
        end
        warning( WarningState );
        WarningGenerated = max( WarningGenerated, ~isempty( lastwarn ) );
        
        p.progress; %#ok<PFBNS>
    end
    p.stop;
    
    if WarningGenerated
        warning( 'dynareOBC:SlowIRFsWarnings', 'Critical warnings were generated in the inner loop for calculating slow IRFs; accuracy may be compromised.' );
    end

    % Compute irf, allowing correlated shocks
    SS = M_.Sigma_e + 1e-14 * eye( M_.exo_nbr );
    cs = transpose( chol( SS ) );
    
    for i = dynareOBC_.ShockSelect
        Shock = cs( M_.exo_names_orig_ord, i );

        p = TimedProgressBar( Replications, 20, [ 'Computing average IRFs for shock ' dynareOBC_.Shocks{i} '. Please wait for around ' ], '. Progress: ', [ 'Computing average IRFs for shock ' dynareOBC_.Shocks{i} '. Completed in ' ] );
    
        parfor j = 1: Replications
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                TempShockSequence = ShockSequence( :, :, j );
                TempShockSequence( :, 1 ) = TempShockSequence( :, 1 ) + Shock;

                Simulation = SimulateModel( TempShockSequence, M_, options_, oo_, dynareOBC_, false, StatePreShock( j ) );

                RunWithBoundsWithShock( :, :, j ) = Simulation.total_with_bounds;
                RunWithoutBoundsWithShock( :, :, j ) = Simulation.total;
            catch Error
                warning( WarningState );
                rethrow( Error );
            end
            warning( WarningState );
            WarningGenerated = max( WarningGenerated, ~isempty( lastwarn ) );

            p.progress; %#ok<PFBNS>
        end
        p.stop;
        
        if WarningGenerated
            warning( 'dynareOBC:SlowIRFsWarnings', 'Critical warnings were generated in the inner loop for calculating slow IRFs; accuracy may be compromised.' );
        end
        
        for j = dynareOBC_.VariableSelect
            IRFName = [ deblank( M_.endo_names( j, : ) ) '_' deblank( M_.exo_names( i, : ) ) ];
            IRFsWithoutBounds.( IRFName ) = mean( RunWithoutBoundsWithShock( j, :, : ) - RunWithoutBoundsWithoutShock( j, :, : ), 3 );
            oo_.irfs.( IRFName ) = mean( RunWithBoundsWithShock( j, :, : ) - RunWithBoundsWithoutShock( j, :, : ), 3 );
            IRFOffsets.( IRFName ) = repmat( mean( mean( RunWithBoundsWithoutShock( j, :, : ), 3 ), 2 ), size( oo_.irfs.( IRFName ) ) );
        end
    end
    dynareOBC_.IRFOffsets = IRFOffsets;
    dynareOBC_.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
