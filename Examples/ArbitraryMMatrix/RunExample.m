disp( 'This script illustrates that we can construct a model with a specific M matrix.' );

dynareOBC ArbitraryM.mod TimeToEscapeBounds=10 TimeToReturnToSteadyState=10

disp( 'Opening M matrix. Notice that it has the numbers we specified in the MOD file.' );

openvar dynareOBC_.MMatrix;
