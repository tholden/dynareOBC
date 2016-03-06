var A, B, lambdaY;
varexo epsilon;

parameters beta, mu, rho, sigma, Ybar, R;

beta = 0.99;
mu = 0.5;
rho = 0.95;
sigma = 0.05;
Ybar = 0.25;
R = 1.01;

external_function( name = QueryGlobalSolution, nargs = 2 );

model;
	#R = 1 / beta;
	#phi = R - 1;
	#Y = max( Ybar, A );
	#C = max( 0, 1 - lambdaY );
	#ShadowC = max( 0, 1 - beta * R * lambdaY(+1) );
	B = max( -Ybar / ( R - 1 ), Y + R * B(-1) - ShadowC );
	Y = C + B - R * B(-1);
	A = ( 1 - rho ) * mu + rho * A(-1) + sigma * epsilon;
	#CError = C - log( QueryGlobalSolution( B(-1), A ) );
end;

steady_state_model;
	A = mu;
	B = -Ybar / ( R - 1 );
	lambdaY = 1 + Ybar - mu;
end;

shocks;
	var epsilon = 1;
end;

stoch_simul( order = 2, periods = 1023, irf = 0 ) CError;
