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
    
    if dynareOBC_.MLVSimulationSamples > 0
        MLVNames = dynareOBC_.MLVNames;
        MLVSelect = dynareOBC_.MLVSelect;
        nMLVIRFs = length( MLVSelect );
        MLVsWithBoundsWithoutShock = zeros( nMLVIRFs, T2, Replications );
        MLVsWithoutBoundsWithoutShock = zeros( nMLVIRFs, T2, Replications );
        MLVsWithBoundsWithShock = zeros( nMLVIRFs, T2, Replications );
        MLVsWithoutBoundsWithShock = zeros( nMLVIRFs, T2, Replications );
    else
        MLVNames = { };
        MLVSelect = [];
        nMLVIRFs = 0;
    end
    
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
    parfor k = 1: Replications
        lastwarn( '' );
        WarningState = warning( 'off', 'all' );
        try
            TempShockSequence = zeros( OriginalNumVarExo, T );
            TempShockSequence( PositiveVarianceShocks, : ) = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, T );
            ShockSequence( :, :, k ) = TempShockSequence( :, IRFIndices );

            Simulation = SimulateModel( TempShockSequence, M_, options_, oo_, dynareOBC_, false );

            RunWithBoundsWithoutShock( :, :, k ) = Simulation.total_with_bounds( :, IRFIndices );
            RunWithoutBoundsWithoutShock( :, :, k ) = Simulation.total( :, IRFIndices );
            
            if dynareOBC_.MLVSimulationSamples > 0
                for i = 1 : nMLVIRFs
                    MLVName = MLVNames{MLVSelect(i)}; %#ok<PFBNS>
                    MLVsWithBoundsWithoutShock( i, :, k ) = Simulation.MLVsWithBounds.( MLVName )( :, IRFIndices );
                    MLVsWithoutBoundsWithoutShock( i, :, k ) = Simulation.MLVsWithoutBounds.( MLVName )( :, IRFIndices );
                end
            end

            SimulationFieldNames = setdiff( fieldnames( Simulation ), { 'constant', 'MLVsWithBounds', 'MLVsWithoutBounds' } );
            for l = 1 : length( SimulationFieldNames )
                StatePreShock( k ).( SimulationFieldNames{l} ) = Simulation.( SimulationFieldNames{l} )( :, Drop );
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
    
    for ShockIndex = dynareOBC_.ShockSelect
        Shock = dynareOBC_.ShockScale * cs( M_.exo_names_orig_ord, ShockIndex );

        p = TimedProgressBar( Replications, 20, [ 'Computing average IRFs for shock ' dynareOBC_.Shocks{ShockIndex} '. Please wait for around ' ], '. Progress: ', [ 'Computing average IRFs for shock ' dynareOBC_.Shocks{ShockIndex} '. Completed in ' ] );
    
        parfor k = 1: Replications
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                TempShockSequence = ShockSequence( :, :, k );
                TempShockSequence( :, 1 ) = TempShockSequence( :, 1 ) + Shock;

                Simulation = SimulateModel( TempShockSequence, M_, options_, oo_, dynareOBC_, false, StatePreShock( k ) );

                RunWithBoundsWithShock( :, :, k ) = Simulation.total_with_bounds;
                RunWithoutBoundsWithShock( :, :, k ) = Simulation.total;
                
                if dynareOBC_.MLVSimulationSamples > 0
                    for i = 1 : nMLVIRFs
                        MLVName = MLVNames{MLVSelect(i)}; %#ok<PFBNS>
                        MLVsWithBoundsWithShock( i, :, k ) = Simulation.MLVsWithBounds.( MLVName );
                        MLVsWithoutBoundsWithShock( i, :, k ) = Simulation.MLVsWithoutBounds.( MLVName );
                    end
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
        
        for i = dynareOBC_.VariableSelect
            IRFName = [ deblank( M_.endo_names( i, : ) ) '_' deblank( M_.exo_names( ShockIndex, : ) ) ];
            IRFsWithoutBounds.( IRFName ) = mean( RunWithoutBoundsWithShock( i, :, : ) - RunWithoutBoundsWithoutShock( i, :, : ), 3 );
            oo_.irfs.( IRFName ) = mean( RunWithBoundsWithShock( i, :, : ) - RunWithBoundsWithoutShock( i, :, : ), 3 );
            IRFOffsets.( IRFName ) = repmat( mean( mean( RunWithBoundsWithoutShock( i, :, : ), 3 ), 2 ), size( oo_.irfs.( IRFName ) ) );
        end
        for i = 1 : nMLVIRFs
            MLVName = MLVNames{MLVSelect(i)};
            IRFName = [ MLVName '_' deblank( M_.exo_names( ShockIndex, : ) ) ];
            IRFsWithoutBounds.( IRFName ) = mean( MLVsWithoutBoundsWithShock( i, :, : ) - MLVsWithoutBoundsWithoutShock( i, :, : ), 3 );
            oo_.irfs.( IRFName ) = mean( MLVsWithBoundsWithShock( i, :, : ) - MLVsWithBoundsWithoutShock( i, :, : ), 3 );
            IRFOffsets.( IRFName ) = repmat( mean( mean( MLVsWithBoundsWithoutShock( i, :, : ), 3 ), 2 ), size( oo_.irfs.( IRFName ) ) );
        end
    end
    dynareOBC_.IRFOffsets = IRFOffsets;
    dynareOBC_.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
