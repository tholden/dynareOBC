disp( 'We start by looking at responses to news shocks at horizon 30 (without a ZLB).' );

disp( 'First, without indexation.' );
disp( 'Press a key to continue:' );
pause;

dynare NewsNK

h1 = gcf;

try
    delete NewsNK_*.*
    delete NewsNK.m
    delete NewsNK.log
    rmdir NewsNK s
catch
end

disp( 'Now with indexation.' );
disp( 'Press a key to continue:' );
pause;

dynare NewsNKIndexation

h2 = gcf;

try
    delete NewsNKIndexation_*.*
    delete NewsNKIndexation.m
    delete NewsNKIndexation.log
    rmdir NewsNKIndexation s
catch
end

for i = 1 : 4
    figure( h1 );
    s1 = subplot( 2, 2, i );
    figure( h2 );
    s2 = subplot( 2, 2, i );
    YLim1 = get( s1, 'YLim' );
    YLim2 = get( s2, 'YLim' );
    YLim  = [ min( YLim1( 1 ), YLim2( 1 ) ), max( YLim1( 2 ), YLim2( 2 ) ) ];
    set( s1, 'YLim', YLim );
    set( s2, 'YLim', YLim );
end

Titles = { '$Y_t$', '$\Pi_t$', '$R_t$', '$\nu_t$' };

figure( h1 );
PrepareFigure( 26, Titles, true );
SaveFigure( [ 0.5, 1 ], 'NewsPlots/Standard' );

figure( h2 );
PrepareFigure( 26, Titles, true );
SaveFigure( [ 0.5, 1 ], 'NewsPlots/Indexation' );

figure;
DiffXData = h1.Children( 2 ).Children( 2 ).XData;
DiffYData = h1.Children( 2 ).Children( 2 ).YData - h2.Children( 2 ).Children( 2 ).YData;
plot( DiffXData, zeros( size( DiffXData ) ), 'r-', DiffXData, DiffYData, 'k-' );
PrepareFigure( 26, { '' }, true );
SaveFigure( [ 0.5, 0.5 ], 'NewsPlots/Difference' );

disp( 'Observe that interest rate responses are very slightly lower in the model without indexation, which is enough to lead to multiplicity.' );

disp( 'We now show how multiplicity may be constructed.' );
disp( 'Press a key to continue:' );
pause;

ShowConstructionOfMultiplicity;

Titles = { 'News IRFs', 'Scaled news IRFs', 'Sum of scaled news IRFs' };
PrepareFigure( 22, Titles );
SaveFigure( [ 1, 0.5 ], 'NewsPlots/MultipleEq', true );

disp( 'We now present a complete example of multiplicity in this model, with welfare calculations.' );
disp( 'We start with the "fundamental" solution following a 10 standard deviation discount factor shock.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NKIRF.mod ShockScale=10 MLVSimulationMode=1

PlotWithWelfare;

Titles = { '$C_t$', '$L_t$', '$\Pi_t$', '$\nu_t$', '$R_t$', '$Z_t$ (Welfare c.e.)' };
PrepareFigure( 22, Titles, true );
SaveFigure( [ 0.5, 1 ], 'MultiplicityPlots/EarlyEscape' );

disp( 'We now show an alternative solution following a 10 standard deviation discount factor shock.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NKIRF.mod ShockScale=10 SkipFirstSolutions=1 MLVSimulationMode=1

PlotWithWelfare;

Titles = { '$C_t$', '$L_t$', '$\Pi_t$', '$\nu_t$', '$R_t$', '$Z_t$ (Welfare c.e.)' };
PrepareFigure( 22, Titles, true );
SaveFigure( [ 0.5, 1 ], 'MultiplicityPlots/LateEscape' );

disp( 'Observe that the outcome is much worse, with the economy essentially shutting down.' );
