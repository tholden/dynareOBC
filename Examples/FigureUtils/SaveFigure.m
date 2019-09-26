function SaveFigure( Size, FileName, Colour )

    if nargin < 3
        Colour = false;
    end

    addpath( '../../Extern/export_fig' );
    
    h = gcf;
    
    set( h, 'Renderer', 'opengl' ); % painters
    
    set( h, 'Color', 'w' );
    
    if ~isempty( Size )
        set( h, 'units', 'normalized', 'outerposition', [ 0 0 Size( 1 ) Size( 2 ) ] );
    end
    
    savefig( h, FileName, 'compact' );
    
    warning( 'off', 'MATLAB:LargeImage' );
    
    if Colour
        export_fig( h, [ FileName '.png' ], '-r864', '-opengl', '-a1' );
    else
        export_fig( h, [ FileName '.png' ], '-r864', '-opengl', '-a1', '-grey' );
    end

    warning( 'on', 'MATLAB:LargeImage' );

end
