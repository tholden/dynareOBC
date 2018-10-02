disp( 'We start by running with a weak response to output growth, alpha_{Delta y} = 1.05' );
disp( 'Press a key to continue:' );
pause;

dynareOBC BPYModelPersistentLow.mod PTest=20 TimeToEscapeBounds=50 FeasibilityTestGridSize=20

disp( 'Observe that M was found to be a P-matrix with T=20, and that with T=infinity, M is an S-matrix.' );

disp( 'We now run with a stronger response to output growth, alpha_{Delta y} = 1.05' );
disp( 'Press a key to continue:' );
pause;

dynareOBC BPYModelPersistentHigh.mod TimeToEscapeBounds=200 FeasibilityTestGridSize=20

disp( 'Observe that M was found to not be an S-matrix with T=200 or with T=infinity.' );

disp( 'We now run with price level targeting.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC BPYModelPriceLevelTargeting.mod TimeToEscapeBounds=1000
