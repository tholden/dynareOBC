disp( 'This script replicates Figure 3 from Guerrieri and Iacoviello (2017).' );
disp( 'This figure shows the effect of a gradual increase or decrease in housing prices in their model.' );

disp( 'The model has both an occasionally binding borrowing constraint, and a zero lower bound on nominal interst rates.' );
disp( 'However, for Figure 3, the ZLB plays no role.' );

disp( 'Would you like to include the ZLB? (This makes it marginally slower.)' );
Input = strtrim( lower( input( 'Press y then return to include it, or just return to only include the borrowing constraint: ', 's' ) ) );

if ( length( Input ) ~= 1 ) || ( Input( 1 ) ~= 'y' )
    ReplicateFigure3;
else
    ReplicateFigure3NoZLB;
end

