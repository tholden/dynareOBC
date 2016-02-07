function [ Vnew, Cnew, CBnew ] = EvaluateValueFunctionAtPoint( k, a, Wv, kv, V, Cg, CBg, alpha, beta, nu, theta )
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
    
    CBnew = exp( HalleySolveBound( tlog( CBg ), kNewCore, MOMalphaDalphaPnu, thetaK ) );
    
    Step = 1e-4;
    Cg = min( CBnew * ( Cg / CBg ), CBnew );
    LB = max( 0.5 * CBnew, Cg - Step );
    UB = min( CBnew, Cg + Step );
    Cg = 0.5 * ( LB + UB );
    FLB = Maximand( LB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    FCg = Maximand( Cg, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    FUB = NaN;
    while FLB >= FCg
        UB = Cg;
        FUB = FCg;
        Cg = LB;
        FCg = FLB;
        LB = max( 0.5 * LB, LB - Step );
        Step = 2 * Step;
        FLB = Maximand( LB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    end
    if isnan( FUB )
        FUB = Maximand( UB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    end
    while ( FUB >= FCg ) && ( UB < CBnew )
        if FUB > FCg
            LB = Cg;
            FLB = FCg;
        end
        Cg = UB;
        FCg = FUB;
        UB = min( UB + Step, CBnew );
        Step = 2 * Step;
        FUB = Maximand( UB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    end
    
    [ Cnew, Vnew ] = GoldenSectionMaximise( LB, UB, FLB, FUB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
end

function cBnew = HalleySolveBound( cBg, kNewCore, MOMalphaDalphaPnu, thetaK )
    while true
        t1 = kNewCore * exp( cBg * MOMalphaDalphaPnu );
        t2 = exp( cBg );
        f0 = t1 - t2 - thetaK;
        f1 = MOMalphaDalphaPnu * t1 - t2;
        f2 = MOMalphaDalphaPnu * MOMalphaDalphaPnu * t1;
        Offset = 2 * f0 * f1 / ( 2 * f1 * f1 - f0 * f2 );
        cBnew = cBg - Offset;
        if ( cBnew == cBg )
            return;
        end
        cBg = cBnew;
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
