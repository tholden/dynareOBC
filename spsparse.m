function x = spsparse( x )

    x = sparse( x );
    x( abs( x ) < eps ) = 0;

end
