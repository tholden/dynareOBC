Titles = { '$Y_t$', '$\Pi_t$', '$R_t$', '$\nu_t$' };

for i = 1 : 4
    subplot( 2, 2, i );
    set( gca, 'FontName', 'TeXGyrePagella' );
    set( gca, 'FontSize', 26 );
    title( Titles{ i }, 'Interpreter', 'latex' );
end
