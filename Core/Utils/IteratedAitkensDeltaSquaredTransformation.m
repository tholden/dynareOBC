function Seq = IteratedAitkensDeltaSquaredTransformation( Seq )

    N = size( Seq, 2 );
    
    e = eps;
    se = sqrt( e );
    
    if N >= 3
    
        if mod( N, 2 ) == 0
            Seq = Seq( :, 2:end );
            N = N - 1;
        end

        for Idx = 1 : ( 0.5 * ( N - 1 ) )
            
            Width = max( Seq ) - min( Seq );

            DSeq = diff( Seq, 1, 2 );

            Seq = Seq( :, 3:end );
            LDSeq = DSeq( :, 1:(end-1) );
            DSeq = DSeq( :, 2:end );
            
            Top = DSeq .* DSeq;
            Bottom = DSeq - LDSeq;
            
            aTop = abs( Top );
            aBottom = abs( Bottom );

            GoodAdj = ( aBottom > e ) && ( max( aTop, aBottom ) > se );

            Seq( GoodAdj ) = Seq( GoodAdj ) - max( -Width, min( Width, Top( GoodAdj ) ./ Bottom( GoodAdj ) ) );

        end
        
    else
        
        Seq = Seq( :, N );
    
    end
    
end
