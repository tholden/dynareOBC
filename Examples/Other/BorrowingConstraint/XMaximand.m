function Vout = XMaximand( X, B, A, Wv, Bv, PP, VOverallMax, beta, Ybar, R )
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
        Vv = 0.5 * ( cummax( Vv, 1, 'forward' ) + cummin( Vv, 1, 'reverse' ) );
        EV = Wv' * Vv;
    else
        EV = -Inf;
    end
end
