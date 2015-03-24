function [ oo, dynareOBC_ ] = FastIRFs( M, options, oo, dynareOBC_ )
% derived from nlma_irf.m
    
    IRFOffsets = struct;
    IRFsWithoutBounds = struct;
    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.IRFPeriods;
    % Compute irf, allowing correlated shocks
    SS = M.Sigma_e + 1e-14 * eye( M.exo_nbr );
    cs = transpose( chol( SS ) );
    
    for i = dynareOBC_.ShockSelect
        Shock = zeros( M.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
        Shock(:,1) = dynareOBC_.ShockScale * cs( M.exo_names_orig_ord, i );
        
        %pruning_abounds( M, options, IRFShockSequence, T, dynareOBC.Order, 'lan_meyer-gohde', 1 );
        TempIRFStruct = ExpectedReturn( Shock, M, oo.dr, dynareOBC_ );
        
        TempIRFOffsets = repmat( dynareOBC_.Mean, 1, T );
        
        TempIRFs = TempIRFStruct.total - TempIRFOffsets;
        
        ZeroLowerBoundedReturnPath = vec( TempIRFStruct.total( dynareOBC_.VarIndices_ZeroLowerBounded, : )' );
        
        [ alpha, ~, ConstrainedReturnPath ] = SolveBoundsProblem( ZeroLowerBoundedReturnPath, dynareOBC_ );
        if ~dynareOBC_.NoCubature
            alpha = PerformCubature( alpha, ZeroLowerBoundedReturnPath, ConstrainedReturnPath, options, oo, dynareOBC_, TempIRFStruct.first, [ 'Computing required integral for fast IRFs for shock ' dynareOBC_.Shocks{i} '. Please wait for around ' ], '. Progress: ', [ 'Computing required integral for fast IRFs for shock ' dynareOBC_.Shocks{i} '. Completed in ' ] );
        end
        
        for j = dynareOBC_.VariableSelect
            IRFName = [ deblank( M.endo_names( j, : ) ) '_' deblank( M.exo_names( i, : ) ) ];
            CurrentIRF = TempIRFs( j, 1:Ts );
            IRFsWithoutBounds.( IRFName ) = CurrentIRF;
            if dynareOBC_.NumberOfMax > 0
                CurrentIRF = CurrentIRF + ( dynareOBC_.MSubMatrices{ j }( 1:Ts, : ) * alpha )';
            end
            oo.irfs.( IRFName ) = CurrentIRF;
            IRFOffsets.( IRFName ) = TempIRFOffsets( j, 1:Ts );
        end
    end
    dynareOBC_.IRFOffsets = IRFOffsets;
    dynareOBC_.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
