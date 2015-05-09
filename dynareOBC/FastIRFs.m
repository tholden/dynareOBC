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
        ErrorWeight = repmat( 1 - pWeight, 1, dynareOBC.NumberOfMax );
    end
    
    if dynareOBC.Global
        Shock = zeros( M.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
        yGlobal = FastIRFsInternal( Shock, 'global-offset',  pWeight, ErrorWeight, M, options, oo, dynareOBC, [] );
        GlobalOffset = dynareOBC.MMatrixLongRun * yGlobal;
    else
        GlobalOffset = [];
    end
    
    for i = dynareOBC.ShockSelect
        Shock = zeros( M.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
        Shock(:,1) = dynareOBC.ShockScale * cs( M.exo_names_orig_ord, i );
        
        [ y, TempIRFStruct ] = FastIRFsInternal( Shock, dynareOBC.Shocks{i},  pWeight, ErrorWeight, M, options, oo, dynareOBC, GlobalOffset );
        
        TempIRFOffsets = repmat( dynareOBC.Mean, 1, T );
        
        TempIRFs = TempIRFStruct.total - TempIRFOffsets;
        
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

function [ y, TempIRFStruct ] = FastIRFsInternal( Shock, ShockName, pWeight, ErrorWeight, M, options, oo, dynareOBC, GlobalOffset )
    TempIRFStruct = ExpectedReturn( Shock, M, oo.dr, dynareOBC );

    UnconstrainedReturnPath = vec( TempIRFStruct.total( dynareOBC.VarIndices_ZeroLowerBounded, : )' );
    
    if ~isempty( GlobalOffset )
        UnconstrainedReturnPath = UnconstrainedReturnPath - GlobalOffset;
    end
    
    y = SolveBoundsProblem( UnconstrainedReturnPath, dynareOBC );

    if ~dynareOBC.NoCubature
        y = PerformCubature( y, UnconstrainedReturnPath, options, oo, dynareOBC, TempIRFStruct.first, [ 'Computing required integral for fast IRFs for shock ' ShockName '. Please wait for around ' ], '. Progress: ', [ 'Computing required integral for fast IRFs for shock ' ShockName '. Completed in ' ] );
    end

    if dynareOBC.Global
        y = SolveGlobalBoundsProblem( y, UnconstrainedReturnPath,  TempIRFStruct.total( dynareOBC.VarIndices_ZeroLowerBoundedLongRun, : )', pWeight, ErrorWeight, dynareOBC );
    end
end
