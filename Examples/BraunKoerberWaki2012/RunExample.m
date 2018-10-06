disp( 'This script illustrates IRFs to 5 standard deviation shocks in the Braun Koerber Waki (2012) model.' );

dynareOBC bkw2012 ShockScale=5

disp( 'Note that both shocks hit the zero lower bound.' );
disp( 'Note also from the output above that M is a P-matrix for this model, so there is a unique solution to the linearised model with the bound.' );
