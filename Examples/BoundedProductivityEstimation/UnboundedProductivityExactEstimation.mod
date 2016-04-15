var g;

parameters beta gamma gBar sigma rho;
beta = 0.99;
gamma = 5;
gBar = 1;
rho = 0;
sigma = 1;

varexo epsilon;

model;
	g = ( 1 - rho ) * gBar + rho * g(-1) + sigma * epsilon;
	#mu = ( 1 - rho ) * gBar + rho * g;
	#rObs = -log( beta ) + gamma * mu - gamma ^ 2 * sigma ^ 2 / 2;
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
