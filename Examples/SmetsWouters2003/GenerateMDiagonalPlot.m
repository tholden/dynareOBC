figure( 100 );

subplot( 2, 2, 1 );

N = min( size( dynareOBC_.MMatrix ) );

plot( 0 : ( N - 1 ), diag( dynareOBC_.MMatrix ), 'k', 0 : ( N - 1 ), zeros( 1, N ), 'r' );
