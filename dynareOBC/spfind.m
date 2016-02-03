function [ xi, xj, xs ] = spfind( x )

    x( abs( x ) < eps ) = 0;
    [ xi, xj, xs ] = find( x );

end
