function Points = SobolSequence( Dimension, NumPoints )
    persistent SobolCache

    if isempty( SobolCache )
        SobolCache = cell( 0, 0 );
    end
    
    if ( size( SobolCache, 1 ) >= Dimension ) && ( size( SobolCache{ Dimension, 1 }, 2 ) >= NumPoints )
        Points = SobolCache{ Dimension, 1 }( :, 1:NumPoints );
        return;
    end
    
    Points = qmc_sequence( Dimension, int64(1), 1, NumPoints );
    SobolCache{ Dimension, 1 } = Points;
end
