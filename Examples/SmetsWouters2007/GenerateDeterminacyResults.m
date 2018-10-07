disp( 'We start by showing that M is not an S-matris in the Smets Wouters (2007) model, with T=1000 or with T=infinity.' );

dynareOBC SW07.mod TimeToEscapeBounds=1000 FeasibilityTestGridSize=10

disp( 'Observe that M was found to not be an S-matrix with T=1000 or T=infinity.' );

disp( 'Things are different if we switch to a rule that just responds to NGDP.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC SW07NGDP.mod TimeToEscapeBounds=1000 FeasibilityTestGridSize=10 SkipQuickPCheck

disp( 'Observe that M was found to be an S-matrix for T=1000 and T=infinity. Observe also that M is a P-matrix for T=1000.' );
