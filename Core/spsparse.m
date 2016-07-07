function x = spsparse( x )

    x = sparse( x );
    x( abs( x ) < 1.81898940354586e-12 ) = 0;

end
