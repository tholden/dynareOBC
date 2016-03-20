function [ Vnew, Xopt, Verr, Xerr, PP ] = IterateValueFunction( V, X, XB, W, Bv, Av, beta, Ybar, R, UseTightBounds )
    nB = length( Bv );
    nA = length( Av );
    VOverallMax = max( max( V ) );
    PP = pchip( Bv, V );
    Vopt = coder.nullcopy( V );
    Xopt = coder.nullcopy( X );
    parfor iA = 1 : nA
        A = Av( iA );
        Wv = W( :, iA );
        for iB = 1 : nB
            B = Bv( iB ); %#ok<PFBNS>
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
            [ Vopt( iA, iB ), Xopt( iA, iB ) ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, PP, VOverallMax, XL, X( iA, iB ), XU, beta, Ybar, R ); %#ok<PFBNS>
        end
    end
    Xnew = 0.5 * ( cummax( cummax( Xopt, 2, 'forward' ), 1, 'forward' ) + cummin( cummin( Xopt, 2, 'reverse' ), 1, 'reverse' ) );
    Xerr = max( max( abs( Xnew - Xopt ) ) );
    Vnew = 0.5 * ( cummax( cummax( Vopt, 2, 'forward' ), 1, 'forward' ) + cummin( cummin( Vopt, 2, 'reverse' ), 1, 'reverse' ) );
    Verr = max( max( abs( Vnew - Vopt ) ) );
end
