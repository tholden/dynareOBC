function [ Vnew, Xnew ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, PP, VOverallMax, XL, XG, XU, beta, Ybar, R )
    [ Xnew, Vnew ] = GoldenSectionMaximise( XL, XG, XU, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
end

function [ x, fx ] = GoldenSectionMaximise( a, g, b, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R )
    gr = 0.618033988749894848204586834365638117720;

    if a >= b
        x = a;
        fx = Maximand( a, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        return;
    end
    
    g = max( a, min( b, g ) );
    
    x = g;
    fx = Maximand( g, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    
    fa = Maximand( a, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    fb = Maximand( b, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    if fb > fa
        if fb > fx
            x = b;
            fx = fb;
        end
    elseif fa < fb
        if fa > fx
            x = a;
            fx = fa;
        end
    else
        if fa > fx
            fx = fa;
            if abs( g - a ) <= abs( g - b )
                x = a;
            else
                x = b;
            end
        end
    end
    
    c = b - gr * ( b - a );
    d = a + gr * ( b - a );
    fc = Maximand( c, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    fd = Maximand( d, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    while true
        if fc > fd || ( fc == fd && abs( g - c ) <= abs( g - d ) )
            if fc > fx
                x = c;
                fx = fc;
            elseif fc == fx
                if abs( g - c ) < abs( g - x )
                    x = c;
                end
            end
            b = d;
            d = c;
            fd = fc;
            c = b - gr * ( b - a );
            fc = Maximand( c, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        else
            if fd > fx
                x = d;
                fx = fd;
            elseif fd == fx
                if abs( g - d ) < abs( g - x )
                    x = d;
                end
            end
            a = c;
            c = d;
            fc = fd;
            d = a + gr * ( b - a );
            fd = Maximand( d, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        end
        if a >= c || c >= d || d >= b
            break;
        end
    end
end

function Vout = Maximand( X, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R )
    OmC = max( 0, 1 - X );
    phi = R - 1;
    BNew = max( Ybar, A ) + R * B - X;
    if BNew < Bv( 1 )
        Vout = -Inf;
    else
        BNew = min( BNew, Bv( end ) );
        Vout = min( 0, -0.5 * OmC * OmC - 0.5 * phi * BNew * BNew + beta * min( VOverallMax, ExpectedV( BNew, PP, Wv ) ) );
    end
end

function EV = ExpectedV( BNew, PP, Wv )
    if ~isnan( BNew )
        Vv = ppval( PP, BNew );
        EV = Wv' * Vv;
    else
        EV = -Inf;
    end
end
