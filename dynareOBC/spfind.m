function [ xi, xj, xs ] = spfind( x )

   [ xi, xj, xs ] = find( abs( x ) > eps );

end
