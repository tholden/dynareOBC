function beta = GHWRidge( y, X )
% Golub Heath Wahba Ridge regression
% http://www.stat.wisc.edu/~wahba/ftp1/oldie/golub.heath.wahba.pdf
% note that formula 2.3 in the paper contains a typo. the n - p should be divided by n.
% X should not contain a column of 1s.

    mean_y = mean( y );
    if size( X, 2 ) == 0
        beta = mean_y;
        return;
    end
    mean_X = mean( X );
    std_X = std( X );
    
    X = bsxfun( @minus, X, mean_X );
    X = bsxfun( @rdivide, X, std_X );
    
    y = y(:) - mean_y;
    
    n = size( X, 1 );
    p = size( X, 2 );
    
    [ U, D, V ] = svd( X, 0 );
    
    z = U'*y;
    d = diag( D );
    d2 = d .* d;
    
    c1 = y' * y - z' * z;
    c2 = 1 - p / n;
    nInv = 1 / n;

    kappa = fminbnd( @(kappa) ObjectiveFast( kappa, z, d2, c1, c2, nInv ), 0, 1, optimset( 'Display', 'off' ) );
    lambda = 1 / ( 1 - kappa ) - 1;
    
%     lambda2 = fminbnd( @(lambda) ObjectiveSlow( lambda, y, X, n, p ), 0, 100, optimset( 'Display', 'off' ) );
%     disp( [lambda lambda2] );
%     figure( 1 ); ezplot( @(lambda) ObjectiveFast( 1 - 1 / ( 1 + lambda ), z, d2, c1, c2, nInv ), [0, 1] );
%     figure( 2 ); ezplot( @(lambda) ObjectiveSlow( lambda, y, X, n, p ), [0, 1] );
%     keyboard;
    
    b1 = V * ( d .* z ./ ( d2 + lambda ) );
    b1s = b1 ./ std_X';
    
    beta = [ mean_y - mean_X * b1s; b1s ];
    
end

% function Out = ObjectiveSlow( lambda, y, X, n, p )
%     A = ( X / ( X' * X + lambda * eye( p ) ) ) * X';
%     Out = ( 1 / n ) * ( norm( ( eye( n ) - A ) * y ).^2 ) / ( ( ( 1 / n ) * trace( eye( n ) - A ) ) .^ 2 );
% end

function Out = ObjectiveFast( kappa, z, d2, c1, c2, nInv )
    kappa = max( 0, min( 1, kappa ) );
    lambda = 1 / ( 1 - kappa ) - 1;
    T2 = lambda ./ ( d2 + lambda );
    T2( ~isfinite( T2 ) ) = 1;
    T1 = z .* T2;
    T1 = c1 + T1' * T1;
    T2 = c2 + nInv * sum( T2 );
    Out = nInv * T1 / ( T2 * T2 );
end
