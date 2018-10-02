disp( 'This script runs some of the examples from sub-folders.' );

SelectedExamples = { 'ArbitraryMMatrix', 'BraunKoerberWaki2012' };

for i = 1 : length( SelectedExamples )

    WarningState = warning( 'off', 'all' );
    save State i SelectedExamples WarningState;
    clear all; %#ok<CLALL>
    load State;
    warning( WarningState );

    cd( SelectedExamples{ i } );
    
    disp( [ 'About to run example ' int2str( i ) ', "' SelectedExamples{ i } '".' ] );
    disp( 'Press a key to continue:' );
    pause;
    
    RunExample;
    
    disp( 'Press a key to continue:' );
    pause;
    
    cd ..;
    
    load State;
    
end
