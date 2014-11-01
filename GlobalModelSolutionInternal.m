function [ fxNorm, gx, fx, M_Internal, oo_Internal ] = GlobalModelSolutionInternal( x, FirstCall, M_Internal, options_, oo_Internal, dynareOBC_, LowerIndices, PI, StateVariableAndShockTypes, fsolveOptions, ShadowQuadratureWeights, ShadowShockComponents )

    if any( ~isfinite( x ) )
        error( 'dynareOBC:BadParameters', 'Non-finite parameters were passed to GlobalModelSolutionInternal.' );
    end
    
    M_Internal.params( PI ) = x;
    
    Info = -1;
    try
        [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = ModelSolution( FirstCall, M_Internal, options_, oo_Internal ,dynareOBC_ );
    catch
    end
    
    if Info ~= 0
        fxNorm = NaN;
        gx = NaN;
        fx = NaN;
        return
    end
    
    StateVariableAndShockCombinations = dynareOBC_.StateVariableAndShockCombinations;
    StateVariablesAndShocks = dynareOBC_.StateVariablesAndShocks;
    ShadowShockCombinations = dynareOBC_.ShadowShockCombinations;

    T = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;

    Tns = ns * T;
    
    nOSSC = length( LowerIndices );
    nSVAS = length( StateVariablesAndShocks );
    nSVASC = size( StateVariableAndShockCombinations, 1 );
    nSSC = size( ShadowShockCombinations, 1 );
    
    CholSigma = RRRoot( M_Internal.Sigma_e );
    switch dynareOBC_.Order
        case 1
            Var_z = dynareOBC_.Var_z1;
        case 2
            Var_z = dynareOBC_.Var_z2;
        case 3
            error( 'dynareOBC:NotImplemented', 'Currently dynareOBC cannot solve globally at order 3.' );
        otherwise
            error( 'dynareOBC:UnsupportedOrder', 'dynareOBC only supports orders 1, 2 and 3.' );
    end
    CholVar_z = RRRoot( Var_z );
    Mean_z = dynareOBC_.Mean_z;

    nEndo = M_Internal.endo_nbr;
    nState = M_Internal.nspred;
    nVar_z = size( CholVar_z, 2 );
    nSigma = size( CholSigma, 2 );

    IntegrationDimension = nVar_z + nSigma;
    [ QuadratureWeights, QuadratureNodes ] = fwtpts( IntegrationDimension, min( dynareOBC_.Order, IntegrationDimension + 1 ) );
    NumberOfQuadratureNodes = length( QuadratureWeights );

    p = TimedProgressBar( NumberOfQuadratureNodes, 50, 'Computing simulation at grid points. Please wait for around ', '. Progress: ', 'Computing simulation at grid points. Completed in ' );
    WarningFlag = false;

    SimulationPresent = zeros( nEndo, NumberOfQuadratureNodes );
    SimulationPast = zeros( nEndo, NumberOfQuadratureNodes );
    ShockPresent = zeros( size( M_Internal.Sigma_e, 1 ), NumberOfQuadratureNodes );

    inv_order_var = oo_Internal.dr.inv_order_var;
    Order = dynareOBC_.Order;
    Constant = dynareOBC_.Constant;

    OpenPool;
    parfor i = 1 : NumberOfQuadratureNodes       
        lastwarn( '' );
        WarningState = warning( 'off', 'all' );
        try
            CurrentNodes = QuadratureNodes( :, i );
            z = Mean_z + CholVar_z * CurrentNodes( 1:nVar_z );
            EndoZeroVec = zeros( nEndo, 1 );
            InitialFullState = struct;
            InitialFullState.first = z( inv_order_var );
            InitialFullState.total = InitialFullState.first;
            if Order >= 2
                InitialFullState.second = z( nEndo + inv_order_var );
                InitialFullState.total = InitialFullState.total + InitialFullState.second;
                if Order >= 3
                    idx3 = 2*nEndo+nState*nState;
                    InitialFullState.first_sigma_2 = z( idx3 + inv_order_var );
                    InitialFullState.third = z( idx3 + nEndo + inv_order_var );
                    InitialFullState.total = InitialFullState.total + InitialFullState.first_sigma_2 + InitialFullState.third;
                end
            end
            InitialFullState.bound = EndoZeroVec;
            InitialFullState.total = InitialFullState.total + Constant;
            InitialFullState.total_with_bounds = InitialFullState.total + InitialFullState.bound;

            Shock = CholSigma * CurrentNodes( (nVar_z+1):end );
            Simulation = SimulateModel( Shock, M_Internal, options_, oo_Internal, dynareOBC_, false, InitialFullState );
            SimulationPresent( :, i ) = Simulation.total_with_bounds;
            SimulationPast( :, i ) = InitialFullState.total_with_bounds;
            ShockPresent( :, i ) = Shock;
        catch Error
            warning( WarningState );
            rethrow( Error );
        end
        warning( WarningState );

        if ~isempty( lastwarn )
            WarningFlag = WarningFlag | true;
        end
        if ~isempty( p )
            p.progress;
        end
    end
    if ~isempty( p )
        p.stop;
    end
    if WarningFlag
        warning( 'dynareOBC:InnerGlobal', 'Warnings were generated in an inner-loop during global simulation at grid points.' );
    end

    Components = zeros( NumberOfQuadratureNodes, nSVAS );
    for i = 1 : nSVAS
        switch StateVariableAndShockTypes( 1, i )
            case 0
                Components( :, i ) = ones( NumberOfQuadratureNodes, 1 );
            case 1
                Components( :, i ) = SimulationPast( StateVariableAndShockTypes( 2, i ), : ).';
            case 2
                Components( :, i ) = ShockPresent( StateVariableAndShockTypes( 2, i ), : ).';
            otherwise
                error( 'dynareOBC:UnrecognisedStateVariableOrShockType', 'Unrecognised state variable or shock type.' );
        end
    end

    Regressors = ones( NumberOfQuadratureNodes, nSVASC );

    parfor i = 1 : nSVASC
        StateVariableAndShockCombination = StateVariableAndShockCombinations( i, : );
        for l = 1 : length( StateVariableAndShockCombination )
            if StateVariableAndShockCombination( l ) > 0
                CurrentComponent = Components( :, l ); %#ok<PFBNS>
                Regressors( :, i ) = Regressors( :, i ) .* ( CurrentComponent .^ StateVariableAndShockCombination( l ) );
            end
        end
    end

    % OneIndex = all( Regressors == 1 );
    % RegressorsWithout1 = Regressors( :, ~OneIndex );

    LinearIndex = 0;
    xIndex = 0;
    gx = x;
    Residuals = zeros( NumberOfQuadratureNodes, Tns );

    for i = 1 : ns
        for j = 1 : T
            LinearIndex = LinearIndex + 1;
            ShadowInnovation = SimulationPresent( dynareOBC_.VarIndices_Sum( j, i ), : );
            if j < T
                ShadowInnovation = ShadowInnovation - SimulationPast( dynareOBC_.VarIndices_Sum( j + 1, i ), : );
            end

            ShadowInnovation = ShadowInnovation';
            WeightedRegressors = bsxfun( @times, Regressors, QuadratureWeights' );

            % betaTmp = GHWRidgeWeighted( ShadowInnovation, RegressorsWithout1, QuadratureWeights );
            % beta = betaTmp;
            % beta( OneIndex ) = betaTmp( 1 );
            % beta( ~OneIndex ) = betaTmp( 2:end );

            [ U1, D1, V1 ] = svd( WeightedRegressors' * Regressors, 0 );
            d1 = diag( D1 );
            PInvTolerance = NumberOfQuadratureNodes * eps( max( d1 ) );
            FirstZeroSV = sum( d1 > PInvTolerance ) + 1;
            U1( :, FirstZeroSV:end ) = [];
            d1( FirstZeroSV:end ) = [];
            V2 = V1( :, FirstZeroSV:end );
            V1( :, FirstZeroSV:end ) = [];
            PInvXpWX = bsxfun(@times,V1,(1./d1).')*U1';
            ComplementMatrix = V2 * V2';
            beta = PInvXpWX * WeightedRegressors' * ShadowInnovation;

            NewxIndex = xIndex + nSVASC;
            old_beta = gx( ( xIndex+1 ):NewxIndex );

            beta = beta + ComplementMatrix * ( old_beta - beta );

            Residuals( :, LinearIndex ) = ShadowInnovation - Regressors * beta;

            gx( ( xIndex+1 ):NewxIndex ) = beta;
            xIndex = NewxIndex;
        end
    end

    Residuals = bsxfun( @minus, Residuals, QuadratureWeights * Residuals );
    WeightedResiduals = bsxfun( @times, Residuals, QuadratureWeights' );
    [ LDLCovResiduals, ~ ] = mchol( ( 1 / ( NumberOfQuadratureNodes - nSVASC ) ) * ( Residuals' * WeightedResiduals ) + sqrt( eps ) * eye( Tns ) );

    Residuals = ( LDLCovResiduals \ ( Residuals' ) )';

    LinearIndex = 0;

    NewxIndex = xIndex + nOSSC;
    gx( ( xIndex+1 ):NewxIndex ) = LDLCovResiduals( LowerIndices );
    xIndex = NewxIndex;

    for i = 1 : ns
        for j = 1 : T

            LinearIndex = LinearIndex + 1;
            CurrentResiduals = Residuals( :, LinearIndex );
            CurrentWeightedResiduals = WeightedResiduals( :, LinearIndex );

            ResidualMoments = CurrentWeightedResiduals' * bsxfun( @power, CurrentResiduals, 1 : nSSC );
            StdResiduals = sqrt( ResidualMoments( 1 ) );

            NewxIndex = xIndex + nSSC;
            if dynareOBC_.Order == 1
                gx( ( xIndex+1 ):NewxIndex ) = [ StdResiduals; zeros( nSSC - 1, 1 ) ];
            else
                BestValues = fsolve( @( Values ) MomentObjective( Values, ResidualMoments, ShadowQuadratureWeights, ShadowShockComponents, nSSC ), gx( ( xIndex+1 ):NewxIndex ), fsolveOptions );
                gx( ( xIndex+1 ):NewxIndex ) = BestValues;
            end
            xIndex = NewxIndex;

        end
    end

    fx = gx - x;
    fxNorm = norm( fx );

    
end

function [ Distance, DDistance ] = MomentObjective( Values, ResidualMoments, ShadowQuadratureWeights, ShadowShockComponents, nSSC )
    ShadowValues = ShadowShockComponents * Values;
    DShadowValues = ShadowShockComponents;
    WeightedShadowValues = ShadowValues .* ShadowQuadratureWeights';
    DWeightedShadowValues = bsxfun( @times, DShadowValues, ShadowQuadratureWeights' );
    ShadowValuePowersReduced = bsxfun( @power, ShadowValues, 0 : (nSSC-1) );
    ShadowValuePowers = bsxfun( @times, ShadowValuePowersReduced, ShadowValues );
    ShadowMoments = WeightedShadowValues' * ShadowValuePowers;
    DShadowMoments = bsxfun( @times, WeightedShadowValues', bsxfun( @times, ( 1 : nSSC )', ShadowValuePowersReduced' ) ) * DShadowValues + ShadowValuePowers' * DWeightedShadowValues;
    Distance = ShadowMoments - ResidualMoments;
    DDistance = DShadowMoments;
end

function RootSigma = RRRoot( Sigma )
    FullSigma = full( 0.5 * ( Sigma + Sigma' ) );
    [ V, D ] = eig( FullSigma );
    d = diag( D );
    Select = d > 1.81898940354586e-12;
    RootSigma = V( :, Select ) * diag( sqrt( d( Select ) ) );
end