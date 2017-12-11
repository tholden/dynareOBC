function [ ix, jx, sx, rx, cx ] = spkron( A, B )
    
    % derived from alt_kron.m
    
    global spkronUseMex

    [I, J] = size(A);
    [K, L] = size(B);
    
    [ia,ja,sa] = vfind( A );
    [ib,jb,sb] = vfind( B );
    
    a = double( [ia,ja,sa] );
    b = double( [ib,jb,sb] );
    
    if isempty( ia ) || isempty( ib )
        ix = [];
        jx = [];
        sx = [];
    else
        if isempty( spkronUseMex )
            [ ix, jx, sx ] = spkron_internal( K,a, L,b );
        elseif spkronUseMex
            [ ix, jx, sx ] = spkron_internal_mex_mex( int32(K),a, int32(L),b );
        else
            [ ix, jx, sx ] = spkron_internal_mex( int32(K),a, int32(L),b );
        end
    end
    rx = I*K;
    cx = J*L;
    
    if nargout <= 1
        ix = sparse( ix, jx, sx, rx, cx );
    end

end
