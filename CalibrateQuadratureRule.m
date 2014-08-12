function dynareOBC_ = CalibrateQuadratureRule( M_, options_, oo_, dynareOBC_ )

    T = dynareOBC_.InternalIRFPeriods;
    ns = dynareOBC_.NumberOfMax;
    RootConditionalCovariance = RetrieveConditionalCovariances( options_, oo_, dynareOBC_, sparse( M_.endo_nbr, T * ns ) );
    d = size( RootConditionalCovariance, 2 );
    AZBC = abs( dynareOBC_.Mean( dynareOBC_.VarIndices_ZeroLowerBounded ) )';
    kappa = Inf;
    for i = 1 : d
        CurrentShock = max( abs( reshape( RootConditionalCovariance( :, i ), T, ns ) ) );
        kappa = min( kappa, min( AZBC ./ CurrentShock ) );
    end
    kappa = kappa * dynareOBC_.Scale_kappa_lambda;
    kappa_alt = 0;
    if dynareOBC_.OrderFiveQuadrature
        dM1 = d - 1;
        lambda = Inf;
        for i = 1 : d
            for j = (i+1) : d
                CurrentShock1 = reshape( RootConditionalCovariance( :, i ), T, ns );
                CurrentShock2 = reshape( RootConditionalCovariance( :, j ), T, ns );
                CurrentShockA = max( abs( CurrentShock1 + CurrentShock2 ) );
                CurrentShockB = max( abs( CurrentShock1 - CurrentShock2 ) );
                lambda = min( lambda, min( min( AZBC ./ CurrentShockA ), min( AZBC ./ CurrentShockB ) ) );
            end
        end
        lambda = min( lambda * dynareOBC_.Scale_kappa_lambda, sqrt( dM1 ) - sqrt( eps ) );
        tmp = dM1 - lambda * lambda;
        kappa = min( kappa, lambda * sqrt( tmp * ( d - 4 ) ) / tmp );
    elseif dynareOBC_.PseudoOrderFiveQuadrature
        kappa = min( kappa, sqrt( 3 ) );
        target_kappa = sqrt( 7 ) / 2;
        if kappa < target_kappa
            warning( 'dynareOBC:kappa', 'Your model appars to be too close to the bound in steady-state for the pseudo-order-five quadrature algorithm to work properly.\nThe quadrature used will just give degree 3 accuracy.\nFound kappa: %f. Target kappa: %f.', kappa, target_kappa );
            kappa_alt = (1/14)*sqrt(140) * kappa;
        else
            kappa_alt = sqrt( 3 - kappa * kappa );
        end
    else
        kappa = min( kappa, 0.5 * sqrt( 2 + 4 * d ) );
    end        
    dynareOBC_.kappa = kappa;
    dynareOBC_.kappa_alt = kappa_alt;

end

