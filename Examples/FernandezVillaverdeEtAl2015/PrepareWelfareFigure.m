Titles = { '$C_t$', '$L_t$', '$\Pi_t$', '$\nu_t$', '$R_t$', '$Z_t$ (Welfare c.e.)' };

for i = 1 : 6
    subplot( 3, 2, i );
    set( gca, 'XLim', [ 1, 40 ] );
    set( gca, 'FontName', 'TeXGyrePagella' );
    set( gca, 'FontSize', 22 );
    title( Titles{ i }, 'Interpreter', 'latex' );
end
