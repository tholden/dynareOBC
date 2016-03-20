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
