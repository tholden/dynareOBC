var i r pi;

varexo epsilon;

parameters r_ phi;

r_  = log( 1 / 0.99 );
phi = 1.5;

model;
    r = r_ + epsilon;
    i = max( 0, r + phi * pi );
    i = r + pi(+1);
end;

shocks;
    var epsilon = 0.01;
end;

steady_state_model;
    i  = r_;
    r  = r_;
    pi = 0;
end;

stoch_simul( order = 1, irf = 0, periods = 0 );
