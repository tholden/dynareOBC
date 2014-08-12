function [ ix, jx, sx ] = spkron_internal( K,a, L,b )

    % derived from alt_kron.m

    ma = max( abs( a(:,3) ) ) * eps;
    mb = max( abs( b(:,3) ) ) * eps;
    
    a( abs(a(:,3))<mb, : ) = [];
    b( abs(b(:,3))<ma, : ) = [];
    
    ix = bsxfun(@plus,b(:,1),K*(a(:,1)-1).');
    jx = bsxfun(@plus,b(:,2),L*(a(:,2)-1).');
    
    sx = bsxfun(@times,b(:,3),a(:,3).');
    sx( abs( sx ) < eps ) = 0;
    
    ix = ix(:);
    jx = jx(:);
    sx = sx(:);

end
