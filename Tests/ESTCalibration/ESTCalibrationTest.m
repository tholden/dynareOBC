addpath ../../Core

T = 100000;
N = 10;

xi = 10 * randn( N, 1 );
RootOmega = 0.1 * randn( N, N );
Omega = RootOmega * RootOmega';
delta = randn( N, 1 );
tau = randn ^ 2;
nu = 80.5 + 4 * randn ^ 2;
log_nuM4 = log( nu - 4 );

PhiN0 = rand( 1, T );
PhiN10 = rand( 1, T );
pTmp = randn( N, T );

FInvScaledInvChi = sqrt( 0.5 * ( nu + 1 ) ./ gammaincinv( PhiN10, 0.5 * ( nu + 1 ), 'upper' ) );
tcdf_tau_nu = tcdf( tau, nu );
FInvEST = tinv( tcdf_tau_nu + ( 1 - tcdf_tau_nu ) * PhiN0, nu );
N11Scaler = FInvScaledInvChi .* sqrt( ( nu + FInvEST .^ 2 ) / ( 1 + nu ) );

ESTPoints = bsxfun( @plus, RootOmega * bsxfun( @times, pTmp, N11Scaler ) + bsxfun( @times, delta, FInvEST ), xi );

mu = mean( ESTPoints, 2 );
Sigma = cov( ESTPoints' );

DemeanedESTPoints = bsxfun( @minus, ESTPoints, mu );

lambda = mu + delta * median( delta' * DemeanedESTPoints ); % slight cheat to get lambda

Zcheck = ( ( mu - lambda )' * DemeanedESTPoints ) / sqrt( ( mu - lambda )' * Sigma * ( mu - lambda ) );

disp( mean( Zcheck ) );
disp( mean( Zcheck.^2 ) );

Zcheck = Zcheck - mean( Zcheck );
Zcheck = Zcheck / sqrt( mean( Zcheck.^2 ) );

hist( Zcheck, 100 );

sZ3 = mean( Zcheck.^3 );
sZ4 = mean( Zcheck.^4 );

out1 = fsolve( @( in ) CalibrateMomentsEST( in( 1 ), in( 2 ), mu, lambda, Sigma, sZ3, sZ4 ), [ tau; log_nuM4 ], optimoptions( @fsolve, 'display', 'iter' ) );
out2 = fsolve( @( in ) CalibrateMomentsEST( in( 1 ), log_nuM4, mu, lambda, Sigma, sZ3, [] ), tau, optimoptions( @fsolve, 'display', 'iter' ) );

disp( [ out1( 1 ), out2, tau; out1( 2 ), log_nuM4, log_nuM4 ] );
