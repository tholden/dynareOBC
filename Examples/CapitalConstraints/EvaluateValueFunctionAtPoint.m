function [ Vnew, Cnew, CBnew ] = EvaluateValueFunctionAtPoint( k, a, Wv, kv, V, Cg, CBg, alpha, beta, nu, theta )
    OMalpha = 1 - alpha;
    alphaPnu = alpha + nu;
    MOMalphaDalphaPnu = - OMalpha / alphaPnu;
    OPnu = 1 + nu;
    OPnuDalphaPnu = OPnu / alphaPnu;
    ODOPnu = 1 / OPnu;
    nk = length( kv );
    AKEalpha = exp( a + alpha * k );
    kNewCore = ( AKEalpha ^ OPnu * OMalpha ^ OMalpha ) ^ ( 1 / alphaPnu );
    thetaK = theta * exp( k );
    CBnew = exp( HalleySolveBound( log( CBg ), kNewCore, MOMalphaDalphaPnu, thetaK ) );
%     if DMaximand( CBnew - 2 * eps( CBnew ), ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk ) > 0
%         Cnew = CBnew;
%     else
%         Cg = min( Cg, CBnew - 1e-4 );
%         LB = Cg - 1e-4;
%         UB = Cg + 1e-4;
%         while DMaximand( LB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk ) < 0
%             LB = max( 0.5 * LB, Cg - 2 * ( Cg - LB ) );
%         end
%         while DMaximand( UB, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk ) > 0
%             UB = min( CBnew - 0.5 * ( CBnew - UB ), Cg + 2 * ( UB - Cg ) );
%         end
%         Cnew = fzero( @DMaximand, [ LB, UB ], optimset( 'Display', 'off', 'TolX', min( eps( LB ), eps( UB ) ) ), ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
%     end
%     Vnew = Maximand( Cnew, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    [ Cnew, Vnew ] = fminbnd( @Minimand, 0, CBnew, optimset( 'Display', 'off', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolX', max( eps, eps( CBnew ) ) ), ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk );
    Vnew = -Vnew;
end

function cBnew = HalleySolveBound( cBg, kNewCore, MOMalphaDalphaPnu, thetaK )
    ExitFlag = false;
    while true
        t1 = kNewCore * exp( cBg * MOMalphaDalphaPnu );
        t2 = exp( cBg );
        f0 = t1 - t2 - thetaK;
        f1 = MOMalphaDalphaPnu * t1 - t2;
        f2 = MOMalphaDalphaPnu * MOMalphaDalphaPnu * t1;
        Offset = 2 * f0 * f1 / ( 2 * f1 * f1 - f0 * f2 );
        cBnew = cBg - Offset;
        if ( cBnew == cBg ) || ExitFlag
            return;
        end
        if abs( Offset ) <= 4 * min( eps( cBg ), eps( cBnew ) )
            ExitFlag = true;
        end
        cBg = cBnew;
    end
end

function Result = Minimand( C, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk )
    Result = -( log( C ) - ODOPnu * ( OMalpha * AKEalpha / C ) ^ OPnuDalphaPnu + beta * ExpectedV( log( max( thetaK, kNewCore * C ^ MOMalphaDalphaPnu - C ) ), V, Wv, kv, nk ) );
end

function Result = Maximand( C, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk )
    Result = log( C ) - ODOPnu * ( OMalpha * AKEalpha / C ) ^ OPnuDalphaPnu + beta * ExpectedV( log( max( thetaK, kNewCore * C ^ MOMalphaDalphaPnu - C ) ), V, Wv, kv, nk );
end

function Result = DMaximand( C, ODOPnu, OMalpha, AKEalpha, OPnuDalphaPnu, beta, thetaK, kNewCore, MOMalphaDalphaPnu, V, Wv, kv, nk )
    Result = ( 1 + OPnuDalphaPnu * ODOPnu * ( OMalpha * AKEalpha / C ) ^ OPnuDalphaPnu ) / C + beta * ( MOMalphaDalphaPnu * kNewCore * C ^ ( MOMalphaDalphaPnu - 1 ) - 1 ) / ( kNewCore * C ^ MOMalphaDalphaPnu - C ) * DExpectedV( log( max( thetaK, kNewCore * C ^ MOMalphaDalphaPnu - C ) ), V, Wv, kv, nk );
end

function EV = ExpectedV( kNew, V, Wv, kv, nk )
    Index = 1 + ( nk - 1 ) * ( kNew - kv( 1 ) ) / ( kv( end ) - kv( 1 ) );
    lIndex = max( 1, min( nk - 1, floor( Index ) ) );
    uIndex = lIndex + 1;
    fIndex = Index - lIndex;
    Vv = ( 1 - fIndex ) * V( :, lIndex ) + fIndex * V( :, uIndex );
    EV = Wv' * Vv;
end

function DEV = DExpectedV( kNew, V, Wv, kv, nk )
    Index = 1 + ( nk - 1 ) * ( kNew - kv( 1 ) ) / ( kv( end ) - kv( 1 ) );
    lIndex = max( 1, min( nk - 1, floor( Index ) ) );
    uIndex = lIndex + 1;
    DfIndex = ( nk - 1 ) / ( kv( end ) - kv( 1 ) );
    DVv = - DfIndex * V( :, lIndex ) + DfIndex * V( :, uIndex );
    DEV = Wv' * DVv;
end
