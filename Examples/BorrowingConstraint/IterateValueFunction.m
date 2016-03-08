function [ Vnew, Cnew ] = IterateValueFunction( V, C, CB, W, Bv, Av, Vmin, beta, Ybar, R )
    nB = length( Bv );
    nA = length( Av );
    Vnew = coder.nullcopy( V );
    Cnew = coder.nullcopy( C );
    parfor iA = 1 : nA
        A = Av( iA );
        Wv = W( :, iA );
        for iB = 1 : nB
            B = Bv( iB ); %#ok<PFBNS>
            [ Vnew( iA, iB ), Cnew( iA, iB ) ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, CB( iA, iB ), Vmin, beta, Ybar, R );
        end
    end
    Vnew = cummax( Vnew, 1 );
    Vnew = cummax( Vnew, 2 );
end
