Titles = { '$x_{y,t}$', '$x_{\pi,t}$', '$x_{i,t}$' };

for i = 1 : 3
    subplot( 3, 1, i );
    set( gca, 'FontName', 'TeXGyrePagella' );
    set( gca, 'FontSize', 40 );
    title( Titles{ i }, 'Interpreter', 'latex' );
end
