clear variables
close all

dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[5]
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[5:6]
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[5:8]
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[1] IRFsForceNotAtBoundIndices=[4]
dynareOBC SW03IRFpTPLT.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
dynareOBC SW03IRFpPLT.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1
dynareOBC SW03IRFpRW.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1

dynareOBC SW03IRFp.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
dynareOBC SW03IRFp.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[5]
dynareOBC SW03IRFp.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[5:6]
dynareOBC SW03IRFp.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[5:8]
dynareOBC SW03IRFp.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0 IRFsForceAtBoundIndices=[1] IRFsForceNotAtBoundIndices=[4]
dynareOBC SW03IRFpTPLT.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
dynareOBC SW03IRFpPLT.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0
dynareOBC SW03IRFpRW.mod ShockScale=23.1 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=0

NPlots = 16;

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
    savefig( hf, int2str( i ), 'compact' );
    saveas( hf, int2str( i ), 'meta' );
end
