var i r pi;

parameters r_ phi psi;

r_  = log( 1 / 0.99 );
phi = 2;
psi = 0.5;

model;
    r = r_;
    i = max( 0, r + phi * pi - psi * pi(-1) );
    i = r + pi(+1);
end;

steady_state_model;
    i  = r_;
    r  = r_;
    pi = 0;
end;

stoch_simul( order = 1, irf = 0, periods = 0 );
