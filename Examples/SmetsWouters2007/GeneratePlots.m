disp( 'We start by showing two solutions following the combination of shocks most likely to take the model to the ZLB.' );

disp( 'First, the solution which escapes the bound earliest.' );

dynareOBC SW07IRF.mod

disp( 'Now we will see an alternative solution following the same shock which stays at the bound for much longer' );
disp( 'Press a key to continue:' );
pause;

dynareOBC SW07IRF.mod SkipFirstSolutions=1

disp( 'The multiplicity here is less obvious given that the diagonal of the M matrix is positive.' );
disp( 'The next figure shows this diagonal.' );

figure;
plot( diag( dynareOBC_.MMatrix ) );
