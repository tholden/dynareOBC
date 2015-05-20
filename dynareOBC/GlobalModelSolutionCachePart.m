function beta = GlobalModelSolutionCachePart( x, M, options, oo, dynareOBC )

    if any( ~isfinite( x ) )
        error( 'dynareOBC:GlobalBadParameters', 'Non-finite parameters were passed to GlobalModelSolutionCachePart.' );
    end
    
    PI = dynareOBC.ParameterIndices_StateVariableAndShockCombinations(:);
    M.params( PI ) = x;
    
    Info = -1;
    try
        [ dr, Info, M, options, oo ] = resol( 0, M, options, oo );
        oo.dr = dr;
    catch
    end
    
    if Info ~= 0
        error( 'dynareOBC:GlobalCacheFailure', 'Failed caching the approximation.' );
    end
    
    %% derived from nlma_th_moments.m
    options.ar = 0;
    nstatic = M.nstatic;
    nspred = M.nspred;
    nboth = M.nboth;
    nfwrd = M.nfwrd;

    SelectSVASC = sum( dynareOBC.StateVariableAndShockCombinations( :, 2:end ), 2 ) <= 1;
    select_obs = [ dynareOBC.VarIndices_StateVariableAndShockCombinations( SelectSVASC ); dynareOBC.VarIndices_ZeroLowerBounded' ];
    select_obs = oo.dr.inv_order_var( select_obs ); 
    
	select_state = ( nstatic + 1 ):( nstatic + nspred );

    moments.nstatic = nstatic;
    moments.npred   = nspred;
    moments.nboth   = nboth;
    moments.nfwrd   = nfwrd;
    
    moments.select_state = select_state;
    moments.select_obs   = select_obs;
    
    moments.ns = size( select_state, 2 );
    
    moments.nobs = size( select_obs, 1 );
    
    moments.ne = M.exo_nbr;
    
    switch options.order
        case 1
            moments = nlma_th_mom_first( moments, M, oo, options );
            Mean = moments.first_order.mean;
            Variance = moments.first_order.Gamma_obs{1};
        case 2
            moments = nlma_th_mom_second( moments, M, oo, options );
            Mean = moments.second_order.mean;
            Variance = moments.second_order.Gamma_y_obs{1};
        case 3
            moments = nlma_th_mom_third( moments, M, oo, options );
            Mean = moments.second_order.mean;
            Variance = moments.third_order.Gamma_y_obs{1};
        otherwise
            error( 'dynareOBC:UnsupportedOrder', 'Only orders 1 to 3 are supported at present.' );
    end
    %% derived from "truncated normal calcs.mw"
       
    nSVASC = sum( SelectSVASC );
    
    E_x_xT = Mean( 1:nSVASC ) * Mean( 1:nSVASC )' + Variance( 1:nSVASC, 1:nSVASC );
    E_x_yT = Mean( 1:nSVASC ) * Mean( (nSVASC+1):end )' + Variance( 1:nSVASC, (nSVASC+1):end );
    
    beta = pinv( E_x_xT ) * E_x_yT;
    
end
