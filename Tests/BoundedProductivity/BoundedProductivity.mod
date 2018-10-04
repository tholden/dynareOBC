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
    #Int = ( 1 - normcdf( mu / sigma ) ) + ( 1 - normcdf( ( gamma * sigma ^ 2 - mu ) / sigma ) ) * exp( sigma ^ 2 * gamma ^ 2 / 2 - gamma * mu );
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