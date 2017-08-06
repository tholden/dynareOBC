function Seq = WynnEpsilonTransformation( Seq )

    [ M, N ] = size( Seq );
    
    if N >= 3
    
        if mod( N, 2 ) == 0
            Seq = Seq( :, 2 : end );
        end
        
        RS = RandStream( 'mt19937ar' );
        
        Seq = DoubleDouble.Plus( Seq, eps( Seq ) .* ( RS.rand( size( Seq ) ) - 0.5 ) ); % adding a little noise helps prevent explosions
        
        OSeq = Seq;
        
        OOSeq = zeros( M, size( OSeq, 2 ) + 1 );
        
        Seq = InverseDifference( Seq( :, 2 : end ), Seq( :, 1 : ( end - 1 ) ) );
        
        NSeq = OSeq( :, 2 : end - 1 ) + InverseDifference( Seq( :, 2 : end ), Seq( :, 1 : ( end - 1 ) ) );
        
        OOOSeq = OOSeq;
        
        OOSeq = OSeq;
        
        OSeq = Seq;
        
        Seq = NSeq;
        
        LimitEst = Seq( :, end );

        while size( Seq, 2 ) > 1

            NSeq1 = OSeq( :, 2 : end - 1 ) + InverseDifference( Seq( :, 2 : end ), Seq( :, 1 : ( end - 1 ) ) );
            
            a = OSeq( :, 3 : end ) ./ ( 1 - OSeq( :, 3 : end ) ./ OSeq( :, 2 : end - 1 ) ) + OSeq( :, 1 : end - 2 ) ./ ( 1 - OSeq( :, 1 : end - 2 ) ./ OSeq( :, 2 : end - 1 ) ) - OOOSeq( :, 3 : end - 2 ) ./ ( 1 - OOOSeq( :, 3 : end - 2 ) ./ OSeq( :, 2 : end - 1 ) );
            
            NSeq2 = a ./ ( 1 + a ./ OSeq( :, 2 : end - 1 ) );
            
            OOOSeq = OOSeq;

            OOSeq = OSeq;

            OSeq = Seq;

            Seq1 = NSeq1;

            Seq2 = NSeq2;
            
            NSeq11 = OSeq( :, 2 : end - 1 ) + InverseDifference( Seq1( :, 2 : end ), Seq1( :, 1 : ( end - 1 ) ) );
            
            NSeq12 = OSeq( :, 2 : end - 1 ) + InverseDifference( Seq2( :, 2 : end ), Seq2( :, 1 : ( end - 1 ) ) );
            
            a = OSeq( :, 3 : end ) ./ ( 1 - OSeq( :, 3 : end ) ./ OSeq( :, 2 : end - 1 ) ) + OSeq( :, 1 : end - 2 ) ./ ( 1 - OSeq( :, 1 : end - 2 ) ./ OSeq( :, 2 : end - 1 ) ) - OOOSeq( :, 3 : end - 2 ) ./ ( 1 - OOOSeq( :, 3 : end - 2 ) ./ OSeq( :, 2 : end - 1 ) );
            
            NSeq2 = a ./ ( 1 + a ./ OSeq( :, 2 : end - 1 ) );
            
            OOOSeq = OOSeq;

            OOSeq = OSeq;

            OSeq = Seq1;
            
            Seq = NSeq11;
            
            Select = ( abs( NSeq11 - LimitEst ) > abs( NSeq12 - LimitEst ) ) | isnan( NSeq11 );
            
            OSeq( Select ) = Seq2( Select );
            
            Seq( Select ) = NSeq12( Select );
            
            Select = ( abs( Seq - LimitEst ) > abs( NSeq2 - LimitEst ) ) | isnan( Seq );
            
            Seq( Select ) = NSeq2( Select );

            LimitEst = Seq( :, end );

        end
        
        Seq = double( Seq );
        
    else
        
        Seq = Seq( :, end );
    
    end
    
end

function v = InverseDifference( a, b )
    d = DoubleDouble.Minus( a, b );
    d( ( 0 <= d ) & ( d < DoubleDouble.eps ) ) = DoubleDouble.eps;
    d( ( 0 > d ) & ( d > -DoubleDouble.eps ) ) = DoubleDouble.eps;
    v = 1 ./ d;
end
