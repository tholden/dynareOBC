figure( 1 );

subplot( 1, 2, 2 );

N = min( size( dynareOBC_.MMatrix ) );

plot( 0 : ( N - 1 ), diag( dynareOBC_.MMatrix ), 0 : ( N - 1 ), zeros( 1, N ) );

set( gca, 'FontName', 'TeXGyrePagella' );
set( gca, 'FontSize', 26 );

title( 'The Smets & Wouters (2007) model' );

subplot( 1, 2, 1 );
YLim1 = get( gca, 'YLim' );
subplot( 1, 2, 2 );
YLim2 = get( gca, 'YLim' );

YLim = [ min( YLim1( 1 ), YLim2( 1 ) ), max( YLim1( 2 ), YLim2( 2 ) ) ];

subplot( 1, 2, 1 );
set( gca, 'YLim', YLim );
subplot( 1, 2, 2 );
set( gca, 'YLim', YLim );
