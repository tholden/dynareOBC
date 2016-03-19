function [ V, X, XB, Bv, Av, beta, mu, rho, sigma, Ybar, R ] = GlobalSolution

	beta = 0.99;
	mu = 0.5;
	rho = 0.95;
	sigma = 0.05;
	Ybar = 0.25;
	R = 1 / beta;
    % phi = R - 1;

    nA = 256;
    nB = 4 * nA;
    wA = 4;
    
    MaxBorrowing = Ybar / ( R - 1 );
    
    Bmin = -MaxBorrowing;   
    Bmax = ( 1 - Ybar ) / ( R - 1 );

	std_A = sigma / sqrt( 1 - rho^2 );

    Bv = Bmin : ( ( Bmax - Bmin ) / ( nB - 1 ) ) : Bmax;
    Av = ( mu - wA * std_A ) : ( 2 * wA * std_A / ( nA - 1 ) ) : ( mu + wA * std_A );

    Aoffset = ( 1 - rho ) * mu;
    
    W = zeros( nA, nA );
    parfor i = 1 : nA
        W( :, i ) = GeneratePiecewiseLinearCubatureRule( Av, Aoffset + rho * Av( i ), sigma );
    end

    [ V, X ] = ValueAndPolicyFunctionsNoBounds( Av, Bv, beta, mu, rho, sigma );
    
    [ Bg, Ag ] = meshgrid( Bv, Av );
    
    XB = max( 0, max( Ybar, Ag ) + R * Bg + Ybar / ( R - 1 ) );
    
    assert( all( size( V ) == size( Bg ) ) );
    assert( all( size( X ) == size( Bg ) ) );

    fprintf( '\n' );
    Iter = int32( 0 );
    e1o = Inf;
    while true
        [ Vnew, Xnew, e2 ] = IterateValueFunction( V, X, XB, W, Bv, Av, beta, Ybar, R, Iter > 20 );
        e1 = max( max( abs( V - Vnew ) ) );
        tmp = abs( X - Xnew );
        tmp = tmp(:);
        [ e3, ind ] = max( tmp );
        e4 = mean( mean( abs( X - Xnew ) ) );
        [ sub1, sub2 ] = ind2sub( size( X ), ind );
        Iter = Iter + int32( 1 );
        fprintf( '%d %.15g %.15g %.15g %.15g %d %d\n', Iter, e1, e2, e3, e4, int32( sub1 ), int32( sub2 ) );
        coder.ceval( 'fflush', uint32( 1 ) );
        if e1 >= e1o % && ( e1 < 1e-6 && e2 < 1e-6 )
            break;
        end
        e1o = e1;
        V = Vnew;
        X = Xnew;
    end

end
