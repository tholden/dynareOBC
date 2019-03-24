clear variables
close all

NPlots = 4;

for i = 1 : NPlots
    eval( [ 'dynareOBC SW03IRFpNews.mod Bypass -DHorizon=' int2str( i - 1 ) ] );
end

delete SW03IRFpNews*.m
delete SW03IRFpNews.log
rmdir SW03IRFpNews s

for i = 1 : NPlots
    eval( [ 'dynareOBC SW03IRFpPLTNews.mod Bypass -DHorizon=' int2str( i - 1 ) ] );
end

delete SW03IRFpPLTNews*.m
delete SW03IRFpPLTNews.log
rmdir SW03IRFpPLTNews s

Titles = { 'Output', 'Consumption', 'Hours Worked', 'Quarterly Inflation', 'Price Level', 'Quarterly Nominal Interest Rate' };

NSubPlots = length( Titles );

XLims = zeros( 2, NSubPlots, 2 * NPlots );
YLims = zeros( 2, NSubPlots, 2 * NPlots );

for i = 1 : ( 2 * NPlots )
    hf1 = figure( i );
    for j = 1 : NSubPlots
        hs1 = hf1.Children( j );
        XLims( :, j, i ) = get( hs1, 'XLim' );
        YLims( :, j, i ) = get( hs1, 'YLim' );
    end
end

XLim = [ min( XLims( 1, :, : ), [], 3 ); max( XLims( 2, :, : ), [], 3 ) ];
YLim = [ min( YLims( 1, :, : ), [], 3 ); max( YLims( 2, :, : ), [], 3 ) ];

for i = 1 : ( 2 * NPlots )
    hf1 = figure( i );
    set( hf1, 'Position', [ 100 100 1280 800 ] );
    for j = 1 : NSubPlots
        hs1 = hf1.Children( j );
        axis( hs1, 'square' );
        title( hs1, Titles{ NSubPlots + 1 - j } );
        set( hs1, 'XLim', XLim( :, j ) );
        set( hs1, 'YLim', YLim( :, j ) );
    end
    tightfigadv( hf1 );
    savefig( hf1, [ 'News' int2str( i ) ], 'compact' );
    saveas( hf1, [ 'News' int2str( i ) ], 'meta' );
end
