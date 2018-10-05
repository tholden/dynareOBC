disp( 'This script illustrates multiplicity of solutions following a 24.5 standard deviation demand shock in the Adjemian, Darracq Paries and Moyen (2007) model.' );

dynareOBC SWNLWCD ShockScale=24.5 SkipFirstSolutions=1

disp( 'Observe that the dotted line does not hit the bound, but the solid line does.' );
disp( 'Observe too that the welfare costs of such a jump to the bound are about 5 times higher.' );
