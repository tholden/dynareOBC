disp( 'This script illustrates properties of the Smets Wouters (2007) model.' );

GeneratePlots;

disp( 'Would you like to see results on determinacy of the Smets Wouters (2007) model and a variant with a response to the price level? (These are very slow, and require at least 32GB of RAM.)' );
Input = strtrim( lower( input( 'Press y then return to see them or just return to skip: ', 's' ) ) );
if ( length( Input ) ~= 1 ) || ( Input( 1 ) ~= 'y' )
    return
end

GenerateDeterminacyResults;
