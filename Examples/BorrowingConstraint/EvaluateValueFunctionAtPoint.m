function [ Vnew, Cnew ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, CB, Vmin, beta, Ybar, R )
    nB = length( Bv );
    
    [ Cnew, Vnew ] = GoldenSectionMaximise( 0, CB, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
end

function [ x, fx ] = GoldenSectionMaximise( a, b, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB )
    gr = 0.618033988749894848204586834365638117720;

    fa = Maximand( a, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
    fb = Maximand( b, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
    if fb > fa
        x = b;
        fx = fb;
    else
        x = a;
        fx = fa;
    end
    
    c = b - gr * ( b - a );
    d = a + gr * ( b - a );
    fc = Maximand( c, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
    fd = Maximand( d, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
    while true
        if fc > fd
            if fc > fx
                x = c;
                fx = fc;
            end
            b = d;
            d = c;
            fd = fc;
            c = b - gr * ( b - a );
            fc = Maximand( c, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
        else
            if fd > fx
                x = d;
                fx = fd;
            end
            a = c;
            c = d;
            fc = fd;
            d = a + gr * ( b - a );
            fd = Maximand( d, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB );
        end
        if a >= c || c >= d || d >= b
            break;
        end
    end
end

function V = Maximand( C, B, A, Wv, Bv, V, Vmin, beta, Ybar, R, nB )
    OmC = 1 - C;
    V = -0.5 * OmC * OmC + beta * ExpectedV( max( Ybar, A ) + R * B - C, V, Wv, Bv, nB );
    V = max( Vmin, min( 0, V ) );
end

function EV = ExpectedV( BNew, V, Wv, Bv, nB )
    if ~isnan( BNew )
        BNew = max( Bv( 1 ), min( Bv( end ), BNew ) );
        Index = 1 + ( nB - 1 ) * ( BNew - Bv( 1 ) ) / ( Bv( end ) - Bv( 1 ) );
        lIndex = min( nB - 1, floor( Index ) );
        uIndex = lIndex + 1;
        fIndex = Index - lIndex;
        Vv = ( 1 - fIndex ) * V( :, lIndex ) + fIndex * V( :, uIndex );
        EV = Wv' * Vv;
    else
        EV = -Inf;
    end
end
