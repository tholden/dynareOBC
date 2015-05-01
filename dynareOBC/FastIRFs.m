function [ oo, dynareOBC ] = FastIRFs( M, options, oo, dynareOBC )
% derived from nlma_irf.m
    
    IRFOffsets = struct;
    IRFsWithoutBounds = struct;
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.IRFPeriods;
    % Compute irf, allowing correlated shocks
    SS = M.Sigma_e + 1e-14 * eye( M.exo_nbr );
    cs = transpose( chol( SS ) );
    
    if dynareOBC.Global
        TM2 = T - 2;
        pM1 = ( -1 : TM2 )';
        pWeight = 0.5 * ( 1 + cos( pi * max( 0, pM1 ) / TM2 ) );
    end
    
    for i = dynareOBC.ShockSelect
        Shock = zeros( M.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
        Shock(:,1) = dynareOBC.ShockScale * cs( M.exo_names_orig_ord, i );
        
        %pruning_abounds( M, options, IRFShockSequence, T, dynareOBC.Order, 'lan_meyer-gohde', 1 );
        TempIRFStruct = ExpectedReturn( Shock, M, oo.dr, dynareOBC );
        
        TempIRFOffsets = repmat( dynareOBC.Mean, 1, T );
        
        TempIRFs = TempIRFStruct.total - TempIRFOffsets;
        
        UnconstrainedReturnPath = vec( TempIRFStruct.total( dynareOBC.VarIndices_ZeroLowerBounded, : )' );
        if dynareOBC.Global
            NewUnconstrainedReturnPath = pWeight .* vec( TempIRFStruct.total( dynareOBC.VarIndices_ZeroLowerBoundedShortRun, : )' ) + ( 1 - pWeight ) .* UnconstrainedReturnPath;
            yExtra = ( dynareOBC.MMatrix ) \ ( NewUnconstrainedReturnPath - UnconstrainedReturnPath );
            UnconstrainedReturnPath = NewUnconstrainedReturnPath;
        end

        y = SolveBoundsProblem( UnconstrainedReturnPath, dynareOBC );

        if ~dynareOBC.NoCubature
            y = PerformCubature( y, UnconstrainedReturnPath, options, oo, dynareOBC, TempIRFStruct.first, [ 'Computing required integral for fast IRFs for shock ' dynareOBC.Shocks{i} '. Please wait for around ' ], '. Progress: ', [ 'Computing required integral for fast IRFs for shock ' dynareOBC.Shocks{i} '. Completed in ' ] );
        end
        
        if dynareOBC.Global
            y = y + yExtra;
        end

        for j = dynareOBC.VariableSelect
            IRFName = [ deblank( M.endo_names( j, : ) ) '_' deblank( M.exo_names( i, : ) ) ];
            CurrentIRF = TempIRFs( j, 1:Ts );
            IRFsWithoutBounds.( IRFName ) = CurrentIRF;
            if dynareOBC.NumberOfMax > 0
                CurrentIRF = CurrentIRF + ( dynareOBC.MSubMatrices{ j }( 1:Ts, : ) * y )';
            end
            oo.irfs.( IRFName ) = CurrentIRF;
            IRFOffsets.( IRFName ) = TempIRFOffsets( j, 1:Ts );
        end
    end
    dynareOBC.IRFOffsets = IRFOffsets;
    dynareOBC.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
