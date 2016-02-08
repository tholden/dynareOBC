var a, c, k, lambda;
varexo epsilon;

parameters alpha, beta, nu, theta, rho, sigma;

alpha = 0.3;
beta = 0.99;
nu = 2;
theta = 0.99;
rho = 0.95;
sigma = 0.01;

external_function( name = QueryGlobalSolution, nargs = 2 );

model;
	#l = 1 / ( alpha + nu ) * ( log( 1 - alpha ) + a + alpha * k(-1) - c );
	#y = a + alpha * k(-1) + ( 1 - alpha ) * l;
	#LEAD_l = 1 / ( alpha + nu ) * ( log( 1 - alpha ) + a(+1) + alpha * k - c(+1) );
	#LEAD_y = a(+1) + alpha * k + ( 1 - alpha ) * LEAD_l;
	exp( -c ) - lambda = alpha * beta * exp( LEAD_y - c(+1) - k ) - beta * theta * lambda(+1);
	exp( c ) = exp( y ) - exp( k );
	exp( -c ) = max( alpha * beta * exp( LEAD_y - c(+1) - k ) - beta * theta * lambda(+1), 1 / ( exp( y ) - theta * exp( k(-1) ) ) );
	a = rho * a(-1) + sigma * epsilon;
	#cError = c - log( QueryGlobalSolution( k(-1), a ) );
end;

steady_state_model;
	a = 0;
	k = 1 / ( 1 - alpha ) * ( log( alpha * beta ) + a + ( ( 1 - alpha ) / ( 1 + nu ) ) * log( ( 1 - alpha ) / ( 1 - alpha * beta ) ) );
	y_ = a + alpha * k + ( ( 1 - alpha ) / ( 1 + nu ) ) * log( ( 1 - alpha ) / ( 1 - alpha * beta ) );
	c = log( 1 - alpha * beta ) + y_;
	lambda = 0;
end;

shocks;
	var epsilon = 1;
end;

stoch_simul( order = 2, periods = 1023, irf = 0 ) cError;
