dynareOBC NKNonDeflationary OtherMODFile=NKDeflationary OtherMODFileSwitchToProbability=0.001 OtherMODFileSwitchFromProbability=0.001 MLVSimulationMode=1 TimeToEscapeBounds=128
figure;
plot( dynareOBC_.MLVSimulationWithBounds.R( 1:1000 ) );
