% Contains code taken from pruning_abounds.m and nlma_irf.m by Lan and Meyer-Gohde

function dynareOBC_ = GetIRFsToShadowShocks( M_, options_, oo_, dynareOBC_ )

    %% code derived from pruning_abounds.m
    
    [numeric_version] = return_dynare_version(dynare_version);
    if numeric_version >= 4.4 
        nstatic = M_.nstatic;
        nspred = M_.nspred; % note M_.nspred = M_.npred+M_.nboth;
        % nboth = M_.nboth;
        % nfwrd = M_.nfwrd;
    else
        nstatic = oo_.dr.nstatic;
        nspred = oo_.dr.npred;
        % nboth = oo_.dr.nboth;
        % nfwrd = oo_.dr.nfwrd;
    end
    SelectState = ( nstatic + 1 ):( nstatic + nspred );
    
    dynareOBC_.SelectState = SelectState;

    Order = dynareOBC_.Order;
    
    nx = M_.exo_nbr;
    
    % set up ghu and ghx
    if Order == 1
        ghu = oo_.dr.ghu;
        dynareOBC_.OrderText = 'first';
    end
    if Order == 2
        ghu = (1/2)*oo_.dr.ghuu( :, 1:(nx+1):(nx*nx) );
        dynareOBC_.OrderText = 'second';
    end
    if Order==3
        if options_.pruning == 0
            oo_ = full_block_dr_new(oo_,M_,options_);
        end
        ghu = (1/6)*oo_.dr.ghuuu( :, 1:(nx*(nx+1)+1):(nx*nx*nx) );
        dynareOBC_.OrderText = 'third';
    end
    
    ghx = oo_.dr.ghx;
    
    dynareOBC_.HighestOrder_ghx = ghx;
    dynareOBC_.HighestOrder_ghu = ghu;
    
    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;

    %% code derived from nlma_irf.m
    MSubMatrices = cell( M_.endo_nbr, 1 );
    
    for j = 1 : M_.endo_nbr
        MSubMatrices{ j } = zeros( T, ns * Ts );
    end
    
    MMatrix = zeros( ns * T, ns * Ts );
    
    dynareOBC_.OriginalSigns = ones( Ts, ns );
	% Compute irfs
    simulation_first = zeros( M_.endo_nbr, T );
    
    SignsFlippedString = '';
    
    for l = 1 : ns
        for k = 1 : Ts
            E = zeros( M_.exo_nbr, 1 ); % Pre-allocate and reset irf shock sequence
            E( dynareOBC_.VarExoIndices_DummyShadowShocks( k, l ), 1 ) = 1 / sqrt( eps ); % M_.params( dynareOBC_.ParameterIndices_ShadowShockCombinations_Slice( k, l ) );

            % IRFs{i,j} = pruning_abounds( M_, options_, E, T, 1, 'lan_meyer-gohde' );

            %% code derived from pruning_abounds.m
            simulation_first(:,1) = ghu * E(:,1); 
            for t = 2 : T
              simulation_first(:,t) = ghx * simulation_first( SelectState, t-1 );
            end
            simulation_first = simulation_first( oo_.dr.inv_order_var, : );
            
            if simulation_first( dynareOBC_.VarIndices_ZeroLowerBounded( l ), k ) < 0
                dynareOBC_.OriginalSigns( k, l ) = -1;
                simulation_first = -simulation_first;
                SignsFlippedStringAddition = [ '( ' int2str( l ) ', ' int2str( k ) ' )' ];
                if isempty( SignsFlippedString )
                    SignsFlippedString = SignsFlippedStringAddition;
                else
                    SignsFlippedString = [ SignsFlippedString ', ' SignsFlippedStringAddition ]; %#ok<AGROW>
                end
            end
            
            for j = 1 : ns % j and l here correspond to the notation in the paper
                IRF = simulation_first( dynareOBC_.VarIndices_ZeroLowerBounded( j ), : )';
                MMatrix( ( (j-1)*T + 1 ):( j * T ), (l-1)*Ts + k ) = IRF;
            end
            for j = 1 : M_.endo_nbr % j and l here correspond to the notation in the paper
                IRF = simulation_first( j, : )';
                MSubMatrices{ j }( :, (l-1)*Ts + k ) = IRF;
            end
        end
    end
    
    %% Save the new matrices
    dynareOBC_.MSubMatrices = MSubMatrices;
    dynareOBC_.MMatrix = MMatrix;

    SelectIndices = vec( bsxfun( @plus, (1:Ts)', 0:T:((ns-1)*T) ) )';
    dynareOBC_.SelectIndices = SelectIndices;
    InverseSelectIndices = zeros( T, ns );
    InverseSelectIndices( 1:Ts, : ) = reshape( 1 : ( Ts * ns ), Ts, ns );
    InverseSelectIndices = vec( InverseSelectIndices );
    dynareOBC_.InverseSelectIndices = InverseSelectIndices;
    % InverseSelectIndices( SelectIndices ) = 1 : ( Ts * ns )

    MsMatrix = MMatrix( SelectIndices, : );
    dynareOBC_.MsMatrix = MsMatrix;
    
    dynareOBC_.MsMatrixSymmetric = MsMatrix + MsMatrix';
    
    SignsFlipped = dynareOBC_.OriginalSigns < 1;
    if any( SignsFlipped(:) )
        warning( 'dynareOBC:SignFlipped', 'Signs have been flipped for the shadow shocks: %s.\nThis may indicate a problem with your model.', SignsFlippedString );
    end
    
end