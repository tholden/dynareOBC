function Seq = IteratedAitkensDeltaSquaredTransformation( Seq )

    N = size( Seq, 2 );
    
    if N >= 3
    
        if mod( N, 2 ) == 0
            Seq = Seq( :, 2:end );
            N = N - 1;
        end

        for Idx = 1 : ( 0.5 * ( N - 1 ) )

            DSeq = diff( Seq, 1, 2 );

            Seq = Seq( :, 3:end );
            LDSeq = DSeq( :, 1:(end-1) );
            DSeq = DSeq( :, 2:end );

            Adj = DSeq .* DSeq ./ ( DSeq - LDSeq );
            FiniteAdj = isfinite( Adj );

            Seq( FiniteAdj ) = Seq( FiniteAdj ) - Adj( FiniteAdj );

        end
        
    else
        
        Seq = Seq( :, N );
    
    end
    
end
