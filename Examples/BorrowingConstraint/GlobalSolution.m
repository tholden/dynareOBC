function [ V, C, CB, Bv, Av, beta, mu, rho, sigma, Ybar, R ] = GlobalSolution

	beta = 0.99;
	mu = 0.5;
	rho = 0.95;
	sigma = 0.05;
	Ybar = 0.25;
	R = 1.01;

    nA = 256;
    nB = 4 * nA;
    wA = 4;
    
    MaxBorrowing = Ybar / ( R - 1 );
    
    Vmin = -1 / ( 2 * ( 1 - beta ) );
 
    % A_ = mu;
    Bmin = -MaxBorrowing;
    % C_ = mu - Ybar;
    
    Bmax = ( 1 - Ybar ) / ( R - 1 );

	std_A = sigma / sqrt( 1 - rho^2 );

    Bv = Bmin : ( ( Bmax - Bmin ) / ( nB - 1 ) ) : Bmax;
    Av = ( - wA * std_A ) : ( 2 * wA * std_A / ( nA - 1 ) ) : ( wA * std_A );

    W = zeros( nA, nA );
    parfor i = 1 : nA
        W( :, i ) = GeneratePiecewiseLinearCubatureRule( Av, rho * Av( i ), sigma );
    end

    Vtmp = max( Vmin, min( 0, ValueFunctionAlwaysAtBorrowingConstraint( Av, beta, mu, rho, sigma, Ybar ) ) );
    
    V = bsxfun( @times, Vtmp, 1:(-1/(nB-1)):0 );
    
    [ Bg, Ag ] = meshgrid( Bv, Av );
    
    assert( all( size( V ) == size( Bg ) ) );

    C = max( 0, min( 1, max( Ybar, Ag ) + MaxBorrowing + R * Bg ) );
    CB = C;
 
    fprintf( '\n' );
    Iter = int32( 0 );
    e1o = Inf;
    while true
        [ Vnew, Cnew ] = IterateValueFunction( V, C, CB, W, Bv, Av, Vmin, beta, Ybar, R );
        e1 = max( max( abs( V - Vnew ) ) );
        e2 = max( max( abs( C - Cnew ) ) );
        Iter = Iter + int32( 1 );
        fprintf( '%d %.15g %.15g %.15g %.15g\n', Iter, thetac, e1, e2 );
        if e1 >= e1o % && ( e1 < 1e-6 && e2 < 1e-6 )
            break;
        end
        e1o = e1;
        V = Vnew;
        C = Cnew;
    end

end
