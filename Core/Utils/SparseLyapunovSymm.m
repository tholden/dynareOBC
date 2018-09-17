function [ X, Norm ] = SparseLyapunovSymm( ATrans, B )
% Solves the Lyapunov equation X = ATrans.'*X*ATrans + B, for B and X symmetric matrices.

    if isempty( B )
        B = zeros( size( ATrans, 1 ) );
    end

    X = B;
    APowerTrans = ATrans;

    for i = 1 : ( 10 + size( B, 1 ) * size( B, 1 ) )
        XOld = X;
        
        X = APowerTrans.' * X * APowerTrans + X;
        X( abs(X) < eps ) = 0;
        
        APowerTrans = APowerTrans * APowerTrans;
        APowerTrans( abs( APowerTrans ) < eps ) = 0;
        
        if ( norm( X - XOld, Inf ) < eps ) || all( APowerTrans(:) == 0 )
            % disp( i );
            break;
        end
    end
    
    Norm = norm( ATrans.'*X*ATrans + B - X, Inf ) / norm( B, Inf );
    
    if Norm > sqrt( eps )
        X = lyapunov_symm( full( ATrans.' ), full( B ), 1+1e-6, 1e-12, 1e-15 );
        X = spsparse( X );
        Norm = norm( ATrans.'*X*ATrans + B - X, Inf ) / norm( B, Inf );
    end

end

