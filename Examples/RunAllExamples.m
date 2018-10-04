disp( 'This script runs all the examples from sub-folders.' );

DirResult = dir;

j = 0;

for i = 1 : length( DirResult )
    
    if DirResult( i ).name( 1 ) == '.'
        continue
    end
    
    if ~DirResult( i ).isdir
        continue
    end
    
    j = j + 1;
    WarningState = warning( 'off', 'all' );
    save State i j DirResult WarningState;
    clear all; %#ok<CLALL>
    load State;
    warning( WarningState );

    DirName = DirResult( i ).name;

    cd( DirName );
        
    fprintf( '\n\n' );
    disp( [ 'About to run example ' int2str( j ) ', "' DirName '".' ] );
    disp( 'Press a key to continue:' );
    pause;
    fprintf( '\n\n' );
    
    try
        RunExample;
    catch Error
        disp( 'Error running example.' );
        disp( Error );
    end
    
    cd ..;
    
    load State;
    
end

try
    delete State.mat
catch
end
