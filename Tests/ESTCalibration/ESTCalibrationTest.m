clear all;
addpath ../../Core

Order = 14;
N = 3;

xi = 10 * randn( N, 1 );
RootOmega = 0.1 * randn( N, N );
Omega = RootOmega * RootOmega';
delta = randn( N, 1 );
tau = randn ^ 2;
nu = 8.5 + 4 * randn ^ 2;
log_nuM4 = log( nu - 4 );

[ Weights, pTmp, T ] = fwtpts( N + 2, Order );
disp( T );
PhiN0 = normcdf( pTmp( end - 1, : ) );
PhiN10 = normcdf( pTmp( end, : ) );

FInvScaledInvChi = sqrt( 0.5 * ( nu + 1 ) ./ gammaincinv( PhiN10, 0.5 * ( nu + 1 ), 'upper' ) );
tcdf_tau_nu = tcdf( tau, nu );
FInvEST = tinv( tcdf_tau_nu + ( 1 - tcdf_tau_nu ) * PhiN0, nu );
N11Scaler = FInvScaledInvChi .* sqrt( ( nu + FInvEST .^ 2 ) / ( 1 + nu ) );

ESTPoints = bsxfun( @plus, RootOmega * bsxfun( @times, pTmp( 1:(end-2), : ), N11Scaler ) + bsxfun( @times, delta, FInvEST ), xi );

mu = sum( bsxfun( @times, ESTPoints, Weights ), 2 );
DemeanedESTPoints = bsxfun( @minus, ESTPoints, mu );
Weighted_DemeanedESTPoints = bsxfun( @times, DemeanedESTPoints, Weights );

Sigma = DemeanedESTPoints * Weighted_DemeanedESTPoints';
Sigma = 0.5 * ( Sigma + Sigma' );

lambda = ESTPoints( :, 1 );

Zcheck = ( ( mu - lambda )' * DemeanedESTPoints ) / sqrt( ( mu - lambda )' * Sigma * ( mu - lambda ) );

disp( Zcheck * Weights' );
disp( Zcheck.^2 * Weights' );

Zcheck = Zcheck - mean( Zcheck );
Zcheck = Zcheck / sqrt( mean( Zcheck.^2 ) );

hist( Zcheck, 100 );

sZ3 = Zcheck.^3 * Weights';
sZ4 = Zcheck.^4 * Weights';

disp( [ sZ3 sZ4 ] );

out1 = fsolve( @( in ) CalibrateMomentsEST( in( 1 ), in( 2 ), mu, lambda, Sigma, sZ3, sZ4 ), [ tau; log_nuM4 ], optimoptions( @fsolve, 'display', 'iter' ) );
out2 = fsolve( @( in ) CalibrateMomentsEST( in( 1 ), log_nuM4, mu, lambda, Sigma, sZ3, [] ), tau, optimoptions( @fsolve, 'display', 'iter' ) );

disp( [ out1( 1 ), out2, tau; out1( 2 ), log_nuM4, log_nuM4 ] );
