disp( 'This script illustrates that we can construct a model with a specific M matrix.' );

dynareOBC ArbitraryM.mod TimeToEscapeBounds=7 TimeToReturnToSteadyState=7

disp( 'The model''s M matrix follows. Notice that it has the numbers we specified in the MOD file.' );

disp( dynareOBC_.MMatrix( 1:7, 1:7 ) );
