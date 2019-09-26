function PrepareFigure( FontSize, Titles, LaTeX )

    LineWidth = 2;

    h = gcf;
    
    I = length( h.Children );
    
    if nargin < 3
        LaTeX = false;
        if nargin < 2
            Titles = cell( I, 1 );
        end
    end
    
    for i = 1 : I
        
        g = h.Children( i );
        
        set( g, 'FontName', 'TeXGyrePagella' );
        set( g, 'FontSize', FontSize );
        
        if LaTeX
            title( g, Titles{ I + 1 - i }, 'Interpreter', 'latex' );
        else
            title( g, Titles{ I + 1 - i } );
        end
        
        ff = g.Children;
        
        J = length( ff );
        
        for j = 1 : J
            
            f = ff( j );
                       
            Color = f.Color;
            
            if all( Color == 0 )
                f.LineWidth = LineWidth;
            else
                f.LineWidth = 0.5 * LineWidth;
            end
            
            if f.LineStyle( 1 ) ~= ':'
                continue
            end
            
            X = f.XData;
            Y = f.YData;
            
            delete( f );
            
            K = length( X );
            
            for k = 1 : ( K - 1 )
                
                x = linspace( X( k ), X( k + 1 ), 5 );
                y = linspace( Y( k ), Y( k + 1 ), 5 );
                
                line( g, x( 1 : 2 ), y( 1 : 2 ), 'Color', Color, 'LineWidth', LineWidth );
                line( g, x( 4 : 5 ), y( 4 : 5 ), 'Color', Color, 'LineWidth', LineWidth );
                
            end
            
        end
        
    end
    
    drawnow;

end
