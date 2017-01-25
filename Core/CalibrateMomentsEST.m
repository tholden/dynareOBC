function [ resid, xi, delta, cholOmega ] = CalibrateMomentsEST( tau, nu, mu, lambda, cholSigma, sZ3, sZ4 )

    tcdf_tau_nu = StudentTCDF( tau, nu );
    
    resid = zeros( 0, 1 );
    
    if tcdf_tau_nu == 0
        Z3 = 0;
        if isfinite( nu )
            Z4 = ( 3 * nu - 6 ) / ( nu - 4 );
        else
            Z4 = 3;
        end
        if ~isempty( sZ3 )
            resid = [ resid; sZ3 - Z3 ];
        end
        if ~isempty( sZ4 )
            resid = [ resid; sZ4 - Z4 ];
        end
        if nargout > 1
            xi = mu;
            delta = zeros( size( mu ) );
            cholOmega = cholSigma;
            if isfinite( nu )
                cholOmega = cholOmega * sqrt( ( nu - 2 ) / nu );
            end
        end
        return;
    end

    tauTtau = tau * tau;
    OPtauTtauDnu = 1 + tauTtau / nu;
    
    if isfinite( nu )
        nuOnuM1 = nu / ( nu - 1 );
        nuOnuM2 = nu / ( nu - 2 );
        nuOnuM3 = nu / ( nu - 3 );
    else
        nuOnuM1 = 1;
        nuOnuM2 = 1;
        nuOnuM3 = 1;
    end
    
    tau2 = tau / sqrt( nuOnuM2 );
    nuTnu = nu * nu;
    
    tpdfRatio = StudentTPDF( tau, nu ) / tcdf_tau_nu;
    MedT = tinv( 1 - 0.5 * tcdf_tau_nu, nu );
    
    ET1 = nuOnuM1 * OPtauTtauDnu * tpdfRatio;
    ET2 = nuOnuM2 * StudentTCDF( tau2, nu - 2 ) / tcdf_tau_nu - tau * ET1;
    ET3 = 2 * nuOnuM1 * nuOnuM3 * OPtauTtauDnu * OPtauTtauDnu * tpdfRatio + tauTtau * ET1;
    
    delta = ( mu - lambda ) / ( ET1 - MedT );
    
    if nargout > 1
        xi = mu - delta * ET1;
    end
    delta_deltaT = delta * delta';
    ET12 = ET1 * ET1;
    
    if isfinite( nu )
        OmegaScaleRatio = ( nu - 1 ) / ( nu + ET2 );
    else
        OmegaScaleRatio = 1;
    end
    
    if ET2 < ET12
        cholOmega = sqrt( OmegaScaleRatio ) * cholupdate( cholSigma, sqrt( ET12 - ET2 ) * delta );
    else
        [ cholOmega, p ] = cholupdate( cholSigma, sqrt( ET2 - ET12 ) * delta, '-' );
        if p == 0
            cholOmega = cholOmega * sqrt( OmegaScaleRatio );
        else
            [ ~, cholOmega ] = NearestSPD( OmegaScaleRatio * ( cholSigma' * cholSigma - ( ET2 - ET12 ) * delta_deltaT ) );
        end
    end
    
    if isempty( sZ3 ) && isempty( sZ4 )
        return;
    end
    
    cholOmegaCheck = cholupdate( cholOmega, delta );
    
    deltaT_delta = delta' * delta;
    deltaT_delta2 = deltaT_delta * deltaT_delta;
    cholOmegaHat_delta = cholOmegaCheck * delta;
    deltaT_OmegaHat_delta = cholOmegaHat_delta' * cholOmegaHat_delta;
    cholSigma_delta = cholSigma * delta;
    deltaT_Sigma_delta = cholSigma_delta' * cholSigma_delta;
    sqrt_deltaT_OmegaHat_delta = sqrt( deltaT_OmegaHat_delta );
    OmegaHatSigmaRatio = deltaT_OmegaHat_delta / deltaT_Sigma_delta;
    sqrt_delta2OmegaHatRatio = deltaT_delta / sqrt_deltaT_OmegaHat_delta;
    delta2OmegaHatRatio = sqrt_delta2OmegaHatRatio * sqrt_delta2OmegaHatRatio;
    
    omega1 = sqrt_delta2OmegaHatRatio * ET1;
    omega2 = ( deltaT_Sigma_delta + deltaT_delta2 * ET12 ) / deltaT_OmegaHat_delta;
    OMdelta2OmegaHatRatio = 1 - delta2OmegaHatRatio;
    omega3 = 3 * nuOnuM1 * sqrt_delta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( ET1 + ET3 / nu ) + delta2OmegaHatRatio * sqrt_delta2OmegaHatRatio * ET3;

    if ~isempty( sZ3 )
        Z3 = OmegaHatSigmaRatio * sqrt( OmegaHatSigmaRatio ) * ( omega3 - 3 * omega2 * sqrt_delta2OmegaHatRatio * ET1 + 3 * omega1 * delta2OmegaHatRatio * ET12 - sqrt_delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET1 );
        resid = [ resid; sZ3 - Z3 ];
    end
    
    if ~isempty( sZ4 )
        if isfinite( nu )
            nuOnuM4 = nu / ( nu - 4 );
        else
            nuOnuM4 = 1;
        end
        tau4 = tau / sqrt( nuOnuM4 );
        if tcdf_tau_nu > 0
            ET4 = 3 * nuOnuM2 * nuOnuM4 * StudentTCDF( tau4, nu - 4 ) / tcdf_tau_nu - 1.5 * tau * ET3 + 0.5 * tauTtau * tau * ET1;
        else
            ET4 = 3 * nuOnuM2 * nuOnuM4;
        end
        omega4 = 3 * nuOnuM1 * nuOnuM3 * OMdelta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( 1 + 2 / nu * ET2 + ET4 / nuTnu ) + 6 * nuOnuM1 * delta2OmegaHatRatio * OMdelta2OmegaHatRatio * ( ET2 + ET4 / nu ) + delta2OmegaHatRatio * delta2OmegaHatRatio * ET4;
        Z4 = OmegaHatSigmaRatio * OmegaHatSigmaRatio * ( omega4 - 4 * omega3 * sqrt_delta2OmegaHatRatio * ET1 + 6 * omega2 * delta2OmegaHatRatio * ET12 - 4 * omega1 * sqrt_delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET1 + delta2OmegaHatRatio * delta2OmegaHatRatio * ET12 * ET12 );
        resid = [ resid; sZ4 - Z4 ];
    end
    
end
