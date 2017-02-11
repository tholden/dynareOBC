function x = clamp( xmean, dx, LB, UB, A, b )
    dxpos = dx > 0;
    dxneg = dx < 0;
    Adx = A * dx;
    Adxpos = Adx > 0;
    alpha = min( [ 1; ( b( Adxpos ) - A( ( Adxpos ), : ) * xmean ) ./ Adx( Adxpos ); ( LB( dxneg ) - xmean( dxneg ) ) ./ dx( dxneg ); ( UB( dxpos ) - xmean( dxpos ) ) ./ dx( dxpos ) ] );
    x = xmean + alpha * dx;
end
