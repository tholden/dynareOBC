function [ Vnew, Xnew ] = EvaluateValueFunctionOffGrid( B, A, Bv, Av, V, beta, Ybar, R, mu, rho, sigma )
    Wv = GeneratePiecewiseLinearCubatureRule( Av, ( 1 - rho ) * mu + rho * A, sigma );
       
    XB = max( 0, max( Ybar, A ) + R * B + Ybar / ( R - 1 ) );
    
    [ Vnew, Xnew ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, 0, XB, beta, Ybar, R );
end
