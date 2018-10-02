disp( 'This script illustrates various properties of the Brendon Paustian Yates (2012) model along with various extensions.' );

disp( 'We start with IRFs.' );

GeneratePlots;

disp( 'Would you like to see the results of tests of how the response to output growth changes determinacy?' );
Input = strtrim( lower( input( 'Press y then return to see them or just return to skip:', 's' ) ) );
if ( length( Input ) ~= 1 ) || ( Input( 1 ) ~= 'y' )
    return
end

GenerateDeterminacyResults;
