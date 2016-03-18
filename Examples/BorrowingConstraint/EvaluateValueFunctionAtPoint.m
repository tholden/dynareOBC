function [ Vnew, Xnew ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, XL, XU, beta, Ybar, R )
    nB = length( Bv );
    
    [ Xnew, Vnew ] = GoldenSectionMaximise( XL, XU, B, A, Wv, Bv, V, beta, Ybar, R, nB );
end

function [ x, fx ] = GoldenSectionMaximise( a, b, B, A, Wv, Bv, V, beta, Ybar, R, nB )
    gr = 0.618033988749894848204586834365638117720;

    if a >= b
        x = a;
        fx = Maximand( a, B, A, Wv, Bv, V, beta, Ybar, R, nB );
        return;
    end
    
    fa = Maximand( a, B, A, Wv, Bv, V, beta, Ybar, R, nB );
    fb = Maximand( b, B, A, Wv, Bv, V, beta, Ybar, R, nB );
    if fb > fa
        x = b;
        fx = fb;
    else
        x = a;
        fx = fa;
    end
    
    c = b - gr * ( b - a );
    d = a + gr * ( b - a );
    fc = Maximand( c, B, A, Wv, Bv, V, beta, Ybar, R, nB );
    fd = Maximand( d, B, A, Wv, Bv, V, beta, Ybar, R, nB );
    while true
        if fc >= fd
            if fc > fx
                x = c;
                fx = fc;
            end
            b = d;
            d = c;
            fd = fc;
            c = b - gr * ( b - a );
            fc = Maximand( c, B, A, Wv, Bv, V, beta, Ybar, R, nB );
        else
            if fd > fx
                x = d;
                fx = fd;
            end
            a = c;
            c = d;
            fc = fd;
            d = a + gr * ( b - a );
            fd = Maximand( d, B, A, Wv, Bv, V, beta, Ybar, R, nB );
        end
        if a >= c || c >= d || d >= b
            break;
        end
    end
end

function V = Maximand( X, B, A, Wv, Bv, V, beta, Ybar, R, nB )
    OmC = max( 0, 1 - X );
    phi = R - 1;
    BNew = max( Ybar, A ) + R * B - X;
    BNew = max( Bv( 1 ), min( Bv( end ), BNew ) );
    V = min( 0, -0.5 * OmC * OmC - 0.5 * phi * BNew * BNew + beta * ExpectedV( BNew, V, Wv, Bv, nB ) );
end

function EV = ExpectedV( BNew, V, Wv, Bv, nB )
    if ~isnan( BNew )
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
