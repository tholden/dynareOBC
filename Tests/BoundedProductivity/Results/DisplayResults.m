clear all; %#ok<CLALL>
WarningState = warning( 'off', 'all' );
try
    Files = dir( '*.mat' );
    Norms = zeros( length( Files ), 8 );
    for i = 1 : length( Files )
        
        load( Files( i ).name );
        
        AtBound = oo_.endo_simul(end,:) <= 0.0001;
        rError = dynareOBC_.MLVSimulationWithBounds.rError;
        
        AtBound = AtBound( 101:end );
        rError = rError( 101:end );
        
        OneNorm = mean( abs( rError ) );
        TwoNorm = sqrt( mean( rError .^ 2 ) );
        InfNorm = max( abs( rError ) );
        
        AtBoundOneNorm = mean( abs( rError( AtBound ) ) );
        AtBoundTwoNorm = sqrt( mean( rError( AtBound ) .^ 2 ) );
        AtBoundInfNorm = max( abs( rError( AtBound ) ) );
        
        Norms( i, : ) = [ ( t2 - t1 ) / 1000, OneNorm, TwoNorm, InfNorm, AtBoundOneNorm, AtBoundTwoNorm, AtBoundInfNorm, sum( AtBound ) ];
        
    end
    Norms = array2table( Norms, 'VariableNames', { 'Seconds', 'OneNorm', 'TwoNorm', 'InfNorm', 'AtBoundOneNorm', 'AtBoundTwoNorm', 'AtBoundInfNorm', 'PeriodsAtBound' }, 'RowNames', { Files.name } );
    Norms = sortrows( Norms, 'OneNorm' );
    disp( Norms );
catch Err
    disp( Err.message );
end
warning( WarningState );
writetable( Norms, 'Results.xlsx', 'WriteRowNames', true );
