function y = PerformCubature( y, UnconstrainedReturnPath, options, oo, dynareOBC, FirstOrderSimulation, varargin )
   
    RootConditionalCovariance = RetrieveConditionalCovariances( options, oo, dynareOBC, FirstOrderSimulation );
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

    OpenPool;
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
                yNew = SolveBoundsProblem( UnconstrainedReturnPath + RootConditionalCovariance * CubaturePoints( :, j ), dynareOBC );
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
		
        if dynareOBC.FastCubature || dynareOBC.NoStatisticalCubature || ( i == 1 && dynareOBC.KappaPriorParameter == 0 )
            yNew = yMatrix( :, i );
            yError = max( abs( y - yNew ) );
            y = yNew;
        else
            x_y = [ yOriginal yMatrix( :, 1:i ) ];
            OptiFunction = @( HP ) GetTwoNLogL( HP, x_y, dynareOBC.KappaPriorParameter );
            % fmincon( @(HPG) fd(OptiFunction,HPG), HyperParams, [],[],[],[], [ -1; -1; 0 ], [ 1; 1; 1 ],[],optimset('disp','iter','DerivativeCheck','on','FinDiffType','forward','gradobj','on'));
            OptiProblem = opti( 'fun', OptiFunction, 'grad', @( HPG ) cstepJac( OptiFunction, HPG, 1 ), 'bounds', [ -1+Tolerance; -1+Tolerance; Tolerance ], [ 1-Tolerance; 1-Tolerance; 1-Tolerance ], 'x0', HyperParams, 'options', dynareOBC.OptiOptions );
            HyperParams = solve( OptiProblem );
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

% function [f,d] = fd( fun, x )
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
    I = size( x, 1 );
    T = size( x, 2 );
    RhoInv = GetInvARCovMat( rho, T );
    PhiInv = GetInvARCovMat( phi, I );
    KappaInv = kappa .^ (-(0:(T-1)).');
    diagKappaInv = diag( KappaInv );
    diagKappaInvRhoInvdiagKappaInv = diagKappaInv * RhoInv * diagKappaInv;
    II = eye( I );
    OI = ones( I, 1 );
    OT = ones( T, 1 );
    mu = ( x * diagKappaInvRhoInvdiagKappaInv * OT ) / ( OT.' * diagKappaInvRhoInvdiagKappaInv * OT );
    Error = x(:) - kron( OT, mu );
    Temp = diag( Error ) * kron( KappaInv, II );
    sigma = sqrt( eps + max( 0, 1 / T * Temp.' * kron( RhoInv, PhiInv ) * Temp * OI ) );
end

function TwoNLogL = GetTwoNLogL( HyperParams, x, KappaPriorParameter )
    rho = HyperParams( 1 );
    phi = HyperParams( 2 );
    kappa = HyperParams( 3 );
    [ ~, sigma, PhiInv, diagKappaInvRhoInvdiagKappaInv, Error ] = GetMu( HyperParams, x );
    I = size( x, 1 );
    T = size( x, 2 );
    OI = ones( I, 1 );
    diag_sigmaInv = diag( 1 ./ sigma );
    log_kappa = log( kappa );
    TwoNLogL = I * ( T * ( T - 1 ) * log_kappa - log( 1 - rho ) - log( 1 + rho ) ) + T * ( 2 * OI.' * log( sigma ) - log( 1 - phi ) - log( 1 + phi ) ) + Error.' * kron( diagKappaInvRhoInvdiagKappaInv, diag_sigmaInv * PhiInv * diag_sigmaInv ) * Error;
    if KappaPriorParameter > 0
        OPKappaPriorParameter = 1 + KappaPriorParameter;
        TwoNLogL = TwoNLogL + KappaPriorParameter * ( kappa ^ ( -KappaPriorParameter ) * OPKappaPriorParameter + KappaPriorParameter * OPKappaPriorParameter * log_kappa );
    end
end
