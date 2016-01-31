clear all; %#ok<CLALL>
WarningState = warning( 'off', 'all' );
try
    Files = dir( '*.mat' );
    Norms = zeros( length( Files ), 7 );
    for i = 1 : length( Files )
        
        load( Files( i ).name );
        
        Errors = [ dynareOBC_.MLVSimulationWithBounds.error01; dynareOBC_.MLVSimulationWithBounds.error02; dynareOBC_.MLVSimulationWithBounds.error03; dynareOBC_.MLVSimulationWithBounds.error04 ];
        NonNan = all( ~isnan( Errors ) );
        NonNan( 1:100 ) = false;
        Errors = Errors( :, NonNan );
        AtBound = oo_.endo_simul( end, NonNan ) <= 0.0001;
        
        Errors = Errors( : );
        AtBound = AtBound( : );
        AtBound = [ AtBound; AtBound; AtBound; AtBound; ]; %#ok<AGROW>
        
        OneNorm = mean( abs( Errors ) );
        TwoNorm = sqrt( mean( Errors .^ 2 ) );
        InfNorm = max( abs( Errors ) );
        
        AtBoundOneNorm = mean( abs( Errors( AtBound ) ) );
        AtBoundTwoNorm = sqrt( mean( Errors( AtBound ) .^ 2 ) );
        AtBoundInfNorm = max( abs( Errors( AtBound ) ) );
        
        Norms( i, : ) = [ OneNorm, TwoNorm, InfNorm, AtBoundOneNorm, AtBoundTwoNorm, AtBoundInfNorm, sum( AtBound ) ];
        
    end
    Norms = array2table( Norms, 'VariableNames', { 'OneNorm', 'TwoNorm', 'InfNorm', 'AtBoundOneNorm', 'AtBoundTwoNorm', 'AtBoundInfNorm', 'PeriodsAtBound' }, 'RowNames', { Files.name } );
    Norms = sortrows( Norms, 'OneNorm' );
    disp( Norms );
catch Err
    disp( Err.message );
end
warning( WarningState );
writetable( Norms, 'Results.xlsx', 'WriteRowNames', true );
