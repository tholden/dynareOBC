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
    
    A = zeros( endo_nbr );
    B = zeros( endo_nbr );
    C = zeros( endo_nbr );
    
    [ ~, cols_a ] = find(lead_lag_incidence(maximum_lag, order_var));
    [ ~, cols_b ] = find(lead_lag_incidence(maximum_lag+1, order_var));
    [ ~, cols_c ] = find(lead_lag_incidence(maximum_lag+2, order_var));
    A( :, cols_a ) = jacobia( :, nonzeros(lead_lag_incidence(maximum_lag,:)) );
    B( :, cols_b ) = jacobia( :, nonzeros(lead_lag_incidence(maximum_lag+1,:)) );
    C( :, cols_c ) = jacobia( :, nonzeros(lead_lag_incidence(maximum_lag+2,:)) );
        
    %% end taken from dyn_first_order_solver
    
    %% calculate ps
    
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    FTGC = dynareOBC.FeasibilityTestGridSize;

    if FTGC
        TimeReversedSolutionError = 0;
    else
        TimeReversedSolutionError = 100;
    end
    
    seps = sqrt( eps );
    if abs( det( A + B + C ) ) < seps
        warning( 'dynareOBC:UnitRoot', 'Your model appears to have an exact unit root. Skipping infinite T tests.' );
        TimeReversedSolutionError = 7;
    end

    VarIndices = dynareOBC.VarIndices_ZeroLowerBounded;
    
    if dynareOBC.Global
        VarIndicesLongRun = dynareOBC.VarIndices_ZeroLowerBoundedLongRun;
    end
    
    F = kalman_transition_matrix(oo.dr,(1:endo_nbr)',nstatic+(1:nspred)',exo_nbr);
    
    if dynareOBC.Debug
        [ F2, info ] = cycle_reduction( A, B, C, seps, true );

        if max( max( abs( F - F2 ) ) ) > seps
            warning( 'dynareOBC:PotentialSolutionInaccuracy', 'Resolving the model with cycle reduction produced a different result.' );
        end

        if info ~= 0
            warning( 'dynareOBC:PotentialSolutionProblems', 'Resolving the model with cycle reduction produced no solution.' );
        end
    end
    
    V = inv( B + C * F );
    
    G = -C * V; %#ok<MINV>
    
    if ~TimeReversedSolutionError
        try
            [ H, TimeReversedSolutionError ] = cycle_reduction( C, B, A, seps, true );
        catch
            H = [];
            TimeReversedSolutionError = 1;
            warning( 'dynareOBC:NoTimeReversedSolution', 'Could not solve the time reversed model. Skipping infinite T tests.' );
        end
    end
    
    if ~TimeReversedSolutionError
        if ( max( abs( eig( F ) ) ) > 1 - 2 * seps )
            warning( 'dynareOBC:CloseToUnitRoot', 'Forward model is close to a unit root. Skipping infinite T tests.' );
            TimeReversedSolutionError = 2;
        end       
        if ( max( abs( eig( H ) ) ) > 1 - 2 * seps )
            warning( 'dynareOBC:CloseToUnitRoot', 'Backwards model is close to a unit root. Skipping infinite T tests.' );
            TimeReversedSolutionError = 2;
        end       
        if dynareOBC.Debug
            if max( abs( sort( abs( eig( G ) ) ) - sort( abs( eig( H ) ) ) ) ) > seps
                warning( 'dynareOBC:GHNonAgreement', 'The eigenvalues of the G and H matrices do not appear to agree.' );
            end
        end
    end

    ITs = eye( Ts );
    Iendo_nbr = eye( endo_nbr );
    
    p = cell( Ts, ns );
    
    if ~TimeReversedSolutionError
        d0 = zeros( endo_nbr, ns );
        InvIMinusHdPs = zeros( ns, ns, 2 * Ts - 1 );
        InvIMinusFdNs = zeros( ns, ns, 2 * Ts - 1 );
        d0s = zeros( ns, ns );
        dPs = zeros( ns, ns, 2 * Ts - 1 );
        dNs = zeros( ns, ns, 2 * Ts - 1 );
        
        InvIMinusF = inv( Iendo_nbr - F );
        InvIMinusH = inv( Iendo_nbr - H );

        IOV = oo.dr.inv_order_var;
        IOVVarIndices = IOV( VarIndices );
    end
    
    for l = 1 : ns
        pVal = zeros( endo_nbr, Ts );
        if dynareOBC.Global
            ZLBEquationSelect = sum( Iendo_nbr( :, ( endo_nbr - 2 * ns + 2 * l - 1 ) : ( endo_nbr - 2 * ns + 2 * l ) ), 2 );
        else
            ZLBEquationSelect = Iendo_nbr( :, endo_nbr - ns + l );
        end
        if ~TimeReversedSolutionError
            d0t = ( A*H + B + C*F ) \ ZLBEquationSelect; % sign of ZLBEquationSelect flipped relative to paper because dynare defines things on the opposite side of the equals sign
            d0( :, l ) = d0t( IOV );
            d0s( :, l ) = d0t( IOVVarIndices );
            dPt = d0t;
            dNt = d0t;
            for t = 1 : ( 2 * Ts - 1 )
                dPt = H * dPt;
                dNt = F * dNt;
                tmp = InvIMinusH * dPt; %#ok<MINV>
                InvIMinusHdPs( :, l, t ) = tmp( IOVVarIndices );
                tmp = InvIMinusF * dNt; %#ok<MINV>
                InvIMinusFdNs( :, l, t ) = tmp( IOVVarIndices );
                dPs( :, l, t ) = dPt( IOVVarIndices );
                dNs( :, l, t ) = dNt( IOVVarIndices );
            end
        end
        for t = Ts : -1 : 1
            pVal = - V * ( C * pVal - ZLBEquationSelect * ITs( t, : ) ); % sign of ZLBEquationSelect flipped relative to paper because dynare defines things on the opposite side of the equals sign
            p{ t, l } = pVal;
        end
    end
    
    if TimeReversedSolutionError
        dynareOBC.NormInvIMinusF = [];
        dynareOBC.Norm_d0 = [];
        dynareOBC.d0s = [];
        dynareOBC.dPs = [];
        dynareOBC.dNs = [];
        dynareOBC.InvIMinusHd0s = [];
        dynareOBC.InvIMinusFd0s = [];
        dynareOBC.InvIMinusHdPs = [];
        dynareOBC.InvIMinusFdNs = [];
    else
        dynareOBC.NormInvIMinusF = norm( InvIMinusF, 2 );
        dynareOBC.Norm_d0 = sqrt( sum( abs( d0 ).^2 ) );
        dynareOBC.d0s = d0s;
        dynareOBC.dPs = dPs;
        dynareOBC.dNs = dNs;
        tmp = InvIMinusH * d0; %#ok<MINV>
        dynareOBC.InvIMinusHd0s = tmp( IOVVarIndices, : );
        tmp = InvIMinusF * d0; %#ok<MINV>
        dynareOBC.InvIMinusFd0s = tmp( IOVVarIndices, : );
        dynareOBC.InvIMinusHdPs = InvIMinusHdPs;
        dynareOBC.InvIMinusFdNs = InvIMinusFdNs;
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
    if dynareOBC.Global
        MMatrixLongRun = zeros( ns * T, ns * Ts );
    end
    
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
    
    if dynareOBC.Debug && ~TimeReversedSolutionError
        figure;
        plot( (-(Ts-1)):(Ts-1), [ MMatrix( Ts, 1:Ts ) MMatrix( (Ts-1):-1:1, Ts )' ], '-r', (-(2*Ts-1)):(2*Ts-1), [ squeeze( dNs( 1, 1, end:-1:1 ) ); d0s( 1, 1 ); squeeze( dPs( 1, 1, 1:end ) ) ], '--g' );
    end

    if ~TimeReversedSolutionError
        disp( 'Performing pre-calculations for the tests of feasibility with arbitrarily large T (TimeToEscapeBounds).' );
        disp( 'To skip this run dynareOBC with the FeasibilityTestGridSize=0 option.' );
        
        rhoFmin = max( abs( eig( F ) ) );
        rhoGmin = max( abs( eig( G ) ) );
        rhoScales = ( 1:FTGC )' ./ ( FTGC + 1 );
        rhoF = ( 1 - rhoScales ) * rhoFmin + rhoScales;
        rhoG = ( 1 - rhoScales ) * rhoGmin + rhoScales;
        
        CF = zeros( FTGC, 1 );
        CG = zeros( FTGC, 1 );
        CH = zeros( FTGC, 1 );
        
        for i = 1 : FTGC

            CF( i ) = GetC( F / rhoF( i ) );
            CG( i ) = GetC( G / rhoG( i ) );
            CH( i ) = GetC( H / rhoG( i ) );
        
        end
        
        D = ( CF * CG' ) .* norm( V, 2 );
        
        dynareOBC.rhoF = rhoF;
        dynareOBC.rhoG = rhoG;
        dynareOBC.CF = CF;
        dynareOBC.CG = CG;
        dynareOBC.CH = CH;
        dynareOBC.D = D;
    end
    
    
end

function C = GetC( M )
    InitialValue = 0;
    epsilonStar = -1;
    while epsilonStar < 0
        try
            epsilonStar = exp( fzero( @( log_epsilon ) pspr_2way( M, exp( log_epsilon ) ) - 1, InitialValue ) );
        catch
            InitialValue = InitialValue - 1;
        end
    end
    
    Power = eye( size( M ) );
    Norm = 1;
    SupNorm = 1;
    
    while SupNorm * epsilonStar < Norm
        Power = Power * M;
        Norm = norm( Power, 2 );
        SupNorm = max( Norm, SupNorm );
    end
    
    C = SupNorm;

end
