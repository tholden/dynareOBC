var y pi i d;

varexo e;

parameters beta, sigma, theta, phi, rho;

beta = 0.99;
sigma = 1;
theta = 0.85;
phi = 2;
rho = 0.5;

model;
	#gamma = ( 1 - theta ) * ( 1 - theta * beta ) / theta * ( sigma + phi );
	#i_bar = 1 - beta;
	#ee = 0.01 * e;
	y = y(+1) - 1 / sigma * ( i - i_bar - pi(+1) - ee );
	pi = beta * pi(+1) + gamma * y;
	d =  ( 1 - rho ) * ( i_bar + 1.5 * pi + 1.51 * ( y - y(-1) ) ) + rho * d(-1);
	i = max( 0, d );
end;

steady_state_model;
	y = 0;
	pi = 0;
	i = 1 - beta;
	d = 1 - beta;
end;

shocks;
	var e = 1;
end;

stoch_simul( order = 1, periods = 0, irf = 0 ) y pi i;
