disp( 'This script illustrates multiplicity of solutions following a 24.5 standard deviation demand shock in the Adjemian, Darracq Paries and Moyen (2007) model.' );

dynareOBC SWNLWCD ShockScale=24.5 SkipFirstSolutions=1

Titles = { 'Output', 'Consumption', 'Inflation', 'Nom. int. rates', 'Hours', 'Welfare c.e.' };
PrepareFigure( 22, Titles );
SaveFigure( [ 0.5, 1 ], 'MultiplicityExample' );

disp( 'Observe that the dotted line does not hit the bound, but the solid line does.' );
disp( 'Observe too that the welfare costs of such a jump to the bound are about 5 times higher.' );

disp( 'We now run the same exercise with a response to the price level in the Taylor rule.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC SWNLWCD_PLT ShockScale=24.5 SkipFirstSolutions=1

Titles = { 'Output', 'Consumption', 'Inflation', 'Nom. int. rates', 'Hours', 'Welfare c.e.' };
PrepareFigure( 22, Titles );
SaveFigure( [ 0.5, 1 ], 'NoMultiplicityPLTExample' );

disp( 'Observe that now no additional solution was found, and the welfare consequences of the shock are greatly muted.' );
