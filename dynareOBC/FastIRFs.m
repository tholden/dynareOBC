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
    else
        pWeight = [];
    end
       
	TempIRFLROffsets = repmat( dynareOBC.Mean, 1, T );
	TempIRFSROffsets = zeros( length( dynareOBC.VariableSelect ), Ts );
    if dynareOBC.NumberOfMax > 0 && ( ~dynareOBC.NoCubature || dynareOBC.Global )
        Shock = zeros( M.exo_nbr, 1 );
        y = FastIRFsInternal( Shock, 'the base path', pWeight, M, options, oo, dynareOBC );
		for k = 1:length( dynareOBC.VariableSelect )
			j = dynareOBC.VariableSelect( k );
			TempIRFSROffsets( k, : ) = ( dynareOBC.MSubMatrices{ j }( 1:Ts, : ) * y )';
		end
    end
	        
    for i = dynareOBC.ShockSelect
        Shock = zeros( M.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
        Shock(:,1) = dynareOBC.ShockScale * cs( M.exo_names_orig_ord, i );
        
        [ y, TempIRFStruct ] = FastIRFsInternal( Shock, [ 'shock ' dynareOBC.Shocks{i} ], pWeight, M, options, oo, dynareOBC );
        
        TempIRFs = TempIRFStruct.total - TempIRFLROffsets;
        
        for k = 1:length( dynareOBC.VariableSelect )
			j = dynareOBC.VariableSelect( k );
            IRFName = [ deblank( M.endo_names( j, : ) ) '_' deblank( M.exo_names( i, : ) ) ];
            CurrentIRF = TempIRFs( j, 1:Ts );
            IRFsWithoutBounds.( IRFName ) = CurrentIRF;
            if dynareOBC.NumberOfMax > 0
                CurrentIRF = CurrentIRF - TempIRFSROffsets( k, 1:Ts ) + ( dynareOBC.MSubMatrices{ j }( 1:Ts, : ) * y )';
            end
            oo.irfs.( IRFName ) = CurrentIRF;
            IRFOffsets.( IRFName ) = TempIRFLROffsets( j, 1:Ts );
        end
    end
    dynareOBC.IRFOffsets = IRFOffsets;
    dynareOBC.IRFsWithoutBounds = IRFsWithoutBounds;
    
end

function [ y, TempIRFStruct ] = FastIRFsInternal( Shock, ShockName, pWeight, M, options, oo, dynareOBC )
    TempIRFStruct = ExpectedReturn( Shock, M, oo.dr, dynareOBC );

    UnconstrainedReturnPath = vec( TempIRFStruct.total( dynareOBC.VarIndices_ZeroLowerBounded, : )' );
    
    y = SolveBoundsProblem( UnconstrainedReturnPath, dynareOBC );

	if dynareOBC.NumberOfMax > 0
        if ~dynareOBC.NoCubature
			y = PerformCubature( y, UnconstrainedReturnPath, options, oo, dynareOBC, TempIRFStruct.first, [ 'Computing required integral for fast IRFs for ' ShockName '. Please wait for around ' ], '. Progress: ', [ 'Computing required integral for fast IRFs for ' ShockName '. Completed in ' ] );
        end

        if dynareOBC.Global
			y = SolveGlobalBoundsProblem( y, zeros( size( y ) ), UnconstrainedReturnPath, TempIRFStruct.total( dynareOBC.VarIndices_ZeroLowerBoundedLongRun, : )', pWeight, dynareOBC );
        end
	end
end
