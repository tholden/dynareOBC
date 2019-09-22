disp( 'We start by looking at responses to news shocks at horizon 30 (without a ZLB).' );

disp( 'First, without indexation.' );
disp( 'Press a key to continue:' );
pause;

dynare NewsNK

PrepareFigure;

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

PrepareFigure;

try
    delete NewsNKIndexation_*.*
    delete NewsNKIndexation.m
    delete NewsNKIndexation.log
    rmdir NewsNKIndexation s
catch
end

disp( 'Observe that interest rate responses are very slightly lower in the model without indexation, which is enough to lead to multiplicity.' );

disp( 'We now present an example of multiplicity in this model, with welfare calculations.' );
disp( 'We start with the "fundamental" solution following a 10 standard deviation discount factor shock.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NKIRF.mod ShockScale=10 MLVSimulationMode=1

PlotWithWelfare;

disp( 'We now show an alternative solution following a 10 standard deviation discount factor shock.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NKIRF.mod ShockScale=10 SkipFirstSolutions=1 MLVSimulationMode=1

PlotWithWelfare;

disp( 'Observe that the outcome is much worse, with the economy essentially shutting down.' );
