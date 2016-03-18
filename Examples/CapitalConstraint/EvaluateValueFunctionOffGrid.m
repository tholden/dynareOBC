function [ Vnew, Cnew, CBnew ] = EvaluateValueFunctionOffGrid( k, a, kv, av, V, CB, alpha, beta, nu, theta, rho, sigma )
    Wv = GeneratePiecewiseLinearCubatureRule( av, rho * a, sigma );
    nk = length( kv );
    na = length( av );
    
    kIndex = 1 + ( nk - 1 ) * ( k - kv( 1 ) ) / ( kv( end ) - kv( 1 ) );
    klIndex = max( 1, min( nk - 1, floor( kIndex ) ) );
    kuIndex = klIndex + 1;
    kfIndex = kIndex - klIndex;

    aIndex = 1 + ( na - 1 ) * ( a - av( 1 ) ) / ( av( end ) - av( 1 ) );
    alIndex = max( 1, min( na - 1, floor( aIndex ) ) );
    auIndex = alIndex + 1;
    afIndex = aIndex - alIndex;
    
    CBg = ( 1 - afIndex ) * ( ( 1 - kfIndex ) * CB( alIndex, klIndex ) + kfIndex * CB( alIndex, kuIndex ) ) + afIndex * ( ( 1 - kfIndex ) * CB( auIndex, klIndex ) + kfIndex * CB( auIndex, kuIndex ) );
    
    [ Vnew, Cnew, CBnew ] = EvaluateValueFunctionAtPoint( k, a, Wv, kv, V, CBg, alpha, beta, nu, theta );
end
