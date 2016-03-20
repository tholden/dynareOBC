function [ Vnew, Xnew, PP, BS, VS, Verr, Xerr ] = IterateValueFunction( V, X, BS, XB, W, Bv, Av, beta, Ybar, R, UseTightBounds )
    nB = length( Bv );
    nA = length( Av );
    VOverallMax = max( max( V ) );
    PP = pchip( Bv, V );
    Vopt = coder.nullcopy( V );
    Xopt = coder.nullcopy( X );
    VS = coder.nullcopy( BS );
    parfor iA = 1 : nA
        A = Av( iA );
        Wv = W( :, iA );
        [ BS( iA ), VS( iA ) ] = GoldenSectionBMaximise( Bv( 1 ), BS( iA ), Bv( end ), A, Wv, Bv, PP, VOverallMax, beta, Ybar, R ); %#ok<PFBNS>
        for iB = 1 : nB
            B = Bv( iB );
            XL = 0;
            XU = XB( iA, iB );
            if UseTightBounds
                if iA > 1
                    XL = max( XL, X( iA - 1, iB ) );
                end
                if iB > 1
                    XL = max( XL, X( iA, iB - 1 ) );
                end
                if iA < nA
                    XU = min( XU, X( iA + 1, iB ) );
                end
                if iB < nB
                    XU = min( XU, X( iA, iB + 1 ) );
                end
            end
            XU = max( XL, XU );
            [ Vopt( iA, iB ), Xopt( iA, iB ) ] = EvaluateValueFunctionAtPoint( B, A, BS( iA ), VS( iA ), Wv, Bv, PP, VOverallMax, XL, X( iA, iB ), XU, beta, Ybar, R ); %#ok<PFBNS>
        end
    end
    Xnew = MakeIncreasing( Xopt );
    Xerr = max( max( abs( Xnew - Xopt ) ) );
    Vnew = MakeIncreasing( Vopt );
%     while true
%         Vold = Vnew;
%         Vnew = MakeIncreasing( cumsum( [ Vnew( :, 1 ), -MakeIncreasing( -diff( Vnew, 1, 2 ) ) ], 2 ) );
%         if max( max( abs( Vnew - Vold ) ) ) < eps
%             break;
%         end
%     end
    Verr = max( max( abs( Vnew - Vopt ) ) );
end

function Z = MakeIncreasing( Z )
    Z = 0.5 * ( cummax( cummax( Z, 2, 'forward' ), 1, 'forward' ) + cummin( cummin( Z, 2, 'reverse' ), 1, 'reverse' ) );
end

function [ x, fx ] = GoldenSectionBMaximise( a, g, b, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R )
    gr = 0.618033988749894848204586834365638117720;

    if a >= b
        x = a;
        fx = BMaximand( a, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        return;
    end
    
    g = max( a, min( b, g ) );
    
    x = g;
    fx = BMaximand( g, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    
    fa = BMaximand( a, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    fb = BMaximand( b, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
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
    fc = BMaximand( c, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
    fd = BMaximand( d, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
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
            fc = BMaximand( c, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
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
            fd = BMaximand( d, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
        end
        if a >= c || c >= d || d >= b
            break;
        end
    end
end

function Vout = BMaximand( B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R )
    Vout = XMaximand( 1, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R );
end
