function [ V, C, CB, kv, av, beta, mu, rho, sigma, Ybar, R ] = GlobalSolution

	beta = 0.99;
	mu = 0.5;
	rho = 0.95;
	sigma = 0.05;
	Ybar = 0.25;
	R = 1.01;

    nA = 256;
    nB = 4 * nA;
    wA = 4;
 
    A_ = mu;
    B_ = -Ybar / ( R - 1 );
    C_ = mu - Ybar;
    
    Bbliss = ( 1 - Ybar ) / ( R - 1 );

	std_A = sigma / sqrt( 1 - rho^2 );

    Bv = B_ : ( ( Bbliss - B_ ) / ( nB - 1 ) ) : Bbliss;
    Av = ( - wA * std_A ) : ( 2 * wA * std_A / ( nA - 1 ) ) : ( wA * std_A );

    W = zeros( nA, nA );
    parfor i = 1 : nA
        W( :, i ) = GeneratePiecewiseLinearCubatureRule( av, rho * av( i ), sigma );
    end

    [ kg, ag ] = meshgrid( kv, av );

    F = log( 1 - alpha * beta ) / ( 1 - beta ) + ( 1 - alpha ) / ( ( 1 - alpha * beta ) * ( 1 - beta ) * ( 1 + nu ) ) * ( log ( ( 1 - alpha ) / ( 1 - alpha * beta ) ) - 1 ) + alpha * beta * log( alpha * beta ) / ( ( 1 - alpha * beta ) * ( 1 - beta ) );
    G = alpha / ( 1 - alpha * beta );
    H = 1 / ( ( 1 - alpha * beta ) * ( 1 - beta * rho ) );

    V = F + G * kg + H * ag;
    Y = exp( ag + alpha * kg ) * ( ( 1 - alpha ) / ( 1 - alpha * beta ) ) .^ ( ( 1 - alpha ) / ( 1 + nu ) );
    C = ( 1 - alpha * beta ) * Y;
    CB = ( exp( ( 1 + nu ) * ( ag + alpha * kg ) ) * ( 1 - alpha ) ^ ( 1 - alpha ) ) .^ ( 1 / ( 1 + nu ) );

    fprintf( '\n' );
    Iter = int32( 0 );
    e1o = Inf;
    while true
        thetac = min( theta, double( Iter ) / 200 );
        [ Vnew, Cnew, CBnew ] = IterateValueFunction( V, C, CB, W, kv, av, alpha, beta, nu, thetac );
        e1 = max( max( abs( V - Vnew ) ) );
        e2 = max( max( abs( C - Cnew ) ) );
        e3 = max( max( abs( CB - CBnew ) ) );
        Iter = Iter + int32( 1 );
        fprintf( '%d %.15g %.15g %.15g %.15g\n', Iter, thetac, e1, e2, e3 );
        if thetac == theta
            if e1 >= e1o % && ( e1 < 1e-6 && e2 < 1e-6 && e3 < 1e-6 )
                break;
            end
            e1o = e1;
        end
        V = Vnew;
        C = Cnew;
        CB = CBnew;
    end

end
