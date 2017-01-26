clear all; %#ok<CLALL>
addpath ../../Core

Order = 4;
N = 10;

xi = 10 * randn( N, 1 );
RootOmega = 0.1 * randn( N, N );
Omega = RootOmega * RootOmega';
[ Omega, cholOmega ] = NearestSPD( Omega );
delta = randn( N, 1 );
tau = 10 * randn;
nu = 4.5 + 4 * randn ^ 2; % Inf;

disp( 'tau, nu:' );
disp( [ tau, nu ] );

IntDim = N + 2;

tcdf_tau_nu = StudentTCDF( tau, nu );

if tcdf_tau_nu == 1
    IntDim = IntDim - 1;
    cholOmega = cholupdate( cholOmega, delta );
    Omega = cholOmega' * cholOmega;
    delta = zeros( N, 1 );
end

if isfinite( nu )
    [ Weights, pTmp, T ] = fwtpts( IntDim, Order );
    disp( 'T:' );
    disp( T );
    PhiN10 = normcdf( pTmp( end, : ) );
    if tcdf_tau_nu < 1
        N11Scaler = sqrt( 0.5 * ( nu + 1 ) ./ gammaincinv( PhiN10, 0.5 * ( nu + 1 ), 'upper' ) );
    else
        N11Scaler = sqrt( 0.5 * nu ./ gammaincinv( PhiN10, 0.5 * nu, 'upper' ) );
    end
end

if ~isfinite( nu ) || all( abs( N11Scaler - 1 ) <= sqrt( eps ) )
    IntDim = IntDim - 1;
    [ Weights, pTmp, T ] = fwtpts( IntDim, Order );
    disp( 'T:' );
    disp( T );
else
    pTmp( end, : ) = [];
end

if tcdf_tau_nu < 1
    PhiN0 = normcdf( pTmp( end, : ) );
    pTmp( end, : ) = [];
    FInvEST = tinv( 1 - ( 1 - PhiN0 ) * tcdf_tau_nu, nu );
    tpdfRatio = StudentTPDF( tau, nu ) / tcdf_tau_nu;
    MedT = tinv( 1 - 0.5 * tcdf_tau_nu, nu );
    N11Scaler = N11Scaler .* sqrt( ( nu + FInvEST .^ 2 ) / ( 1 + nu ) );
else
    FInvEST = zeros( size( Weights ) );
    tpdfRatio = 0;
    MedT = 0;
end

ESTPoints = bsxfun( @plus, cholOmega' * bsxfun( @times, pTmp, N11Scaler ) + bsxfun( @times, delta, FInvEST ), xi );

mu = sum( bsxfun( @times, ESTPoints, Weights ), 2 );
DemeanedESTPoints = bsxfun( @minus, ESTPoints, mu );
Weighted_DemeanedESTPoints = bsxfun( @times, DemeanedESTPoints, Weights );

Sigma = DemeanedESTPoints * Weighted_DemeanedESTPoints';
[ Sigma, cholSigma ] = NearestSPD( Sigma );

lambda = ESTPoints( :, 1 );

tauTtau = tau * tau;
OPtauTtauDnu = 1 + tauTtau / nu;
if isfinite( nu )
    nuOnuM1 = nu / ( nu - 1 );
else
    nuOnuM1 = 1;
end
if tcdf_tau_nu < 1
    ET1 = nuOnuM1 * OPtauTtauDnu * tpdfRatio;
else
    ET1 = 0;
end
xiAlt = mu - delta * ET1;

lambdaAlt = xi + delta * MedT;

disp( 'xi, xiAlt:' );
disp( [ xi, xiAlt ] );

disp( 'lambda, lambdaAlt:' );
disp( [ lambda, lambdaAlt ] );

cholSigma_muMlambda = cholSigma * ( mu - lambda );

Zcheck = ( ( mu - lambda )' * DemeanedESTPoints ) / sqrt( cholSigma_muMlambda' * cholSigma_muMlambda );

meanZcheck = Zcheck * Weights';
meanZcheck2 = Zcheck.^2 * Weights';

disp( 'EZ, EZ^2:' );
disp( [ meanZcheck, meanZcheck2 ] );

Zcheck = Zcheck - meanZcheck;
meanZcheck2 = Zcheck.^2 * Weights';
Zcheck = Zcheck / sqrt( meanZcheck2 );

[ fZcheck, xiZcheck ] = ksdensity( Zcheck, linspace( min( Zcheck ), max( Zcheck ), 2000 ), 'NumPoints', 2000, 'Weights', Weights );
fZcheck = max( 0, fZcheck );
fZcheck = fZcheck / sum( fZcheck );
idx1Zcheck = find( fZcheck / max( fZcheck ) > 0.005, 1 );
idx2Zcheck = find( fZcheck / max( fZcheck ) > 0.005, 1, 'last' );
plot( xiZcheck( idx1Zcheck : idx2Zcheck ), fZcheck( idx1Zcheck : idx2Zcheck ) );

sZ3 = Zcheck.^3 * Weights';
sZ4 = max( 3, Zcheck.^4 * Weights' );

disp( 'EZ^3, EZ^3:' );
disp( [ sZ3, sZ4 ] );

[ resid, xiHat, deltaHat, cholOmegaHat ] = CalibrateMomentsEST( tau, nu, mu, lambda, cholSigma, sZ3, sZ4 );

disp( 'at truth:' );
disp( 'resid:' );
disp( resid' );
disp( 'xi comparison:' );
disp( [ xi, xiHat ] );
disp( 'delta comparison:' );
disp( [ delta, deltaHat ] );
disp( 'diag( cholOmega ) comparison:' );
disp( [ diag( cholOmega ), diag( cholOmegaHat ) ] );

Estim4 = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), in( 2 ), mu, lambda, cholSigma, sZ3, sZ4 ), [ min( 1e300, tau ); min( 1e300, nu ) ], [ -Inf; 4 ], [], optimoptions( @lsqnonlin, 'display', 'iter', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );
Estim3 = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), nu, mu, lambda, cholSigma, sZ3, [] ), min( 1e300, tau ), [], [], optimoptions( @lsqnonlin, 'display', 'iter', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );

disp( 'Estim4 Estim3 Truth:' );
disp( [ Estim4( 1 ), Estim3, tau; Estim4( 2 ), nu, nu ] );

[ resid, xiHat, deltaHat, cholOmegaHat ] = CalibrateMomentsEST( Estim4( 1 ), Estim4( 2 ), mu, lambda, cholSigma, sZ3, sZ4 );

disp( 'at Estim4:' );
disp( 'resid:' );
disp( resid' );
disp( 'xi comparison:' );
disp( [ xi, xiHat ] );
disp( 'delta comparison:' );
disp( [ delta, deltaHat ] );
disp( 'diag( cholOmega ) comparison:' );
disp( [ diag( cholOmega ), diag( cholOmegaHat ) ] );

[ resid, xiHat, deltaHat, cholOmegaHat ] = CalibrateMomentsEST( Estim3( 1 ), nu, mu, lambda, cholSigma, sZ3, sZ4 );

disp( 'at Estim3:' );
disp( 'resid:' );
disp( resid' );
disp( 'xi comparison:' );
disp( [ xi, xiHat ] );
disp( 'delta comparison:' );
disp( [ delta, deltaHat ] );
disp( 'diag( cholOmega ) comparison:' );
disp( [ diag( cholOmega ), diag( cholOmegaHat ) ] );
