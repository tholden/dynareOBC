figure( 100 );

subplot( 2, 2, 1 );

N = min( size( dynareOBC_.MMatrix ) );

plot( 0 : ( N - 1 ), diag( dynareOBC_.MMatrix ), 0 : ( N - 1 ), zeros( 1, N ) );

set( gca, 'FontName', 'TeXGyrePagella' );
set( gca, 'FontSize', 26 );

title( 'The Smets & Wouters (2003) model' );
