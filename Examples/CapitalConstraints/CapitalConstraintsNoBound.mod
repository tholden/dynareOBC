var a, c, k;
varexo epsilon;

parameters alpha, beta, nu, theta, rho, sigma;

alpha = 0.3;
beta = 0.99;
nu = 2;
theta = 0.99;
rho = 0.95;
sigma = 0.01;

external_function( name = QueryGlobalSolutionNoBound, nargs = 2 );

model;
	#l = 1 / ( alpha + nu ) * ( log( 1 - alpha ) + a + alpha * k(-1) - c );
	#y = a + alpha * k(-1) + ( 1 - alpha ) * l;
	#LEAD_l = 1 / ( alpha + nu ) * ( log( 1 - alpha ) + a(+1) + alpha * k - c(+1) );
	#LEAD_y = a(+1) + alpha * k + ( 1 - alpha ) * LEAD_l;
	exp( -c ) = alpha * beta * exp( LEAD_y - c(+1) - k );
	// exp( y ) = exp( c ) + exp( k );
	exp( -c ) = 1 / ( exp( y ) - exp( k ) );
	a = rho * a(-1) + sigma * epsilon;
	#cError = c - log( QueryGlobalSolutionNoBound( k(-1), a ) );
end;

steady_state_model;
	a = 0;
	k = 1 / ( 1 - alpha ) * ( log( alpha * beta ) + a + ( ( 1 - alpha ) / ( 1 + nu ) ) * log( ( 1 - alpha ) / ( 1 - alpha * beta ) ) );
	y_ = a + alpha * k + ( ( 1 - alpha ) / ( 1 + nu ) ) * log( ( 1 - alpha ) / ( 1 - alpha * beta ) );
	c = log( 1 - alpha * beta ) + y_;
end;

shocks;
	var epsilon = 1;
end;

stoch_simul( order = 1, periods = 1023, irf = 0 ) cError;
