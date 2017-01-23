function [ resid, xi, delta, cholOmega ] = CalibrateMomentsEST( tau, nu, mu, lambda, cholSigma, sZ3, sZ4 )

    tcdf_tau_nu = tcdf( tau, nu );
    tpdfRatio = tpdf( tau, nu ) / tcdf_tau_nu;
    tauTtau = tau * tau;
    OPtauTtauDnu = 1 + tauTtau / nu;
    ET1 = nu / ( nu - 1 ) * OPtauTtauDnu * tpdfRatio;
    tau2 = tau * sqrt( ( nu - 2 ) / nu );
    ET2 = nu / ( nu - 2 ) * tcdf( tau2, nu - 2 ) / tcdf_tau_nu - tau * ET1;
    nuTnu = nu * nu;
    ET3 = 2 * nuTnu / ( ( nu - 1 ) * ( nu - 3 ) ) * OPtauTtauDnu * OPtauTtauDnu * tpdfRatio + tauTtau * ET1;
    
    MedT = tinv( 1 - 0.5 * tcdf_tau_nu, nu );
    
    delta = ( mu - lambda ) / ( ET1 - MedT );
    xi = mu - delta * ET1;
    delta_deltaT = delta * delta';
    ET12 = ET1 * ET1;
    
    if ET2 < ET12
        cholOmega = sqrt( ( nu - 1 ) / ( nu + ET2 ) ) * cholupdate( cholSigma, sqrt( ET12 - ET2 ) * delta );
    else
        [ cholOmega, p ] = cholupdate( cholSigma, sqrt( ET2 - ET12 ) * delta, '-' );
        if p == 0
            cholOmega = cholOmega * sqrt( ( nu - 1 ) / ( nu + ET2 ) );
        else
            [ ~, cholOmega ] = NearestSPD( ( ( nu - 1 ) / ( nu + ET2 ) ) * ( cholSigma' * cholSigma - ( ET2 - ET12 ) * delta_deltaT ) );
        end
    end
    cholOmegaHat = cholupdate( cholOmega, delta );
    
    deltaT_delta = delta' * delta;
    deltaT_delta2 = deltaT_delta * deltaT_delta;
    cholOmegaHat_delta = cholOmegaHat * delta;
    deltaT_OmegaHat_delta = cholOmegaHat_delta' * cholOmegaHat_delta;
    cholSigma_delta = cholSigma * delta;
    deltaT_Sigma_delta = cholSigma_delta' * cholSigma_delta;
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
        omega4 = 3 * nuTnu / ( ( nu - 1 ) * ( nu - 3 ) ) * OMdelta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( 1 + 2 / nu * ET2 + ET4 / nuTnu ) + 6 * nu / ( nu - 1 ) * delta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( ET2 + ET4 / nu ) + delta2OmegaHatRatio * delta2OmegaHatRatio * ET4;
        Z4 = OmegaHatSigmaRatio * OmegaHatSigmaRatio * ( omega4 - 4 * omega3 * sqrt_delta2OmegaHatRatio * ET1 + 6 * omega2 * delta2OmegaHatRatio * ET12 - 4 * omega1 * sqrt_delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET1 + delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET12 );
        resid = [ sZ3 - Z3; sZ4 - Z4 ];
    end
    
end
