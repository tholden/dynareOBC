function [ X, Norm ] = SparseLyapunovSymm( A, B )
% Solves the Lyapunov equation X = A*X*A' + B, for B and X symmetric matrices.

    X = B;
    APower = A;

    for i = 1 : ( 10 + size( B, 1 ) * size( B, 1 ) )
        XOld = X;
        
        X = APower * X * APower' + X;
        X( abs(X) < eps ) = 0;
        
        APower = APower * APower;
        APower( abs(APower) < eps ) = 0;
        
        if ( norm( X - XOld, Inf ) < eps ) || all( APower(:) == 0 )
            % disp( i );
            break;
        end
    end
    
    Norm = norm( A*X*A' + B - X, Inf ) / norm( B, Inf );
    
    if Norm > sqrt( eps )
        X = lyapunov_symm( A, B, 1+1e-6, 1e-15 );
        X = spsparse( X );
        Norm = norm( A*X*A' + B - X, Inf ) / norm( B, Inf );
    end

end

