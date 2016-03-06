function [ Vnew, Cnew, CBnew ] = EvaluateValueFunctionAtPoint( k, a, Wv, kv, V, CBg, alpha, beta, nu, theta )
    OMalpha = 1 - alpha;
    alphaPnu = alpha + nu;
    MOMalphaDalphaPnu = - OMalpha / alphaPnu;
    OPnu = 1 + nu;
    OPnuDalphaPnu = OPnu / alphaPnu;
    ODOPnu = 1 / OPnu;
    nk = length( kv );
    AKEalpha = exp( a + alpha * k );
    kNewCore = tpow( tpow( AKEalpha, OPnu ) * tpow( OMalpha, OMalpha ), 1 / alphaPnu );
    thetaK = theta * exp( k );
    
    CBnew = HalleySolveBound( CBg, kNewCore, MOMalphaDalphaPnu, thetaK );
       
    FCBnew = Maximand( CBnew, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    [ Cnew, Vnew ] = GoldenSectionMaximise( 0, CBnew, -Inf, FCBnew, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
end

function CBnew = HalleySolveBound( CBg, kNewCore, MOMalphaDalphaPnu, thetaK )
    ExitFlag = false;
    while true
        t0 = kNewCore * tpow( CBg, MOMalphaDalphaPnu );
        f0 = t0 - CBg - thetaK;
        t1 = MOMalphaDalphaPnu * t0 / CBg;
        f1 = t1 - 1;
        f2 = ( MOMalphaDalphaPnu - 1 ) * t1 / CBg;
        Offset = 2 * f0 * f1 / ( 2 * f1 * f1 - f0 * f2 );
        CBnew = max( 0.5 * CBg, CBg - Offset );
        if ( CBnew == CBg ) || ExitFlag
            return;
        end
        if abs( Offset ) <= 4 * min( eps( CBg ), eps( CBnew ) )
            ExitFlag = true;
        end
        CBg = CBnew;
    end
end

function [ x, fx ] = GoldenSectionMaximise( a, b, fa, fb, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk )
    gr = 0.618033988749894848204586834365638117720;

    if fb > fa
        x = b;
        fx = fb;
    else
        x = a;
        fx = fa;
    end
    
    c = b - gr * ( b - a );
    d = a + gr * ( b - a );
    fc = Maximand( c, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    fd = Maximand( d, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
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
            fc = Maximand( c, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
        else
            if fd > fx
                x = d;
                fx = fd;
            end
            a = c;
            c = d;
            fc = fd;
            d = a + gr * ( b - a );
            fd = Maximand( d, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
        end
        if a >= c || c >= d || d >= b
            break;
        end
    end
end

function Result = Maximand( C, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk )
    Result = tlog( C ) - ODOPnu * tpow( OMalpha * AKEalpha / C, OPnuDalphaPnu ) + beta * ExpectedV( tlog( max( thetaK, kNewCore * tpow( C, MOMalphaDalphaPnu ) - C ) ), V, Wv, kv, nk );
end

function EV = ExpectedV( kNew, V, Wv, kv, nk )
    if isfinite( kNew )
        Index = 1 + ( nk - 1 ) * ( kNew - kv( 1 ) ) / ( kv( end ) - kv( 1 ) );
        lIndex = max( 1, min( nk - 1, floor( Index ) ) );
        uIndex = lIndex + 1;
        fIndex = Index - lIndex;
        Vv = ( 1 - fIndex ) * V( :, lIndex ) + fIndex * V( :, uIndex );
        EV = Wv' * Vv;
    else
        EV = -Inf;
    end
end

function y = tlog( x )
    if x > 0
        y = reallog( x );
    else
        y = -Inf;
    end
end

function y = tpow( x, a )
    if x > 0
        y = realpow( x, a );
    else
        if a > 0
            y = 0;
        elseif a < 0
            y = Inf;
        else
            y = 1;
        end
    end
end
