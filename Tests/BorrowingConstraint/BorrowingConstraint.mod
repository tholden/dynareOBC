var A, B, X, lambdaY;
varexo epsilon;

parameters beta, mu, rho, sigma, Ybar;

beta = 0.99;
mu = 0.5;
rho = 0.95;
sigma = 0.05;
Ybar = 0.25;

external_function( name = QueryGlobalSolution, nargs = 2 );

model;
    #R = 1 / beta;
    #phi = R - 1;
    min( 1, X ) = max( 0, 1 - lambdaY );
    B = max( -Ybar / ( R - 1 ), 1 / phi * ( lambdaY(+1) - lambdaY ) );
    X = max( Ybar, A ) + R * B(-1) - B; 
    A = ( 1 - rho ) * mu + rho * A(-1) + sigma * epsilon;
    #XError = X - QueryGlobalSolution( B(-1), A );
end;

steady_state_model;
    A = mu;
    B = 0;
    X = mu;
    lambdaY = 1 - mu;
end;

shocks;
    var epsilon = 1;
end;

stoch_simul( order = 1, periods = 1100, irf = 0 ) XError;
