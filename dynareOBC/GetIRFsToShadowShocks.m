% Contains code taken from pruning_abounds.m and nlma_irf.m by Lan and Meyer-Gohde

function dynareOBC = GetIRFsToShadowShocks( M, options, oo, dynareOBC )

    %% code derived from pruning_abounds.m
    
    [numeric_version] = return_dynare_version(dynare_version);
    if numeric_version >= 4.4 
        nstatic = M.nstatic;
        nspred = M.nspred; % note M_.nspred = M_.npred+M_.nboth;
        % nboth = M_.nboth;
        % nfwrd = M_.nfwrd;
    else
        nstatic = oo.dr.nstatic;
        nspred = oo.dr.npred;
        % nboth = oo_.dr.nboth;
        % nfwrd = oo_.dr.nfwrd;
    end
    SelectState = ( nstatic + 1 ):( nstatic + nspred );
    
    dynareOBC.SelectState = SelectState;

    Order = dynareOBC.Order;
    
    nx = M.exo_nbr;
    
    % set up ghu and ghx
    if Order == 1
        ghu = oo.dr.ghu;
        dynareOBC.OrderText = 'first';
    end
    if Order == 2
        ghu = (1/2)*oo.dr.ghuu( :, 1:(nx+1):(nx*nx) );
        dynareOBC.OrderText = 'second';
    end
    if Order==3
        if options.pruning == 0
            oo = full_block_dr_new(oo,M,options);
        end
        ghu = (1/6)*oo.dr.ghuuu( :, 1:(nx*(nx+1)+1):(nx*nx*nx) );
        dynareOBC.OrderText = 'third';
    end
    
    ghx = oo.dr.ghx;
    
    dynareOBC.HighestOrder_ghx = ghx;
    dynareOBC.HighestOrder_ghu = ghu;
    
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    %% code derived from nlma_irf.m
    MSubMatrices = cell( M.endo_nbr, 1 );
    
    for j = 1 : M.endo_nbr
        MSubMatrices{ j } = zeros( T, ns * Ts );
    end
    
    MMatrix = zeros( ns * T, ns * Ts );
    MMatrixLongRun = zeros( ns * T, ns * Ts );
    
	% Compute irfs
    simulation_first = zeros( M.endo_nbr, T );
    
    if dynareOBC.Global
        VarIndicesLongRun = dynareOBC.VarIndices_ZeroLowerBoundedLongRun;
    end
    VarIndices = dynareOBC.VarIndices_ZeroLowerBounded;
    
    for l = 1 : ns
        for k = 1 : Ts
            E = zeros( M.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
            E( dynareOBC.VarExoIndices_DummyShadowShocks( k, l ), 1 ) = 1 / sqrt( eps ); % M_.params( dynareOBC_.ParameterIndices_ShadowShockCombinations_Slice( k, l ) );

            % IRFs{i,j} = pruning_abounds( M_, options_, E, T, 1, 'lan_meyer-gohde' );

            %% code derived from pruning_abounds.m
            simulation_first(:,1) = ghu * E(:,1); 
            for t = 2 : T
              simulation_first(:,t) = ghx * simulation_first( SelectState, t-1 );
            end
            simulation_first = simulation_first( oo.dr.inv_order_var, : );
            
            for j = 1 : ns % j and l here correspond to the notation in the paper
                IRF = simulation_first( VarIndices( j ), : )';
                MMatrix( ( (j-1)*T + 1 ):( j * T ), (l-1)*Ts + k ) = IRF;
            end
            if dynareOBC.Global
                for j = 1 : ns % j and l here correspond to the notation in the paper
                    IRFLongRun = simulation_first( VarIndicesLongRun( j ), : )';
                    MMatrixLongRun( ( (j-1)*T + 1 ):( j * T ), (l-1)*Ts + k ) = IRFLongRun;
                end
            end
            for j = 1 : M.endo_nbr % j and l here correspond to the notation in the paper
                IRF = simulation_first( j, : )';
                MSubMatrices{ j }( :, (l-1)*Ts + k ) = IRF;
            end
        end
    end
    %% Save the new matrices
    dynareOBC.MSubMatrices = MSubMatrices;
    dynareOBC.MMatrix = MMatrix;
    if dynareOBC.Global
        dynareOBC.MMatrixLongRun = MMatrixLongRun;
    end

    sIndices = vec( bsxfun( @plus, (1:Ts)', 0:T:((ns-1)*T) ) )';
    dynareOBC.sIndices = sIndices;
    sInverseIndices = zeros( T, ns );
    sInverseIndices( 1:Ts, : ) = reshape( 1 : ( Ts * ns ), Ts, ns );
    sInverseIndices = vec( sInverseIndices );
    dynareOBC.sInverseIndices = sInverseIndices;

    dynareOBC.MsMatrix = MMatrix( sIndices, : );
    dynareOBC.NormMsMatrix = norm( dynareOBC.MsMatrix, Inf );
    
end