disp( 'We start by showing two solutions following a 22.5 standard deviation demand shock.' );

dynareOBC SW03IRF.mod ShockScale=22.5 SkipFirstSolutions=1

disp( 'Observe that the dotted line does not hit the bound, but the solid line does.' );
disp( 'Press a key to continue:' );
pause;

disp( 'The multiplicity here is unsurprising given that the diagonal of the M matrix goes negative.' );
disp( 'The next figure shows this diagonal.' );

figure;
plot( diag( dynareOBC_.MMatrix ) );
