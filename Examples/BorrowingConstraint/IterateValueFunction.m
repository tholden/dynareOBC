function [ Vnew, Xnew ] = IterateValueFunction( V, X, XB, W, Bv, Av, beta, Ybar, R, UseTightBounds )
    nB = length( Bv );
    nA = length( Av );
    Vnew = coder.nullcopy( V );
    Xnew = coder.nullcopy( X );
    parfor iA = 1 : nA
        A = Av( iA );
        Wv = W( :, iA );
        Vmax = -Inf;
        Xmax = 0;
        for iB = 1 : nB
            B = Bv( iB ); %#ok<PFBNS>
            XL = Xmax;
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
                    XU = min( XU, X( iA, iB + 1 ) ); %#ok<PFBNS>
                end
            end
            XU = max( XL, XU );
            [ Vtmp, Xmax ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, XL, XU, beta, Ybar, R );
            Vmax = max( Vmax, Vtmp );
            Vnew( iA, iB ) = Vmax;
            Xnew( iA, iB ) = Xmax;
        end
    end
    Vnew = cummax( Vnew );
    Xnew = cummax( Xnew );
end
