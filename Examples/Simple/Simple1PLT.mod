var i r pi p;

varexo epsilon;

parameters r_ phi chi;

r_  = log( 1 / 0.99 );
phi = 1.5;
chi = 0.01;

model;
    r = r_ + epsilon;
    i = max( 0, r + phi * pi + chi * p );
    i = r + pi(+1);
    p = p(-1) + pi;
end;

shocks;
    var epsilon = 0.01;
end;

steady_state_model;
    i  = r_;
    r  = r_;
    pi = 0;
    p  = 0;
end;

stoch_simul( order = 1, irf = 0, periods = 0 );
