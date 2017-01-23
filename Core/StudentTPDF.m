function [ y, log_y ] = StudentTPDF( x, nu )

    % To see why we do not use the MATLAB function, try plot( tpdf( 0, exp( 0:1:300 ) ) ) and plot( tpdf( 0, exp( 0:1:1000 ) ) )

    assert( numel( nu ) == 1 );
    assert( nu > 0 );

    log_y = zeros( size( x ) );
    
    if isfinite( nu )
        nuP1O2 = 0.5 * ( nu + 1 );
        if nu > 20
            inu = 1 ./ nu;
            inu2 = inu .* inu;
            inu4 = inu2 .* inu2;
            inu6 = inu4 .* inu2;
            inu8 = inu4 .* inu4;
            inu10 = inu6 .* inu4;
            inu12 = inu6 .* inu6;
            inu14 = inu8 .* inu6;
            inu16 = inu8 .* inu8;
            logGammaRootNuRatio = -.346573590279972655 - inu .* ( ...
                .250000000000000000 + 0.416666666666666667e-1.*inu2 - 0.500000000000000000e-1.*inu4 + .151785714285714286.*inu6 - .861111111111111111.*inu8 + 7.85227272727272727.*inu10 - 105.019230769230769.*inu12 + 1936.60208333333333.*inu14 - 47092.5147058823529.*inu16 ...
            );
        else
            logGammaRootNuRatio = gammaln( nuP1O2 ) - gammaln( 0.5 * nu ) - 0.5 * log( nu );
        end
        log_y = logGammaRootNuRatio - 0.572364942924700085 - nuP1O2 .* log1p( x .^ 2 ./ nu );
    else
        log_y( idxNuNonFinite ) = - 0.5 * x .^ 2 - 0.918938533204672742;
    end
    
    y = exp( log_y );

end
