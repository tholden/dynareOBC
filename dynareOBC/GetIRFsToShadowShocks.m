% Contains code taken from pruning_abounds.m and nlma_irf.m by Lan and Meyer-Gohde

function dynareOBC = GetIRFsToShadowShocks( M, oo, dynareOBC )

    maximum_lag = M.maximum_endo_lag;
    nspred   = M.nspred;
    nstatic  = M.nstatic;
    endo_nbr = M.endo_nbr;
    exo_nbr  = M.exo_nbr;

    order_var = oo.dr.order_var;
    SelectState = ( nstatic + 1 ):( nstatic + nspred );
    
    dynareOBC.SelectState = SelectState;

    %% begin code taken from stochastic_solvers
    
    klen = M.maximum_lag + M.maximum_lead + 1;
    exo_simul = [repmat(oo.exo_steady_state',klen,1) repmat(oo.exo_det_steady_state',klen,1)];
    iyv = M.lead_lag_incidence';
    z = repmat(oo.dr.ys,1,klen);
    [ ~, jacobia ] = feval( [M.fname '_dynamic'],z(find(iyv(:))),exo_simul, M.params, oo.dr.ys, M.maximum_lag + 1 ); %#ok<FNDSB>
    
    %% end code taken from stochastic_solvers
    
    %% begin taken from dyn_first_order_solver
    
    lead_lag_incidence = M.lead_lag_incidence;
    nz = nnz(lead_lag_incidence);

    reorder_jacobian_columns = [nonzeros(lead_lag_incidence(:,order_var)'); nz+(1:exo_nbr)'];

    jacobia = real( jacobia(:,reorder_jacobian_columns) );
    
    % A = zeros( endo_nbr );
    B = zeros( endo_nbr );
    C = zeros( endo_nbr );
    
    % [ ~, cols_a ] = find(lead_lag_incidence(maximum_lag, order_var));
    [ ~, cols_b ] = find(lead_lag_incidence(maximum_lag+1, order_var));
    [ ~, cols_c ] = find(lead_lag_incidence(maximum_lag+2, order_var));
    % A( :, cols_a ) = jacobia( :, nonzeros(lead_lag_incidence(maximum_lag,:)) );
    B( :, cols_b ) = jacobia( :, nonzeros(lead_lag_incidence(maximum_lag+1,:)) );
    C( :, cols_c ) = jacobia( :, nonzeros(lead_lag_incidence(maximum_lag+2,:)) );
        
    %% end taken from dyn_first_order_solver

    %% calculate ps
    
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    VarIndices = dynareOBC.VarIndices_ZeroLowerBounded;
    
    if dynareOBC.Global
        VarIndicesLongRun = dynareOBC.VarIndices_ZeroLowerBoundedLongRun;
    end
    
    F = kalman_transition_matrix(oo.dr,(1:endo_nbr)',nstatic+(1:nspred)',exo_nbr);
    V = inv( B + C * F );
    
    ITs = eye( Ts );
    Iendo_nbr = eye( endo_nbr );
    
    p = cell( Ts, ns );
    
    for l = 1 : ns
        pVal = zeros( endo_nbr, Ts );
        if dynareOBC.Global
            ZLBEquationSelect = sum( Iendo_nbr( :, ( endo_nbr - 2 * ns + 2 * l - 1 ) : ( endo_nbr - 2 * ns + 2 * l ) ), 2 );
        else
            ZLBEquationSelect = Iendo_nbr( :, endo_nbr - ns + l );
        end
        for t = Ts : -1 : 1
            pVal = - V * ( C * pVal - ZLBEquationSelect * ITs( t, : ) );
            p{ t, l } = pVal;
        end
    end
    
    % dynareOBC.pMat = cell( Ts, 1 );
    % for t = 1 : Ts
    %   dynareOBC.pMat{ t } = cell2mat( p( t, : ) );
    % end

    dynareOBC.pMat = cell2mat( p( 1, : ) );
    
    MSubMatrices = cell( endo_nbr, 1 );
    
    for j = 1 : endo_nbr
        MSubMatrices{ j } = zeros( T, ns * Ts );
    end
    
    MMatrix = zeros( ns * T, ns * Ts );
    MMatrixLongRun = zeros( ns * T, ns * Ts );
    
    % Compute irfs
    simulation = zeros( endo_nbr, T );
    
    for l = 1 : ns
        for k = 1 : Ts
            y = ITs( :, k );
            simulation(:,1) = p{ 1, l } * y;
            for t = 2 : Ts
              simulation(:,t) = p{ t, l } * y + F * simulation( :, t-1 );
            end
            for t = ( Ts + 1 ) : T
              simulation(:,t) = F * simulation( :, t-1 );
            end
            simulation = simulation( oo.dr.inv_order_var, : );
            
            for j = 1 : ns % j and l here correspond to the notation in the paper
                IRF = simulation( VarIndices( j ), : )';
                MMatrix( ( (j-1)*T + 1 ):( j * T ), (l-1)*Ts + k ) = IRF;
            end
            if dynareOBC.Global
                for j = 1 : ns % j and l here correspond to the notation in the paper
                    IRFLongRun = simulation( VarIndicesLongRun( j ), : )';
                    MMatrixLongRun( ( (j-1)*T + 1 ):( j * T ), (l-1)*Ts + k ) = IRFLongRun;
                end
            end
            for j = 1 : endo_nbr % j and l here correspond to the notation in the paper
                IRF = simulation( j, : )';
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