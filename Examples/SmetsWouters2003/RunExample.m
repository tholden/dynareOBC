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

disp( 'Would you like to see results on determinacy of the Smets Wouters (2003) model modified to include NGDP targeting? (These are very slow, and require at least 32GB of RAM.)' );
Input = strtrim( lower( input( 'Press y then return to see them or just return to skip: ', 's' ) ) );
if ( length( Input ) ~= 1 ) || ( Input( 1 ) ~= 'y' )
    return
end

dynareOBC SW03PLT.mod TimeToEscapeBounds=1000 FeasibilityTestGridSize=10 SkipQuickPCheck

disp( 'Observe that M was found to be an S-matrix for T=1000 and T=infinity.' );
