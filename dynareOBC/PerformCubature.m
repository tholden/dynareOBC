function y = PerformCubature( y, UnconstrainedReturnPath, oo, dynareOBC, FirstOrderSimulation, varargin )
   
    RootConditionalCovariance = RetrieveConditionalCovariances( oo, dynareOBC, FirstOrderSimulation );
    d = size( RootConditionalCovariance, 2 );
    if d == 0
        return;
    end
    
    if dynareOBC.FastCubature
        NumPoints = 1 + 2 * d;
        CubatureWeights = ones( NumPoints, 1 ) * ( 1 / NumPoints );
        wTemp = 0.5 * sqrt( 2 * NumPoints );
        CubaturePoints = [ zeros( d, 1 ), eye( d ) * wTemp, eye( d ) * (-wTemp) ];
        CubatureOrder = 1;
    elseif dynareOBC.QuasiMonteCarloLevel > 0
        CubatureOrder = dynareOBC.QuasiMonteCarloLevel;
        NumPoints = 2 .^ ( 2 : ( 1 + CubatureOrder ) ) - 1;
        CubaturePoints = SobolSequence( d, NumPoints( end ) );
        CubatureWeights = zeros( NumPoints( end ), CubatureOrder );
        for i = 1 : CubatureOrder
            CubatureWeights( 1:NumPoints( i ), i ) = 1 ./ NumPoints( i );
        end
    else
        CubatureOrder = ceil( 0.5 * ( dynareOBC.MaxCubatureDegree - 1 ) );
        [ CubatureWeightsCurrent, CubaturePoints, NumPointsCurrent ] = fwtpts( d, CubatureOrder );
        CubatureWeights = zeros( NumPointsCurrent, CubatureOrder );
        CubatureWeights( :, end ) = CubatureWeightsCurrent;
        NumPoints = zeros( 1, CubatureOrder );
        NumPoints( end ) = NumPointsCurrent;
        for i = 1 : ( CubatureOrder - 1 )
            CubatureWeightsCurrent = fwtpts( d, i );
            NumPointsCurrent = length( CubatureWeightsCurrent );
            CubatureWeights( 1:NumPointsCurrent, i ) = CubatureWeightsCurrent;
            NumPoints( i ) = NumPointsCurrent;
        end
    end
    
    NumPoints = [ 1 NumPoints ];

    if nargin > 6
        p = TimedProgressBar( NumPoints( end ), 20, varargin{:} );
    else
        p = [];
    end

    yMatrix = y * CubatureWeights( 1, : );   
    yOriginal = y;

    if ~isempty( p )
        p.progress;
    end
    
    HyperParams = [ 0; 0; 0.5 ];
    
    Tolerance = dynareOBC.Tolerance;
    
    WarningGenerated = false;
    for i = 1 : CubatureOrder
    
        parfor j = ( NumPoints( i ) + 1 ) : NumPoints( i + 1 )
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                yNew = SolveBoundsProblem( UnconstrainedReturnPath + RootConditionalCovariance * CubaturePoints( :, j ) );
                yMatrix = yMatrix + yNew * CubatureWeights( j, : );
            catch Error
                warning( WarningState );
                rethrow( Error );
            end
            warning( WarningState );
            WarningGenerated = WarningGenerated | ~isempty( lastwarn );
            if ~isempty( p )
                p.progress;
            end
        end
        
        if dynareOBC.FastCubature || dynareOBC.NoStatisticalCubature || dynareOBC.QuasiMonteCarloLevel > 0 || ( i == 1 && ( dynareOBC.KappaPriorParameterA == 0 ||  dynareOBC.KappaPriorParameterB == 0 ) )
            yNew = yMatrix( :, i );
            yError = max( abs( y - yNew ) );
            y = yNew;
        else
            x_y = [ yOriginal yMatrix( :, 1:i ) ];
            OptiFunction = @( HP ) GetTwoNLogL( HP, x_y, dynareOBC.KappaPriorParameterA, dynareOBC.KappaPriorParameterB );
            OptiLB = [ -1+Tolerance; -1+Tolerance; Tolerance ];
            OptiUB = [ 1-Tolerance; 1-Tolerance; 1-Tolerance ];
            HyperParams = dynareOBC.FMinFunctor( OptiFunction, HyperParams, OptiLB, OptiUB, 'UseParallel', false );
            yNew = GetMu( HyperParams, x_y );
            yError = max( abs( y - yNew ) );
            y = yNew;
        end
        
        if yError < dynareOBC.CubatureTolerance
            break;
        end
    
    end

    if ~isempty( p )
        p.stop;
    end
    
    % M = dynareOBC.MMatrix;
    % [ y, ~, ~, exitflag ] = lsqlin( M, ConstrainedReturnPath - UnconstrainedReturnPath, -M, UnconstrainedReturnPath, [], [], [], [], y, dynareOBC.LSqLinOptions );
    
    if WarningGenerated
        warning( 'dynareOBC:QuadratureWarnings', 'Warnings were generated in the inner quadrature loop; try increasing TimeToEscapeBounds.' );
    end

end

% function ARCovMat = GetARCovMat( rho, T )
%     ARCovMat = ( rho .^ abs( bsxfun( @minus, 0:(T-1), (0:(T-1))' ) ) ) * ( 1 / ( 1 - rho * rho ) );
% end

% function [ f, d ] = FunctionAndGradient( fun, x )
%     f = fun( x );
%     if nargout > 1
%         d = cstepJac( fun, x, 1 );
%     end
% end

function InvARCovMat = GetInvARCovMat( rho, T )
    if T == 1
        InvARCovMat = 1 - rho * rho;
    else
        d0 = ones( T, 1 ) * ( 1 + rho * rho );
        d0( 1 ) = 1;
        d0( end ) = 1;
        d1 = -rho * ones( T - 1, 1 );
        InvARCovMat = diag( d0 ) + diag( d1, -1 ) + diag( d1, 1 );
    end
end

function [ mu, sigma, PhiInv, diagKappaInvRhoInvdiagKappaInv, Error ] = GetMu( HyperParams, x )
    rho = HyperParams( 1 );
    phi = HyperParams( 2 );
    kappa = HyperParams( 3 );
    T = size( x, 1 );
    D = size( x, 2 );
    RhoInv = GetInvARCovMat( rho, D );
    PhiInv = GetInvARCovMat( phi, T );
    KappaInv = kappa .^ (-(0:(D-1)).');
    diagKappaInv = diag( KappaInv );
    diagKappaInvRhoInvdiagKappaInv = diagKappaInv * RhoInv * diagKappaInv;
    IT = eye( T );
    OT = ones( T, 1 );
    OD = ones( D, 1 );
    mu = ( x * diagKappaInvRhoInvdiagKappaInv * OD ) / ( OD.' * diagKappaInvRhoInvdiagKappaInv * OD );
    Error = x(:) - kron( OD, mu );
    Temp = diag( Error ) * kron( KappaInv, IT );
    sigma = sqrt( eps + max( 0, 1 / D * Temp.' * kron( RhoInv, PhiInv ) * Temp * OT ) );
end

function TwoNLogL = GetTwoNLogL( HyperParams, x, KappaPriorParameterA, KappaPriorParameterB )
    rho = HyperParams( 1 );
    phi = HyperParams( 2 );
    kappa = HyperParams( 3 );
    [ ~, sigma, PhiInv, diagKappaInvRhoInvdiagKappaInv, Error ] = GetMu( HyperParams, x );
    T = size( x, 1 );
    D = size( x, 2 );
    OT = ones( T, 1 );
    diag_sigmaInv = diag( 1 ./ sigma );
    TwoNLogL = T * ( D * ( D - 1 ) * log( kappa ) - log( 1 - rho ) - log( 1 + rho ) ) + D * ( 2 * OT.' * log( sigma ) - log( 1 - phi ) - log( 1 + phi ) ) + Error.' * kron( diagKappaInvRhoInvdiagKappaInv, diag_sigmaInv * PhiInv * diag_sigmaInv ) * Error;
    if KappaPriorParameterA > 0 && KappaPriorParameterB > 0
        TwoNLogL = TwoNLogL - 2 * log( - expm1( KappaPriorParameterB * log1p( - kappa ^ ( T * KappaPriorParameterA ) ) ) );
    end
end
