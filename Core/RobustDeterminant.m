function [ DetA, LB, UB ] = RobustDeterminant( A )

    n = min( size( A, 1 ), size( A, 2 ) );
    A = A( 1:n, 1:n );

    [ L, U, P ] = lu( A );
    DetP = det( P );
    if DetP > 0
        DetA = prod( diag( U ) );
    elseif DetP < 0
        DetA = -prod( diag( U ) );
    else
        DetA = NaN;
    end
    
    a = max( abs( A(:) ) );
    l = max( abs( L(:) ) );
    u = max( abs( U(:) ) );
    eA = ( a + n * l * u ) * eps;
    A1 = norm( A, 1 );
    AInf = norm( A, Inf );
    Aq = min( [ A1, AInf, sqrt( A1 * AInf ) ] );
    ed = ( Aq + n * eA ) ^ ( n - 1 ) * n * n * eA;
    LB = DetA - ed;
    UB = DetA + ed;
    
    if LB < 0 && UB > 0
        k = rank( A );
        if k < n
            DetA = 0;
        end
    end
    
end
