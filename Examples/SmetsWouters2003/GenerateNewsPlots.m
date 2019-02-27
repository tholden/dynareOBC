clear variables
close all

NPlots = 8;

for i = 1 : NPlots
    eval( [ 'dynare SW03IRFpNews.mod -DHorizon=' int2str( i - 1 ) ] );
end

delete SW03IRFpNews*.m
delete SW03IRFpNews.log
rmdir SW03IRFpNews s

Titles = { 'Output', 'Consumption', 'Hours Worked', 'Quarterly Inflation', 'Price Level', 'Quarterly Nominal Interest Rate' };

NSubPlots = length( Titles );

XLims = zeros( 2, NSubPlots, NPlots );
YLims = zeros( 2, NSubPlots, NPlots );

for i = 1 : NPlots
    hf = figure( i );
    for j = 1 : NSubPlots
        hs = subplot( 2, 3, j );
        XLims( :, j, i ) = get( hs, 'XLim' );
        YLims( :, j, i ) = get( hs, 'YLim' );
    end
end

XLim = [ min( XLims( 1, :, : ), [], 3 ); max( XLims( 2, :, : ), [], 3 ) ];
YLim = [ min( YLims( 1, :, : ), [], 3 ); max( YLims( 2, :, : ), [], 3 ) ];

for i = 1 : NPlots
    hf = figure( i );
    set( hf, 'Position', [ 100 100 1280 800 ] );
    for j = 1 : NSubPlots
        hs = subplot( 2, 3, j );
        axis square;
        title( Titles{ j } );
        set( hs, 'XLim', XLim( :, j ) );
        set( hs, 'YLim', YLim( :, j ) );
    end
    tightfigadv( hf );
    savefig( hf, [ 'News' int2str( i ) ], 'compact' );
    saveas( hf, [ 'News' int2str( i ) ], 'meta' );
end
