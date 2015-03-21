function [ xi, xj, xs ] = spfind( x )

   [ xi, xj, xs ] = find( x );
   xs( abs( xs ) < eps ) = 0;

end
