function resid = CalibrateMomentsEST( tau, nu, mu, lambda, Sigma, sZ3, sZ4 )

    if isempty( sZ4 )
        if nu <= 3
            resid = Inf;
            return;
        end
    else
        if nu <= 4
            resid = Inf;
            return;
        end
    end
    
    tcdf_tau_nu = tcdf( tau, nu );
    tpdfRatio = tpdf( tau, nu ) / tcdf_tau_nu;
    tauTtau = tau * tau;
    OPtauTtauDnu = 1 + tauTtau / nu;
    ET1 = nu / ( nu - 1 ) * OPtauTtauDnu * tpdfRatio;
    tau2 = tau * sqrt( ( nu - 2 ) / nu );
    ET2 = nu / ( nu - 2 ) * tcdf( tau2, nu - 2 ) / tcdf_tau_nu - tau * ET1;
    nuTnu = nu * nu;
    ET3 = 2 * nuTnu / ( ( nu - 1 ) * ( nu - 3 ) ) * OPtauTtauDnu * OPtauTtauDnu * tpdfRatio + tauTtau * ET1;
    
    MedT = tinv( tcdf_tau_nu + ( 1 - tcdf_tau_nu ) * 0.5, nu );
    
    delta = ( mu - lambda ) / ( ET1 - MedT );
    delta_deltaT = delta * delta';
    ET12 = ET1 * ET1;
    Omega = ( ( nu - 1 ) / ( nu + ET2 ) ) * ( Sigma - ( ET2 - ET12 ) * delta_deltaT );
    OmegaHat = Omega + delta_deltaT;
    
    deltaT_delta = delta' * delta;
    deltaT_delta2 = deltaT_delta * deltaT_delta;
    deltaT_OmegaHat_delta = delta' * OmegaHat * delta;
    deltaT_Sigma_delta = delta' * Sigma * delta;
    sqrt_deltaT_OmegaHat_delta = sqrt( deltaT_OmegaHat_delta );
    OmegaHatSigmaRatio = deltaT_OmegaHat_delta / deltaT_Sigma_delta;
    sqrt_delta2OmegaHatRatio = deltaT_delta / sqrt_deltaT_OmegaHat_delta;
    delta2OmegaHatRatio = deltaT_delta2 / deltaT_OmegaHat_delta;
    
    omega1 = sqrt_delta2OmegaHatRatio * ET1;
    omega2 = ( deltaT_Sigma_delta + deltaT_delta2 * ET12 ) / deltaT_OmegaHat_delta;
    OMdelta2OmegaHatRatio = 1 - delta2OmegaHatRatio;
    omega3 = 3 * nu / ( nu - 1 ) * sqrt_delta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( ET1 + ET3 / nu ) + delta2OmegaHatRatio * sqrt_delta2OmegaHatRatio * ET3;
    
    Z3 = OmegaHatSigmaRatio * sqrt( OmegaHatSigmaRatio ) * ( omega3 - 3 * omega2 * sqrt_delta2OmegaHatRatio * ET1 + 3 * omega1 * delta2OmegaHatRatio * ET12 - sqrt_delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET1 );
    
    if isempty( sZ4 )
        resid = sZ3 - Z3;
    else
        tau4 = tau * sqrt( ( nu - 4 ) / nu );
        ET4 = 3 * nuTnu / ( ( nu - 2 ) * ( nu - 4 ) ) * tcdf( tau4, nu - 4 ) / tcdf_tau_nu - 1.5 * tau * ET3 + 0.5 * tauTtau * tau * ET1; 
        omega4 = 3 * nuTnu / ( ( nu - 1 ) * ( nu - 3 ) ) * OMdelta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( 1 + 2 / nu * ET2 + ET4 / nuTun ) + 6 * nu / ( nu - 1 ) * delta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( ET2 + ET4 / nu ) + delta2OmegaHatRatio * delta2OmegaHatRatio * ET4;
        Z4 = OmegaHatSigmaRatio * OmegaHatSigmaRatio * ( omega4 - 4 * omega3 * sqrt_delta2OmegaHatRatio * ET1 + 6 * omega2 * delta2OmegaHatRatio * ET12 - 4 * omega1 * sqrt_delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET1 + delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET12 );
        resid = [ sZ3 - Z3; sZ4 - Z4 ];
    end
    
end
