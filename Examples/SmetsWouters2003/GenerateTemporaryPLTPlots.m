clear variables
close all

Regenerate = true;

if Regenerate %#ok<*UNRCH>

    dynareOBC SW03IRFp.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1
    dynareOBC SW03IRFp.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[5]
    dynareOBC SW03IRFp.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[5:6]
    dynareOBC SW03IRFp.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[1] IRFsForceNotAtBoundIndices=[4]
    dynareOBC SW03IRFpTPLT.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
    dynareOBC SW03IRFpPLT.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1
    dynareOBC SW03IRFpRW.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1
    dynareOBC SW03IRFpAIT.mod ShockScale=15.8 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1

    dynareOBC SW03IRFp.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
    dynareOBC SW03IRFp.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[5]
    dynareOBC SW03IRFp.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[5:6]
    dynareOBC SW03IRFp.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[1] IRFsForceNotAtBoundIndices=[4]
    dynareOBC SW03IRFpTPLT.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
    dynareOBC SW03IRFpPLT.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
    dynareOBC SW03IRFpRW.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
    dynareOBC SW03IRFpAIT.mod ShockScale=16.2 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0

    NPlots = 8;
    
else
    
    NPlots = 8;
    
    for k = 0 : 1
        for i = 1 : NPlots
            openfig( int2str( i + NPlots * k ) );
        end
    end
    
end

Titles = { 'Output', 'Consumption', 'Hours Worked', 'Quarterly Inflation', 'Price Level', 'Quarterly Nominal Interest Rate' };

NSubPlots = length( Titles );

for k = 0 : 1

    XLims = zeros( 2, NSubPlots, NPlots );
    YLims = zeros( 2, NSubPlots, NPlots );

    for i = 1 : NPlots

        hf0 = figure( 1 + NPlots * k );

        Lines0 = cell( NSubPlots, 1 );

        for j = 1 : NSubPlots
            hs = hf0.Children( j );
            Lines0{ j } = hs.Children( 2 );

            assert( strcmp( Lines0{ j }.LineStyle, ':' ) );
        end

        hf = figure( i + NPlots * k );
        for j = 1 : NSubPlots
            hs = hf.Children( j );
            Line = hs.Children( 2 );

            assert( strcmp( Line.LineStyle, ':' ) );
            Line.YData = Lines0{ j }.YData;
            drawnow;

            XLims( :, j, i ) = get( hs, 'XLim' );
            YLims( :, j, i ) = get( hs, 'YLim' );
        end

    end

    XLim = [ min( XLims( 1, :, : ), [], 3 ); max( XLims( 2, :, : ), [], 3 ) ];
    YLim = [ min( YLims( 1, :, : ), [], 3 ); max( YLims( 2, :, : ), [], 3 ) ];

    for i = 1 : NPlots

        hf = figure( i + NPlots * k );
        if Regenerate
            set( hf, 'Position', [ 100 100 1280 800 ] );
        end

        for j = 1 : NSubPlots

            hs = hf.Children( j );

            axis( hs, 'square' );
            title( hs, Titles{ j } );
            set( hs, 'XLim', XLim( :, j ) );
            set( hs, 'YLim', YLim( :, j ) );

        end

        tightfigadv( hf );

        savefig( hf, int2str( i + NPlots * k ), 'compact' );
        saveas( hf, int2str( i + NPlots * k ), 'meta' );

    end

end

