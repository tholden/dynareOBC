function [ ix, jx, sx ] = spkron_internal_mex( K,a, L,b )

    % derived from alt_kron.m

    la = int32( size( a, 1 ) );
    lb = int32( size( b, 1 ) );
    
    ma = 0;
    for i = int32( 1 ) : la
        ma = max( ma, abs( a( i, 3 ) ) );
    end
    mb = 0;
    for i = int32( 1 ) : lb
        mb = max( mb, abs( b( i, 3 ) ) );
    end
    
    ma = ma * eps;
    mb = mb * eps;
    
    KianM1 = coder.nullcopy( zeros( la, 1, 'int32' ) );
    LjanM1 = coder.nullcopy( zeros( la, 1, 'int32' ) );
    san = coder.nullcopy( zeros( la, 1, 'double' ) );
    lan = int32( 0 );
    for i = int32( 1 ) : la
        if abs( a( i, 3 ) ) > mb
            lan = lan + 1;
            KianM1( lan ) = K*(int32(a( i, 1 ))-int32( 1 ));
            LjanM1( lan ) = L*(int32(a( i, 2 ))-int32( 1 ));
            san( lan ) = a( i, 3 );
        end
    end
    
    ibn = coder.nullcopy( zeros( lb, 1, 'int32' ) );
    jbn = coder.nullcopy( zeros( lb, 1, 'int32' ) );
    sbn = coder.nullcopy( zeros( lb, 1, 'double' ) );
    lbn = int32( 0 );
    for i = int32( 1 ) : lb
        if abs( b( i, 3 ) ) > ma
            lbn = lbn + 1;
            ibn( lbn ) = b( i, 1 );
            jbn( lbn ) = b( i, 2 );
            sbn( lbn ) = b( i, 3 );
        end
    end
    
    ix = coder.nullcopy( zeros( lbn, lan, 'double' ) );
    jx = coder.nullcopy( zeros( lbn, lan, 'double' ) );
    sx = coder.nullcopy( zeros( lbn, lan, 'double' ) );
    
    parfor i = int32( 1 ) : lan
        ix( :, i ) = double( ibn( 1:lbn ) + KianM1( i ) ); %#ok<PFBNS>
        jx( :, i ) = double( jbn( 1:lbn ) + LjanM1( i ) ); %#ok<PFBNS>
        sx( :, i ) = TrimSmall( sbn( 1:lbn ) * san( i ) ); %#ok<PFBNS>
    end
    
    ix = ix(:);
    jx = jx(:);
    sx = sx(:);
    
    % x = sortrows( [ ix, jx, sx ] );
    % ix = x(end:,1); jx = x(:,2); sx = x(:,3);
    
end

function x = TrimSmall( x )
    coder.inline('always');
    lx = int32( numel( x ) );
    for j = int32( 1 ) : lx
        if abs( x(j) ) < eps
            x(j) = 0;
        end
    end
end
