function [ V, X, PP, BS, VS, XB, Bv, Av, beta, mu, rho, sigma, Ybar, R ] = GlobalSolution

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
    Bmax = 7.5; % ( 1 - Ybar ) / ( R - 1 );

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
    
    BS = ones( size( Av ) ) * ( 0.5 * ( Bv( 1 ) + Bv( end ) ) );
    
    assert( all( size( V ) == size( Bg ) ) );
    assert( all( size( X ) == size( Bg ) ) );

    fprintf( '\n' );
    Iter = int32( 0 );
    e1o = Inf;
    if ~coder.target( 'MATLAB' )
        coder.cinclude( 'fflushStdOut.h' );
        coder.ceval( 'fflushStdOut', int32( 0 ) );
    end
    while true
        [ Vnew, Xnew, PP, BS, VS, e3, e6 ] = IterateValueFunction( V, X, BS, XB, W, Bv, Av, beta, Ybar, R, Iter > 10 );
        tmp = abs( V - Vnew );
        tmp = tmp(:);
        e1 = max( tmp );
        e2 = mean( tmp );
        tmp = abs( X - Xnew );
        tmp = tmp(:);
        e4 = max( tmp );
        e5 = mean( tmp );
        Iter = Iter + int32( 1 );
        fprintf( '%d %.15g %.15g %.15g %.15g %.15g %.15g\n', Iter, e1, e2, e3, e4, e5, e6 );
        if ~coder.target( 'MATLAB' )
            coder.ceval( 'fflushStdOut', int32( 0 ) );
        end
        drawnow update;
        if e1 >= e1o
            break;
        end
        e1o = e1;
        V = Vnew;
        X = Xnew;
    end

end
