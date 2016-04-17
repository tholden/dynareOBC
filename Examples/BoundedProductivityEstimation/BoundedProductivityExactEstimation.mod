var g;

parameters beta gamma gBar sigma rho phi;
beta = 0.99;
gamma = 5;
gBar = 0.005;
rho = 0.95;
sigma = 0.007;
phi = 0.001;

varexo epsilon;

model;
	g = max( phi, ( 1 - rho ) * gBar + rho * g(-1) + sigma * epsilon );
	#mu = ( 1 - rho ) * gBar + rho * g;
	#Int = ( 1 - normcdf( ( mu - phi ) / sigma ) ) * exp( - gamma * phi ) + exp( ( 1 / 2 ) * sigma ^ 2 * gamma ^ 2 - gamma * mu ) * ( 1 - normcdf( ( gamma * sigma ^ 2 + phi - mu ) / sigma ) );
	#rObs = -log( beta * Int );
end;

shocks;
	var epsilon = 1;
end;

steady_state_model;
	g = gBar;
end;

steady;
check;

stoch_simul( order = 1, periods = 0, irf = 0 );