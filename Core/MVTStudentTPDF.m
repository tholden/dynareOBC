function [ y, log_y ] = MVTStudentTPDF( x, nu )

    assert( numel( nu ) == 1 );
    assert( nu > 0 );
    
    x = x(:);
    
    D = length( x );
    HD = 0.5 * D;
    fHD = floor( HD );
    
    if isfinite( nu )
        nuPDO2 = 0.5 * ( nu + D );
        logGammaRatio = sum( log( 0.5 * nu + ( 0 : ( fHD - 1 ) ) ) );
        if HD ~= fHD
            fnu = nu + D - 1;
            if fnu > 20
                ifnu = 1 ./ fnu;
                ifnu2 = ifnu .* ifnu;
                ifnu4 = ifnu2 .* ifnu2;
                ifnu6 = ifnu4 .* ifnu2;
                ifnu8 = ifnu4 .* ifnu4;
                ifnu10 = ifnu6 .* ifnu4;
                ifnu12 = ifnu6 .* ifnu6;
                ifnu14 = ifnu8 .* ifnu6;
                ifnu16 = ifnu8 .* ifnu8;
                logGammaRatio = logGammaRatio + 0.5 * log( fnu ) -.346573590279972655 - ifnu .* ( ...
                    .250000000000000000 + 0.416666666666666667e-1.*ifnu2 - 0.500000000000000000e-1.*ifnu4 + .151785714285714286.*ifnu6 - .861111111111111111.*ifnu8 + 7.85227272727272727.*ifnu10 - 105.019230769230769.*ifnu12 + 1936.60208333333333.*ifnu14 - 47092.5147058823529.*ifnu16 ...
                );
            else
                logGammaRatio = logGammaRatio + gammaln( nuPDO2 ) - gammaln( 0.5 * fnu );
            end
        end
        log_y = logGammaRatio - HD * log( nu ) - HD * 1.14472988584940017 - nuPDO2 .* log1p( ( x' * x ) ./ nu );
    else
        log_y = - 0.5 * ( x' * x ) - 0.5 * D * 1.83787706640934548;
    end
    
    y = exp( log_y );

end
