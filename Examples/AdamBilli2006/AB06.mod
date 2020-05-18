// Derived from code originally written by Shifu Jiang

var y pi i gam1 gam2 u g; // wel
varexo eps_u eps_g;

parameters beta lambda kappa sigma;

beta   = 1/(1+3.5/400);
sigma  = 6.25;
alpha  = 0.66;
theta  = 7.66;
omega  = 0.47; 

kappa  = (1-alpha)*(1-alpha*beta)/alpha*(1/sigma+omega)/(1+omega*theta);
lambda = kappa/theta;

model;
    // wel = -pi^2 - lambda*y^2 + beta*wel(+1);
    pi = beta*pi(+1) + kappa*y + u;
    y = y(+1) - sigma*(i-pi(+1)) + g;

    // mu1( 0 ) = gam1( -1 );
    // mu2( 0 ) = gam2( -1 );

    0 = -2*lambda*y - kappa*gam1 - gam2 + gam2(-1)/beta;
    0 = -2*pi + gam1 - gam1(-1) + gam2(-1)*sigma/beta;
    0 = min( gam2, i + 1/beta-1 );

    u = -0.00154 * eps_u;
    g = 0.8 * g(-1) - 0.01524 * eps_g;
end;
 
steady_state_model;
    // wel=0;
    pi=0;
    y=0;
    i=0;
    gam1=0;
    gam2=0;
    u=0;
    g=0;
end;

shocks;
    var eps_u = 1;
    var eps_g = 1;
end;

steady;
check;

stoch_simul( irf=0, periods=1, drop=1, order=1, pruning, nocorr, nodecomposition, nofunctions );
