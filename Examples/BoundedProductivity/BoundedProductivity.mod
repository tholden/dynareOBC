var g r;

parameters beta gamma gBar sigma rho;
beta = 0.99;
gamma = 5;
gBar = 0.005;
rho = 0.95;
sigma = 0.007;

varexo epsilon;

model;
	#mu = ( 1 - rho ) * gBar + rho * g;
	#Int = (erf(sqrt(2) * (-gamma * sigma ^ 2 + mu) / sigma / 2) + 1) * exp(sigma ^ 2 * gamma ^ 2 / 2 - gamma * mu) / 2 - erf(mu / sigma * sqrt(2) / 2) / 2 + 1 / 2;
	#rTrue = -log( beta * Int );
	#gTrue = max( 0, ( 1 - rho ) * gBar + rho * g(-1) + sigma * epsilon );
	#rError = r - rTrue;
	#gError = g - gTrue;
	g = gTrue;
	1 = beta * exp( r ) * exp( -gamma * g(+1) );
end;

shocks;
	var epsilon = 1;
end;

steady_state_model;
	g = gBar;
	r = gamma * gBar -log( beta );
end;

steady;
check;

stoch_simul( order = 3, periods = 1100, irf = 0 ) g r gError rError;