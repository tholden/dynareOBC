function [ oo_, dynareOBC_ ] = FastIRFs( M_, options_, oo_, dynareOBC_ )
% derived from nlma_irf.m
    
    IRFOffsets = struct;
    IRFsWithoutBounds = struct;
    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.IRFPeriods;
    % Compute irf, allowing correlated shocks
    SS = M_.Sigma_e + 1e-14 * eye( M_.exo_nbr );
    cs = transpose( chol( SS ) );
    
    for i = dynareOBC_.ShockSelect
        Shock = zeros( M_.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
        Shock(:,1) = dynareOBC_.ShockScale * cs( M_.exo_names_orig_ord, i );
        
        %pruning_abounds( M_, options_, IRFShockSequence, T, dynareOBC_.Order, 'lan_meyer-gohde', 1 );
        TempIRFStruct = ExpectedReturn( Shock, M_, oo_.dr, dynareOBC_ );
        
        TempIRFOffsets = repmat( dynareOBC_.Mean, 1, T );
        
        TempIRFs = TempIRFStruct.total - TempIRFOffsets;
        
        ZeroLowerBoundedReturnPath = vec( TempIRFStruct.total( dynareOBC_.VarIndices_ZeroLowerBounded, : )' );
        
        [ alpha, ~, ConstrainedReturnPath ] = SolveBoundsProblem( ZeroLowerBoundedReturnPath, dynareOBC_ );
        if dynareOBC_.Accuracy > 0
            alpha = PerformQuadrature( alpha, ZeroLowerBoundedReturnPath, ConstrainedReturnPath, options_, oo_, dynareOBC_, TempIRFStruct.first, [ 'Computing required integral for fast IRFs for shock ' dynareOBC_.Shocks{i} '. Please wait for around ' ], '. Progress: ', [ 'Computing required integral for fast IRFs for shock ' dynareOBC_.Shocks{i} '. Completed in ' ] );
        end
        
        for j = dynareOBC_.VariableSelect
            IRFName = [ deblank( M_.endo_names( j, : ) ) '_' deblank( M_.exo_names( i, : ) ) ];
            CurrentIRF = TempIRFs( j, 1:Ts );
            IRFsWithoutBounds.( IRFName ) = CurrentIRF;
            if dynareOBC_.NumberOfMax > 0
                CurrentIRF = CurrentIRF + ( dynareOBC_.MSubMatrices{ j }( 1:Ts, : ) * alpha )';
            end
            oo_.irfs.( IRFName ) = CurrentIRF;
            IRFOffsets.( IRFName ) = TempIRFOffsets( j, 1:Ts );
        end
    end
    dynareOBC_.IRFOffsets = IRFOffsets;
    dynareOBC_.IRFsWithoutBounds = IRFsWithoutBounds;
    
end
