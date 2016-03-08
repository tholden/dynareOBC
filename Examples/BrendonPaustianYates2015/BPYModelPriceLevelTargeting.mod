var y p i;
@#ifndef dynareOBC
  var err1 err2 err3;
@#endif

varexo e;

parameters beta, sigma, theta, phi;

beta = 0.99;
sigma = 1;
theta = 0.85;
phi = 2;

model;
  #gamma = ( 1 - theta ) * ( 1 - theta * beta ) / theta * ( sigma + phi );
  #i_bar = 1 - beta;
  #ee = 0.01 * e;
  y = y(+1) - 1 / sigma * ( i - i_bar - p(+1) + p - ee );
  p - p(-1) = beta * p(+1) - beta * p + gamma * y;
  #ii = max( 0, i_bar + p + y );
  i = ii;
@#ifdef dynareOBC
  #err1 = y(+1) - 1 / sigma * ( i - i_bar - p(+1) + p - ee ) - y;
  #err2 = beta * p(+1) - beta * p + gamma * y - p + p(-1);
  #err3 = ii - i;
@#else
  err1 = y(+1) - 1 / sigma * ( i - i_bar - p(+1) + p - ee ) - y;
  err2 = beta * p(+1) - beta * p + gamma * y - p + p(-1);
  err3 = ii - i;
@#endif
end;

steady_state_model;
  y = 0;
  p = 0;
  i = 1 - beta;
@#ifndef dynareOBC
  err1 = 0;
  err2 = 0;
  err3 = 0;
@#endif
end;

@#ifdef dynareOBC
  shocks;
    var e = 1;
  end;
  stoch_simul( order = 1, periods = 0, irf = 20 ) y p i err1 err2 err3;
@#else
  shocks;
    var e;
    periods 1;
    values 1;
  end;
  options_.endogenous_terminal_period = 1;
  simul( periods = 50, maxit=1000 );
  figure;
  plot( oo_.endo_simul' );
@#endif
