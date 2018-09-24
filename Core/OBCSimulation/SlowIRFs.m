function [ oo, dynareOBC ] = SlowIRFs( M, oo, dynareOBC )
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
    
    SqrtmSigma_e = spsqrtm( M.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );
    
    p = TimedProgressBar( Replications, 20, 'Computing base path for average IRFs. Please wait for around ', '. Progress: ', 'Computing base path for average IRFs. Completed in ' );
    
    WarningGenerated = false;
    MLVSimulationMode = dynareOBC.MLVSimulationMode;
    parfor k = 1: Replications
        lastwarn( '' );
        WarningState = warning( 'off', 'all' );
        try
            TempShockSequence = zeros( OriginalNumVarExo, T );
            TempShockSequence( PositiveVarianceShocks, : ) = SqrtmSigma_e * randn( NumberOfPositiveVarianceShocks, T ) * ( Replications > 1 );
            ShockSequence( :, :, k ) = TempShockSequence( :, IRFIndices );

            Simulation = SimulateModel( TempShockSequence, false );

            RunWithBoundsWithoutShock( :, :, k ) = Simulation.total_with_bounds( :, IRFIndices );
            RunWithoutBoundsWithoutShock( :, :, k ) = Simulation.total( :, IRFIndices );
            
            if MLVSimulationMode > 0
                for i = 1 : nMLVIRFs
                    MLVName = MLVNames{MLVSelect(i)}; %#ok<PFBNS>
                    MLVsWithBoundsWithoutShock( i, :, k ) = Simulation.MLVsWithBounds.( MLVName )( :, IRFIndices );
                    MLVsWithoutBoundsWithoutShock( i, :, k ) = Simulation.MLVsWithoutBounds.( MLVName )( :, IRFIndices );
                end
            end

            SimulationFieldNames = fieldnames( Simulation );
            for l = 1 : length( SimulationFieldNames )
                SimulationFieldName = SimulationFieldNames{l};
                if strcmp( SimulationFieldName, 'constant' ) || strcmp( SimulationFieldName, 'MLVsWithBounds' ) || strcmp( SimulationFieldName, 'MLVsWithoutBounds' )
                    continue;
                end
                StatePreShock( k ).( SimulationFieldName ) = Simulation.( SimulationFieldName )( :, Drop );
            end
        catch Error
            warning( WarningState );
            rethrow( Error );
        end
        warning( WarningState );
        WarningGenerated = WarningGenerated | ~isempty( lastwarn );
        
        p.progress; %#ok<PFBNS>
    end
    p.stop;
    
    if WarningGenerated
        warning( 'dynareOBC:SlowIRFsWarnings', 'Critical warnings were generated in the inner loop for calculating slow IRFs; accuracy may be compromised.' );
    end

    % Compute irf, allowing correlated shocks
    SS = M.Sigma_e + 1e-14 * eye( M.exo_nbr );
    cs = spsqrtm( SS );
    
    for ShockIndex = dynareOBC.ShockSelect
        Shock = dynareOBC.ShockScale * cs( M.exo_names_orig_ord, ShockIndex );

        p = TimedProgressBar( Replications, 20, [ 'Computing average IRFs for shock ' dynareOBC.Shocks{ShockIndex} '. Please wait for around ' ], '. Progress: ', [ 'Computing average IRFs for shock ' dynareOBC.Shocks{ShockIndex} '. Completed in ' ] );
    
        parfor k = 1: Replications
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                TempShockSequence = ShockSequence( :, :, k );
                TempShockSequence( :, 1 ) = TempShockSequence( :, 1 ) + Shock;

                Simulation = SimulateModel( TempShockSequence, false, StatePreShock( k ) );

                RunWithBoundsWithShock( :, :, k ) = Simulation.total_with_bounds;
                RunWithoutBoundsWithShock( :, :, k ) = Simulation.total;
                
                if MLVSimulationMode > 0
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
        
        if dynareOBC.MedianIRFs
            for i = dynareOBC.VariableSelect
                IRFName = [ deblank( M.endo_names( i, : ) ) '_' deblank( M.exo_names( ShockIndex, : ) ) ];
                IRFsWithoutBounds.( IRFName ) = median( RunWithoutBoundsWithShock( i, :, : ) - RunWithoutBoundsWithoutShock( i, :, : ), 3 );
                oo.irfs.( IRFName ) = median( RunWithBoundsWithShock( i, :, : ) - RunWithBoundsWithoutShock( i, :, : ), 3 );
                assignin( 'base', IRFName, oo.irfs.( IRFName ).' );
                TmpRunWithBoundsWithoutShock = RunWithBoundsWithoutShock( i, :, : );
                IRFOffsets.( IRFName ) = repmat( median( TmpRunWithBoundsWithoutShock(:) ), size( oo.irfs.( IRFName ) ) );
            end
            for i = 1 : nMLVIRFs
                MLVName = MLVNames{MLVSelect(i)};
                IRFName = [ MLVName '_' deblank( M.exo_names( ShockIndex, : ) ) ];
                IRFsWithoutBounds.( IRFName ) = median( MLVsWithoutBoundsWithShock( i, :, : ) - MLVsWithoutBoundsWithoutShock( i, :, : ), 3 );
                oo.irfs.( IRFName ) = median( MLVsWithBoundsWithShock( i, :, : ) - MLVsWithBoundsWithoutShock( i, :, : ), 3 );
                assignin( 'base', IRFName, oo.irfs.( IRFName ).' );
                TmpRunWithBoundsWithoutShock = RunWithBoundsWithoutShock( i, :, : );
                IRFOffsets.( IRFName ) = repmat( median( TmpRunWithBoundsWithoutShock(:) ), size( oo.irfs.( IRFName ) ) );
            end
        else
            for i = dynareOBC.VariableSelect
                IRFName = [ deblank( M.endo_names( i, : ) ) '_' deblank( M.exo_names( ShockIndex, : ) ) ];
                IRFsWithoutBounds.( IRFName ) = mean( RunWithoutBoundsWithShock( i, :, : ) - RunWithoutBoundsWithoutShock( i, :, : ), 3 );
                oo.irfs.( IRFName ) = mean( RunWithBoundsWithShock( i, :, : ) - RunWithBoundsWithoutShock( i, :, : ), 3 );
                assignin( 'base', IRFName, oo.irfs.( IRFName ).' );
                TmpRunWithBoundsWithoutShock = RunWithBoundsWithoutShock( i, :, : );
                IRFOffsets.( IRFName ) = repmat( mean( TmpRunWithBoundsWithoutShock(:) ), size( oo.irfs.( IRFName ) ) );
            end
            for i = 1 : nMLVIRFs
                MLVName = MLVNames{MLVSelect(i)};
                IRFName = [ MLVName '_' deblank( M.exo_names( ShockIndex, : ) ) ];
                IRFsWithoutBounds.( IRFName ) = mean( MLVsWithoutBoundsWithShock( i, :, : ) - MLVsWithoutBoundsWithoutShock( i, :, : ), 3 );
                oo.irfs.( IRFName ) = mean( MLVsWithBoundsWithShock( i, :, : ) - MLVsWithBoundsWithoutShock( i, :, : ), 3 );
                assignin( 'base', IRFName, oo.irfs.( IRFName ).' );
                TmpRunWithBoundsWithoutShock = RunWithBoundsWithoutShock( i, :, : );
                IRFOffsets.( IRFName ) = repmat( mean( TmpRunWithBoundsWithoutShock(:) ), size( oo.irfs.( IRFName ) ) );
            end
        end
    end
    dynareOBC.IRFOffsets = IRFOffsets;
    dynareOBC.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
