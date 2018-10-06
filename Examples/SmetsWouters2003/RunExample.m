disp( 'This script illustrates properties of the Smets Wouters (2003) model.' );

disp( 'We start by showing two solutions following a 22.5 standard deviation demand shock.' );

dynareOBC SW03IRF.mod ShockScale=22.5 SkipFirstSolutions=1

disp( 'Observe that the dotted line does not hit the bound, but the solid line does.' );
disp( 'Press a key to continue:' );
pause;

disp( 'The multiplicity here is unsurprising given that the diagonal of the M matrix goes negative.' );
disp( 'The next figure shows this diagonal.' );

figure;
plot( diag( dynareOBC_.MMatrix ) );

disp( 'We now look at the other determinacy properties of this model.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC SW03.mod TimeToEscapeBounds=1000 FeasibilityTestGridSize=1 Sparse

disp( 'Observe that now no additional solution was found, and the welfare consequences of the shock are greatly muted.' );
