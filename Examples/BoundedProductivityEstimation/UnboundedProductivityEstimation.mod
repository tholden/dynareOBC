var g r nothing;

parameters beta gamma gBar sigma rho;
beta = 0.99;
gamma = 5;
gBar = 0.005;
rho = 0.95;
sigma = 0.007;

varexo epsilon;

model;
	g = ( 1 - rho ) * gBar + rho * g(-1) + sigma * epsilon;
	1 = beta * exp( r ) * exp( -gamma * g(+1) );
	nothing = 0;
	#rObs = r;
end;

shocks;
	var epsilon = 1;
end;

steady_state_model;
	g = gBar;
	r = gamma * gBar -log( beta );
	nothing = 0;
end;

steady;
check;

stoch_simul( order = 3, periods = 1100, irf = 0 );