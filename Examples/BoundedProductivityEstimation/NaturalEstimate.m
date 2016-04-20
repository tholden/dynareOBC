function gBarHat = NaturalEstimate( rObs, gamma, rho, sigma )
    min_r = min( rObs );
    mean_r = mean( rObs );
    mean_r_minus_min_r = mean_r - min_r;
    soln = fsolve( @( in ) GetResid( in, mean_r_minus_min_r, gamma, rho, sigma ), [ 0.005; log( sigma / sqrt( 1 - rho ^ 2 ) ) ], optimoptions( @fsolve, 'display', 'iter' ) );
    gBarHat = soln( 1 );
end

function resid = GetResid( in, mean_r_minus_min_r, gamma, rho, sigma )
    gBar = in( 1 );
    psi = mean_r_minus_min_r / gamma / rho;
    omega = exp( in( 2 ) );
    psiTilde = ( 1 -rho ) * gBar + rho * psi;
    omegaTilde = sqrt( rho^2 * omega^2 + sigma ^ 2 );
    ratio = psiTilde / omegaTilde;
    resid( 1 ) = normcdf( ratio ) * psiTilde + omegaTilde * normpdf( ratio ) - psi;
    resid( 2 ) = psiTilde ^ 2 * normcdf( ratio ) * ( 1 - normcdf( ratio ) ) + omegaTilde ^ 2 * ( normcdf( ratio ) - normpdf( ratio ) ^ 2 ) + psiTilde * omegaTilde * normpdf( ratio ) * ( 1 - 2 * normcdf( ratio ) ) - omega^2;
end
