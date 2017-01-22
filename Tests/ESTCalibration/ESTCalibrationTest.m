clear all; %#ok<CLALL>
addpath ../../Core

Order = 14;
N = 3;

xi = 10 * randn( N, 1 );
RootOmega = 0.1 * randn( N, N );
Omega = RootOmega * RootOmega';
delta = randn( N, 1 );
tau = randn;
nu = 4.5 + 4 * randn ^ 2;

disp( 'tau, nu:' );
disp( [ tau, nu ] );

[ Weights, pTmp, T ] = fwtpts( N + 2, Order );
disp( 'T:' );
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
Sigma = NearestSPD( Sigma );

lambda = ESTPoints( :, 1 );

tpdfRatio = tpdf( tau, nu ) / tcdf_tau_nu;
tauTtau = tau * tau;
OPtauTtauDnu = 1 + tauTtau / nu;
ET1 = nu / ( nu - 1 ) * OPtauTtauDnu * tpdfRatio;
xiAlt = mu - delta * ET1;

MedT = tinv( tcdf_tau_nu + ( 1 - tcdf_tau_nu ) * 0.5, nu );
lambdaAlt = xi + delta * MedT;

disp( 'xi, xiAlt:' );
disp( [ xi, xiAlt ] );

disp( 'lambda, lambdaAlt:' );
disp( [ lambda, lambdaAlt ] );

disp( 'mu - lambda, delta:' );
disp( [ mu - lambda, delta ] );

Zcheck = ( ( mu - lambda )' * DemeanedESTPoints ) / sqrt( ( mu - lambda )' * Sigma * ( mu - lambda ) );

meanZcheck = Zcheck * Weights';
meanZcheck2 = Zcheck.^2 * Weights';

disp( 'EZ, EZ^2:' );
disp( [ meanZcheck, meanZcheck2 ] );

Zcheck = Zcheck - meanZcheck;
Zcheck = Zcheck / meanZcheck2;

[ fZcheck, xiZcheck ] = ksdensity( Zcheck, linspace( min( Zcheck ), max( Zcheck ), 2000 ), 'NumPoints', 2000, 'Weights', Weights );
fZcheck = max( 0, fZcheck );
fZcheck = fZcheck / sum( fZcheck );
idx1Zcheck = find( fZcheck / max( fZcheck ) > 0.005, 1 );
idx2Zcheck = find( fZcheck / max( fZcheck ) > 0.005, 1, 'last' );
plot( xiZcheck( idx1Zcheck : idx2Zcheck ), fZcheck( idx1Zcheck : idx2Zcheck ) );

sZ3 = Zcheck.^3 * Weights';
sZ4 = Zcheck.^4 * Weights';

disp( 'EZ^3, EZ^3:' );
disp( [ sZ3, sZ4 ] );

[ resid, xiHat, deltaHat, OmegaHat ] = CalibrateMomentsEST( tau, nu, mu, lambda, Sigma, sZ3, sZ4 );

disp( 'at truth:' );
disp( 'resid:' );
disp( resid' );
disp( 'xi comparison:' );
disp( [ xi, xiHat ] );
disp( 'delta comparison:' );
disp( [ delta, deltaHat ] );
disp( 'diag( Omega ) comparison:' );
disp( [ diag( Omega ), diag( OmegaHat ) ] );

Estim4 = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), in( 2 ), mu, lambda, Sigma, sZ3, sZ4 ), [ tau; nu ], [ -Inf; 4 ], [], optimoptions( @lsqnonlin, 'display', 'iter', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );
Estim3 = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), nu, mu, lambda, Sigma, sZ3, [] ), tau, [], [], optimoptions( @lsqnonlin, 'display', 'iter', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );

disp( 'Estim4 Estim3 Truth:' );
disp( [ Estim4( 1 ), Estim3, tau; Estim4( 2 ), nu, nu ] );

[ resid, xiHat, deltaHat, OmegaHat ] = CalibrateMomentsEST( Estim4( 1 ), Estim4( 2 ), mu, lambda, Sigma, sZ3, sZ4 );

disp( 'at Estim4:' );
disp( 'resid:' );
disp( resid' );
disp( 'xi comparison:' );
disp( [ xi, xiHat ] );
disp( 'delta comparison:' );
disp( [ delta, deltaHat ] );
disp( 'diag( Omega ) comparison:' );
disp( [ diag( Omega ), diag( OmegaHat ) ] );

[ resid, xiHat, deltaHat, OmegaHat ] = CalibrateMomentsEST( Estim3( 1 ), nu, mu, lambda, Sigma, sZ3, sZ4 );

disp( 'at Estim3:' );
disp( 'resid:' );
disp( resid' );
disp( 'xi comparison:' );
disp( [ xi, xiHat ] );
disp( 'delta comparison:' );
disp( [ delta, deltaHat ] );
disp( 'diag( Omega ) comparison:' );
disp( [ diag( Omega ), diag( OmegaHat ) ] );
