function fx = GlobalModelSolutionInternal( x, M, options, oo, dynareOBC )

    if any( ~isfinite( x ) )
        error( 'dynareOBC:GlobalBadParameters', 'Non-finite parameters were passed to GlobalModelSolutionInternal.' );
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
        fx = NaN( size( x ) );
        return
    end
    
    %% derived from nlma_th_moments.m
    options.ar = 0;
    nstatic = M.nstatic;
    nspred = M.nspred;
    nboth = M.nboth;
    nfwrd = M.nfwrd;
    
    select_obs = [ dynareOBC.VarIndices_StateVariableAndShockCombinations; dynareOBC.VarIndices_RawZeroLowerBounded' ];
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
            Mean = moments.third_order.mean;
            Variance = moments.third_order.Gamma_y_obs{1};
        otherwise
            error( 'dynareOBC:UnsupportedOrder', 'Only orders 1 to 3 are supported at present.' );
    end
    %% derived from "truncated normal calcs.mw"
       
    nSVASC = length( dynareOBC.VarIndices_StateVariableAndShockCombinations );
    
    E_x_xT = Mean( 1:nSVASC ) * Mean( 1:nSVASC )' + Variance( 1:nSVASC, 1:nSVASC );
    
    mx = Mean( 1:nSVASC );
    my = Mean( (nSVASC+1):end )';
    vxy = Variance( 1:nSVASC, (nSVASC+1):end );
    vyy = diag( Variance( (nSVASC+1):end, (nSVASC+1):end ) )';
    syy = sqrt( vyy );
    zy = my ./ syy;
    E_x_max_0_MyT = ( 1 / sqrt( 2 * pi ) ) * mx * ( syy .* exp( - 0.5 * zy .* zy ) ) + bsxfun( @times, mx * my + vxy, normcdf( zy ) - 1 );
    

    % gx = pinv( E_x_xT ) * E_x_max_0_MyT;
    % gx = gx(:);
    % fx = gx - x;

    gx = E_x_max_0_MyT;
    x = reshape( x, size( gx ) );
    fx = gx - E_x_xT * x;
    fx = fx(:);
    
end
