Titles = { 'Output', 'Consumption', 'Inflation', 'Nominal interest rates' };

for i = 1 : 4
    subplot( 2, 2, i );
    set( gca, 'FontName', 'TeXGyrePagella' );
    set( gca, 'FontSize', 26 );
    title( Titles{ i } );
end
