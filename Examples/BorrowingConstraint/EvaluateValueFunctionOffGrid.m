function [ Vnew, Xnew ] = EvaluateValueFunctionOffGrid( B, A, Bv, Av, V, X, beta, Ybar, R, mu, rho, sigma )
    Wv = GeneratePiecewiseLinearCubatureRule( Av, ( 1 - rho ) * mu + rho * A, sigma );
       
    nB = length( Bv );
    nA = length( Av );
    
    BIndex = 1 + ( nB - 1 ) * ( k - Bv( 1 ) ) / ( Bv( end ) - Bv( 1 ) );
    BlIndex = max( 1, min( nB - 1, floor( BIndex ) ) );
    BuIndex = BlIndex + 1;
    BfIndex = BIndex - BlIndex;

    AIndex = 1 + ( nA - 1 ) * ( a - Av( 1 ) ) / ( Av( end ) - Av( 1 ) );
    AlIndex = max( 1, min( nA - 1, floor( AIndex ) ) );
    AuIndex = AlIndex + 1;
    AfIndex = AIndex - AlIndex;
    
    XL = 0;
    XU = max( 0, max( Ybar, A ) + R * B + Ybar / ( R - 1 ) );
    
    if AfIndex >= 0 && BfIndex >= 0
        XL = max( XL, X( AlIndex, BlIndex ) );
    end
    if AuIndex <= 1 && BuIndex <= 0
        XU = min( XU, X( AuIndex, BuIndex ) );
    end
    
    XG = ( 1 - AfIndex ) * ( ( 1 - BfIndex ) * X( AlIndex, BlIndex ) + BfIndex * X( AlIndex, BuIndex ) ) + AfIndex * ( ( 1 - BfIndex ) * X( AuIndex, BlIndex ) + BfIndex * X( AuIndex, BuIndex ) );

    [ Vnew, Xnew ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, max( max( V ) ), XL, XG, XU, beta, Ybar, R );
end
