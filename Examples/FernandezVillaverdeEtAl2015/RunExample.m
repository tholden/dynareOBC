disp( 'This script illustrates various properties of the Fernandez Villaverde et al. (2012) model along with various extensions.' );

GeneratePlots;

disp( 'Would you like to see the determinacy results? (They are somewhat slow.)' );
Input = strtrim( lower( input( 'Press y then return to see them or just return to skip: ', 's' ) ) );
if ( length( Input ) ~= 1 ) || ( Input( 1 ) ~= 'y' )
    return
end

GenerateDeterminacyResults;
