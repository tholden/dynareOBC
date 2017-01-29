function [ A, d1, d2, k ] = NormalizeMatrix( A, ZeroTolerance, ConvergenceTolerance )
% http://www.numerical.rl.ac.uk/reports/drRAL2001034.pdf
% Finds d1 and d2 such that Aout = diag( d1 ) * A * diag( d2 ) (approximately) satisfies all( sum( abs( Aout ) ) == 1 ) && all( sum( abs( Aout ), 2 ) == 1 )

    [ m, n ] = size( A );
    
    d1 = ones( m, 1 );
    d2 = ones( 1, n );

    k = 0;
    while true
        r = Check( max( abs( A ), [], 2 ), ZeroTolerance );
        c = Check( max( abs( A ) ), ZeroTolerance );
        IdR = 1 ./ sqrt( r );
        IdC = 1 ./ sqrt( c );
        A = bsxfun( @times, IdR, bsxfun( @times, A, IdC ) );
        d1 = d1 .* IdR;
        d2 = d2 .* IdC;
        k = k + 1;
        if k > 100 || ( max( abs( 1 - r ) ) <= ConvergenceTolerance && max( abs( 1 - c ) ) <= ConvergenceTolerance )
            break;
        end
    end
end

function v = Check( v, ZeroTolerance )
    v( any( v <= ZeroTolerance ) ) = 1;
end
