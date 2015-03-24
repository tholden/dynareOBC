function [ oo, dynareOBC ] = SlowIRFs( M, options, oo, dynareOBC )
% derived from nlma_irf.m
    
    IRFOffsets = struct;
    IRFsWithoutBounds = struct;
    Drop = dynareOBC.SimulationDrop;
    T2 = dynareOBC.IRFPeriods;
    T = Drop + T2;
    Replications = dynareOBC.Replications;
    OriginalNumVarExo = dynareOBC.OriginalNumVarExo;
    
    ShockSequence = zeros( dynareOBC.OriginalNumVarExo, T2, Replications );
    
    RunWithBoundsWithoutShock = zeros( M.endo_nbr, T2, Replications );
    RunWithoutBoundsWithoutShock = zeros( M.endo_nbr, T2, Replications );
    
    RunWithBoundsWithShock = zeros( M.endo_nbr, T2, Replications );
    RunWithoutBoundsWithShock = zeros( M.endo_nbr, T2, Replications );
    
    if dynareOBC.MLVSimulationMode > 0
        MLVNames = dynareOBC.MLVNames;
        MLVSelect = dynareOBC.MLVSelect;
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
    
    PositiveVarianceShocks = setdiff( 1:dynareOBC.OriginalNumVarExo, find( diag(M.Sigma_e) == 0 ) );
    NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
    
    CholSigma_e = chol( M.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );

    % temporary work around for warning in dates object.
    options.initial_period = [];
    options.dataset = [];
    
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

            Simulation = SimulateModel( TempShockSequence, M, options, oo, dynareOBC, false );

            RunWithBoundsWithoutShock( :, :, k ) = Simulation.total_with_bounds( :, IRFIndices );
            RunWithoutBoundsWithoutShock( :, :, k ) = Simulation.total( :, IRFIndices );
            
            if dynareOBC.MLVSimulationMode > 0
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
    SS = M.Sigma_e + 1e-14 * eye( M.exo_nbr );
    cs = transpose( chol( SS ) );
    
    for ShockIndex = dynareOBC.ShockSelect
        Shock = dynareOBC.ShockScale * cs( M.exo_names_orig_ord, ShockIndex );

        p = TimedProgressBar( Replications, 20, [ 'Computing average IRFs for shock ' dynareOBC.Shocks{ShockIndex} '. Please wait for around ' ], '. Progress: ', [ 'Computing average IRFs for shock ' dynareOBC.Shocks{ShockIndex} '. Completed in ' ] );
    
        parfor k = 1: Replications
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                TempShockSequence = ShockSequence( :, :, k );
                TempShockSequence( :, 1 ) = TempShockSequence( :, 1 ) + Shock;

                Simulation = SimulateModel( TempShockSequence, M, options, oo, dynareOBC, false, StatePreShock( k ) );

                RunWithBoundsWithShock( :, :, k ) = Simulation.total_with_bounds;
                RunWithoutBoundsWithShock( :, :, k ) = Simulation.total;
                
                if dynareOBC.MLVSimulationMode > 0
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
        
        for i = dynareOBC.VariableSelect
            IRFName = [ deblank( M.endo_names( i, : ) ) '_' deblank( M.exo_names( ShockIndex, : ) ) ];
            IRFsWithoutBounds.( IRFName ) = mean( RunWithoutBoundsWithShock( i, :, : ) - RunWithoutBoundsWithoutShock( i, :, : ), 3 );
            oo.irfs.( IRFName ) = mean( RunWithBoundsWithShock( i, :, : ) - RunWithBoundsWithoutShock( i, :, : ), 3 );
            IRFOffsets.( IRFName ) = repmat( mean( mean( RunWithBoundsWithoutShock( i, :, : ), 3 ), 2 ), size( oo.irfs.( IRFName ) ) );
        end
        for i = 1 : nMLVIRFs
            MLVName = MLVNames{MLVSelect(i)};
            IRFName = [ MLVName '_' deblank( M.exo_names( ShockIndex, : ) ) ];
            IRFsWithoutBounds.( IRFName ) = mean( MLVsWithoutBoundsWithShock( i, :, : ) - MLVsWithoutBoundsWithoutShock( i, :, : ), 3 );
            oo.irfs.( IRFName ) = mean( MLVsWithBoundsWithShock( i, :, : ) - MLVsWithBoundsWithoutShock( i, :, : ), 3 );
            IRFOffsets.( IRFName ) = repmat( mean( mean( MLVsWithBoundsWithoutShock( i, :, : ), 3 ), 2 ), size( oo.irfs.( IRFName ) ) );
        end
    end
    dynareOBC.IRFOffsets = IRFOffsets;
    dynareOBC.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
