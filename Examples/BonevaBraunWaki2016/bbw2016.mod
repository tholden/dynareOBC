var y pi z d r;
parameters sigma nu beta theta gamma pi_STEADY phi_pi phi_y eta tauw rhod sigmad rhoz sigmaz;
varexo epsilond epsilonz;

beta = 0.997;
theta = 7.67;
eta = 0.2;
tauw = 0.2;
gamma = 495.8;
nu = 0.37;
phi_pi = 1.67;
phi_y = 0.31;
sigma = 1;
rhod = 0.89;
rhoz = 0.95;
sigmad = 0.0021;
sigmaz = 0.007;

pi_STEADY = 0;

model;
    #Pi = exp( pi );
    #Pi_LEAD = exp( pi(+1) );
    #Pi_STEADY = exp( pi_STEADY );
    #kappa = ( gamma / 2 ) * ( Pi - 1 ) ^ 2;
    #kappa_STEADY = ( gamma / 2 ) * ( Pi_STEADY - 1 ) ^ 2;
    #c = log( 1 - kappa - eta ) + y;
    #c_LEAD = log( 1 - ( gamma / 2 ) * ( Pi_LEAD - 1 ) ^ 2 - eta ) + y(+1);
    #h = y - z;
    #w = sigma * c + nu * h - log( 1 - tauw );
    #re = -log( beta ) - d(+1) + pi_STEADY;
    #y_STEADY = ( 1 / ( sigma + nu ) ) * ( log( ( 1 - tauw ) * ( ( 1 - beta ) * ( Pi_STEADY - 1 ) * Pi_STEADY / theta * gamma + 1 ) ) - sigma * log( 1 - kappa_STEADY - eta ) );
    #gdp = log( 1 - kappa ) + y;
    #gdp_STEADY = log( 1 - kappa_STEADY ) + y_STEADY;
    r = max( 0, re + phi_pi * ( pi - pi_STEADY ) + phi_y * ( gdp - gdp_STEADY ) );
    1 = beta * exp( d(+1) + r - pi(+1) + sigma * ( c - c_LEAD ) );
    ( Pi - 1 ) * Pi = theta / gamma * ( exp( w - z ) - 1 ) + beta * exp( d(+1) + sigma * ( c - c_LEAD ) + y(+1) - y ) * ( Pi_LEAD - 1 ) * Pi_LEAD;
    d = rhod * d(-1) + sigmad * epsilond;
    z = rhoz * z(-1) + sigmaz * epsilonz;
end;

steady_state_model;
    Pi_ = exp( pi_STEADY );
    kappa_ = ( gamma / 2 ) * ( Pi_ - 1 ) ^ 2;
    y = ( 1 / ( sigma + nu ) ) * ( log( ( 1 - tauw ) * ( ( 1 - beta ) * ( Pi_ - 1 ) * Pi_ / theta * gamma + 1 ) ) - sigma * log( 1 - kappa_ - eta ) );
    pi = pi_STEADY;
    z = 0;
    d = 0;
    r = -log( beta ) + pi_STEADY;
end;

shocks;
    var epsilond = 1;
    var epsilonz = 1;
end;

steady;
check;

stoch_simul( order = 1, periods = 0, irf = 40 );
