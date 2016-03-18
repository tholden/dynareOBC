function [ Vnew, Xnew ] = IterateValueFunction( V, X, XB, W, Bv, Av, beta, Ybar, R )
    nB = length( Bv );
    nA = length( Av );
    Vnew = coder.nullcopy( V );
    Xnew = coder.nullcopy( X );
    parfor iA = 1 : nA
        A = Av( iA );
        Wv = W( :, iA );
        Vmax = -Inf;
        Xmax = -Inf;
        for iB = 1 : nB
            B = Bv( iB ); %#ok<PFBNS>
            [ Vtmp, Xtmp ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, XB( iA, iB ), beta, Ybar, R );
            Vmax = max( Vmax, Vtmp );
            Xmax = max( Xmax, Xtmp );
            Vnew( iA, iB ) = Vmax;
            Xnew( iA, iB ) = Xmax;
        end
    end
    Vnew = cummax( Vnew );
end
