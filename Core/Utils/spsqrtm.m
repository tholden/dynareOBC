function x = spsqrtm( x )

    if issparse( x )
        x = spsparse( sqrtm( full( x ) ) );
    else
        x = sqrtm( x );
    end

end
