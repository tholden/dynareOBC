function [ Vnew, Xnew ] = EvaluateValueFunctionAtPoint( B, A, BS, VS, Wv, Bv, PP, VOverallMax, XL, XG, XU, beta, Ybar, R )
    if B > BS
        Vnew = VS;
        Xnew = 1 + R * ( B - BS );
    else
        [ Xnew, Vnew ] = GoldenSectionXMaximise( XL, XG, min( 1, XU ), B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        Vnew = min( Vnew, VS );
    end
end

function [ x, fx ] = GoldenSectionXMaximise( a, g, b, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R )
    gr = 0.618033988749894848204586834365638117720;

    if a >= b
        x = a;
        fx = XMaximand( a, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        return;
    end
    
    g = max( a, min( b, g ) );
    
    x = g;
    fx = XMaximand( g, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    
    fa = XMaximand( a, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    fb = XMaximand( b, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    if fa < fb
        if fb > fx
            x = b;
            fx = fb;
        end
    elseif fa > fb
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
    fc = XMaximand( c, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    fd = XMaximand( d, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
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
            fc = XMaximand( c, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
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
            fd = XMaximand( d, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        end
        if a >= c || c >= d || d >= b
            break;
        end
    end
end
