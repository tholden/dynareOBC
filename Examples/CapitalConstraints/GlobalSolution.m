function [ V, C, CB, W, kv, alpha, beta, nu, theta ] = GlobalSolution

    alpha = 0.3;
    beta = 0.99;
    nu = 2;
    theta = 0.99;
    rho = 0.95;
    sigma = 0.005;

    n = 1024;
    GridWidth = 4;

    k_ = 1 / ( 1 - alpha ) * ( log( alpha * beta ) + ( ( 1 - alpha ) / ( 1 + nu ) ) * log( ( 1 - alpha ) / ( 1 - alpha * beta ) ) );
    % y_ = alpha * k_ + ( ( 1 - alpha ) / ( 1 + nu ) ) * log( ( 1 - alpha ) / ( 1 - alpha * beta ) );
    % c_ = log( 1 - alpha * beta ) + y_;

    std_k = sigma * sqrt( ( 1 + alpha * rho ) / ( ( 1 - alpha ) * ( 1 + alpha ) * ( 1 - rho ) * ( 1 + rho ) * ( 1 - alpha * rho ) ) );

    kv = ( k_ - GridWidth * std_k ) : ( 2 * GridWidth * std_k / ( n - 1 ) ) : ( k_ + GridWidth * std_k );
    av = ( - GridWidth * sigma ) : ( 2 * GridWidth * sigma / ( n - 1 ) ) : ( GridWidth * sigma );

    W = zeros( n, n );
    parfor i = 1 : n
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
    while true
        thetac = min( theta, double( Iter ) / 100 );
        [ Vnew, Cnew, CBnew ] = IterateValueFunction( V, C, CB, W, kv, av, alpha, beta, nu, thetac );
        e1 = max( max( abs( V - Vnew ) ) );
        e2 = max( max( abs( C - Cnew ) ) );
        e3 = max( max( abs( CB - CBnew ) ) );
        Iter = Iter + int32( 1 );
        fprintf( '%d %.15g %.15g %.15g %.15g\n', Iter, thetac, e1, e2, e3 );
        V = Vnew;
        C = Cnew;
        CB = CBnew;
        if thetac == theta && e1 < sqrt( eps ) && e2 < sqrt( eps ) && e3 < sqrt( eps )
            break;
        end
    end

end
