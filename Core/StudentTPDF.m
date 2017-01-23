function y = StudentTPDF( x, nu )

    % To see why we do not use the MATLAB function, try plot( tpdf( 0, exp( 0:1:300 ) ) ) and plot( tpdf( 0, exp( 0:1:1000 ) ) )

    assert( all( nu > 0 ) );
    assert( numel( x ) == 1 || numel( nu ) == 1 || all( size( x ) == size( nu ) ) );

    y = zeros( max( size( x ), size( nu ) ) );

    selNuFinite = isfinite( nu );
    idxNuFinite = find( selNuFinite );
    if ~isempty( idxNuFinite )
        nuFinite = nu( idxNuFinite );
        nuP1O2Finite = 0.5 * ( nuFinite + 1 );
        if numel( x ) > 1
            xFinite = x( idxNuFinite );
        else
            xFinite = x;
        end
        logGammaRootNuRatio = zeros( size( nuFinite ) );
        inu = 1 ./ nuFinite( nuFinite > 20 );
        inu2 = inu .* inu;
        inu4 = inu2 .* inu2;
        inu6 = inu4 .* inu2;
        inu8 = inu4 .* inu4;
        inu10 = inu6 .* inu4;
        inu12 = inu6 .* inu6;
        inu14 = inu8 .* inu6;
        inu16 = inu8 .* inu8;
        logGammaRootNuRatio( nuFinite > 20 ) = -.346573590279972655 - inu .* ( ...
            .250000000000000000 + 0.416666666666666667e-1.*inu2 - 0.500000000000000000e-1.*inu4 + .151785714285714286.*inu6 - .861111111111111111.*inu8 + 7.85227272727272727.*inu10 - 105.019230769230769.*inu12 + 1936.60208333333333.*inu14 - 47092.5147058823529.*inu16 ...
        );
        idxSmallNu = find( nuFinite <= 20 );
        logGammaRootNuRatio( idxSmallNu ) = gammaln( nuP1O2Finite( idxSmallNu ) ) - gammaln( 0.5 * nuFinite( idxSmallNu ) ) - 0.5 * log( nuFinite( idxSmallNu ) );
        y( idxNuFinite ) = exp( logGammaRootNuRatio - 0.5 * log( pi ) - nuP1O2Finite .* log1p( xFinite .^ 2 ./ nuFinite ) );
    end

    idxNuNonFinite = find( ~selNuFinite );
    if ~isempty( idxNuNonFinite )
        if numel( x ) > 1
            xNonFinite = x( idxNuNonFinite );
        else
            xNonFinite = x;
        end
        y( idxNuNonFinite ) = normpdf( xNonFinite, 0, 1 );
    end

end
