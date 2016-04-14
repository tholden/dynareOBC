var g;

parameters beta gamma gBar sigma rho;
beta = 0.99;
gamma = 5;
gBar = 1;
rho = 0;
sigma = 1;

varexo epsilon;

model;
	g = max( 0, ( 1 - rho ) * gBar + rho * g(-1) + sigma * epsilon );
	#mu = ( 1 - rho ) * gBar + rho * g;
	#Int = (erf(sqrt(2) * (-gamma * sigma ^ 2 + mu) / sigma / 2) + 1) * exp(sigma ^ 2 * gamma ^ 2 / 2 - gamma * mu) / 2 - erf(mu / sigma * sqrt(2) / 2) / 2 + 1 / 2;
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

stoch_simul( order = 1, periods = 1100, irf = 0 );