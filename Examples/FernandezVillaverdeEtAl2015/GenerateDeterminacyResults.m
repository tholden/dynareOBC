disp( 'We start by examining with the original model.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NK.mod TimeToEscapeBounds=1000 FeasibilityTestGridSize=10

disp( 'Observe that M was found to not be an M matrix with any T>=15, and that M is not an S-matrix with T=1000 or T=infinity.' );

disp( 'We now see if responding to expected inflation changes anything.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NKFuture.mod TimeToEscapeBounds=1000 FeasibilityTestGridSize=10

disp( 'Much as before, M was found to not be an M matrix with any T>=14, and that M is not an S-matrix with T=1000 or T=infinity.' );

disp( 'We now run with a response to the price level in the Taylor rule.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC NKPriceTargeting.mod timetoescapebounds=200 FeasibilityTestGridSize=10

disp( 'Observe that M was found to be a P-matrix with T=200, and an S-matrix with T=200 or T=infinity.' );
