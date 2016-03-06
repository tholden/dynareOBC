function w = GeneratePiecewiseLinearCubatureRule( x, mu, sigma )
    n = length( x );
    w = zeros( n, 1 );
    sqrt2 = sqrt( 2 );
    sqrtpi = sqrt( pi );
    invsqrtpi = 1 / sqrtpi;
    OD2sigma = 1 / ( 2 * sigma );
    OD2sigmaE2 = 1 / ( 2 * sigma * sigma );

    x1 = x( 1 );
    x2 = x( 2 );
    % expTerm_x1 = exp(-(-x1 + mu) ^ 2 * OD2sigmaE2);
    expTerm_x2 = exp(-(-x2 + mu) ^ 2 * OD2sigmaE2);
    % erfTerm_x1 = erf(sqrt2 * (-x1 + mu) * OD2sigma);
    erfTerm_x2 = erf(sqrt2 * (-x2 + mu) * OD2sigma);
    w( 1 ) = -invsqrtpi * (sqrt2 * expTerm_x2 * sigma + sqrtpi * (erfTerm_x2 - 1) * (-x2 + mu)) / ((2 * x1) - 2 * x2);
	w( 2 ) = invsqrtpi * (sqrt2 * expTerm_x2 * sigma + sqrtpi * (erfTerm_x2 - 1) * (-x1 + mu)) / (2 * x1 - 2 * x2);

    x1 = x( n - 1 );
    x2 = x( n );
    expTerm_x1 = exp(-(-x1 + mu) ^ 2 * OD2sigmaE2);
    % expTerm_x2 = exp(-(-x2 + mu) ^ 2 * OD2sigmaE2);
    erfTerm_x1 = erf(sqrt2 * (-x1 + mu) * OD2sigma);
    % erfTerm_x2 = erf(sqrt2 * (-x2 + mu) * OD2sigma);
    w( n - 1 ) = w( n - 1 ) + invsqrtpi * (sqrt2 * expTerm_x1 * sigma + sqrtpi * (erfTerm_x1 + 1) * (-x2 + mu)) / (2 * x1 - 2 * x2);
    w( n ) = w( n ) + -invsqrtpi * (sqrt2 * expTerm_x1 * sigma + sqrtpi * (erfTerm_x1 + 1) * (-x1 + mu)) / (2 * x1 - (2 * x2));
    
    for i = 2 : ( n - 2 )
        x1 = x( i );
        x2 = x( i + 1 );
        expTerm_x1 = exp(-(-x1 + mu) ^ 2 * OD2sigmaE2);
        expTerm_x2 = exp(-(-x2 + mu) ^ 2 * OD2sigmaE2);
        erfTerm_x1 = erf(sqrt2 * (-x1 + mu) * OD2sigma);
        erfTerm_x2 = erf(sqrt2 * (-x2 + mu) * OD2sigma);
        w( i ) = w( i ) + -(-sqrt2 * expTerm_x1 * sigma + sqrt2 * expTerm_x2 * sigma + sqrtpi * (-x2 + mu) * (erfTerm_x2 - erfTerm_x1)) * invsqrtpi / (2 * x1 - 2 * x2);
        w( i + 1 ) = w( i + 1 ) + (-sqrt2 * expTerm_x1 * sigma + sqrt2 * expTerm_x2 * sigma + sqrtpi * (-x1 + mu) * (erfTerm_x2 - erfTerm_x1)) * invsqrtpi / (2 * x1 - 2 * x2);
    end
    assert( abs( sum( w ) - 1 ) < sqrt( eps ) );
    w = w ./ sum( w );
end
