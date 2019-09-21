Titles = { 'Output', 'Consumption', 'Inflation', 'Nom. int. rates', 'Hours', 'Welfare c.e.' };

for i = 1 : 6
    subplot( 3, 2, i );
    set( gca, 'FontName', 'TeXGyrePagella' );
    set( gca, 'FontSize', 22 );
    title( Titles{ i } );
end
