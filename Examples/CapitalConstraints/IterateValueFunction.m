function [ Vnew, Cnew, CBnew ] = IterateValueFunction( V, C, CB, W, kv, av, alpha, beta, nu, theta )
    n = length ( kv );
    assert( length( av ) == n );
    Vnew = coder.nullcopy( V );
    Cnew = coder.nullcopy( C );
    CBnew = coder.nullcopy( CB );
    parfor ia = 1 : n
        a = av( ia );
        Wv = W( :, ia );
        for ik = 1 : n
            k = kv( ik ); %#ok<PFBNS>
            [ Vnew( ia, ik ), Cnew( ia, ik ), CBnew( ia, ik ) ] = EvaluateValueFunctionAtPoint( k, a, Wv, kv, V, C( ia, ik ), CB( ia, ik ), alpha, beta, nu, theta );
        end
    end
end
