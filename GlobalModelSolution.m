function [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = GlobalModelSolution( M_Internal, options_, oo_Internal ,dynareOBC_ )

    skipline( );
    disp( 'Beginning the semi-global solution of the model.' );
    skipline( );
    
    StateVariableAndShockCombinations = dynareOBC_.StateVariableAndShockCombinations;
    StateVariablesAndShocks = dynareOBC_.StateVariablesAndShocks;
    ShadowShockCombinations = dynareOBC_.ShadowShockCombinations;

    T = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;

    Tns = ns * T;
    
    LowerIndices = tril( reshape( ( 1 : ( Tns * Tns ) )', [ Tns, Tns ] ), -1 );
    LowerIndices = LowerIndices(:);
    LowerIndices( LowerIndices == 0 ) = [];
    
    PI_StateVariableAndShockCombinations = dynareOBC_.ParameterIndices_StateVariableAndShockCombinations;
    PI_OtherShadowShockCombinations = dynareOBC_.ParameterIndices_OtherShadowShockCombinations( LowerIndices );
    PI_ShadowShockCombinations = dynareOBC_.ParameterIndices_ShadowShockCombinations;
    PI = [ PI_StateVariableAndShockCombinations( : ); PI_OtherShadowShockCombinations( : ); PI_ShadowShockCombinations( : ) ];
    nPI = length( PI );
    m = min(nPI,ceil(4+4*(nPI-1).^(1/4))); % seems "reasonable" and fits http://users.wpi.edu/~walker/Papers/Walker-Ni,SINUM,V49,1715-1735.pdf
    
    nOSSC = length( PI_OtherShadowShockCombinations );
    nSVAS = length( StateVariablesAndShocks );
    nSVASC = size( StateVariableAndShockCombinations, 1 );
    nSSC = size( ShadowShockCombinations, 1 );
    nSS = dynareOBC_.ShadowShockNumberMultiplier;
        
    StateVariableAndShockTypes = zeros( 2, nSVAS );
    for i = 1 : nSVAS
        CurrentStateVariableOrShock = StateVariablesAndShocks{i};
        if CurrentStateVariableOrShock == '1'
            StateVariableAndShockTypes( 1, i ) = 0;
            StateVariableAndShockTypes( 2, i ) = 1;
        elseif ismember( CurrentStateVariableOrShock, dynareOBC_.StateVariables )
            StateVariableAndShockTypes( 1, i ) = 1;
            StateVariableAndShockTypes( 2, i ) = find( ismember( dynareOBC_.EndoVariables, CurrentStateVariableOrShock(1:(end-4)) ), 1 ); % end - 4 remove (-1)
        elseif ismember( CurrentStateVariableOrShock, dynareOBC_.Shocks )
            StateVariableAndShockTypes( 1, i ) = 2;
            StateVariableAndShockTypes( 2, i ) = find( ismember( dynareOBC_.Shocks, CurrentStateVariableOrShock ), 1 );
        else
            error( 'dynareOBC:UnrecognisedStateVariableOrShock', 'Unrecognised state variable or shock.' );
        end
    end
          
    CMAESOptions = cmaes( 'defaults' );
    CMAESOptions.MaxIter = Inf;
    CMAESOptions.DiagonalOnly = '(1+100*N/sqrt(popsize))+(N>=1000)';
    CMAESOptions.CMA.active = 1;
    CMAESOptions.EvalParallel = 1;
    
    if dynareOBC_.Resume
        load dynareOBCSemiGlobalResume.mat x;
        M_Internal.params( PI ) = x;
    else
        x = M_Internal.params( PI );
    end
    
    M_Internal_Init = M_Internal;
    options_Init = options_;
    oo_Internal_Init = oo_Internal;
    dynareOBC_Init = dynareOBC_;
    
    global oo_ M_

    StepSize = 0.01;
    for Iteration = 0 : dynareOBC_.MaxIterations
        if Iteration > 0
            M_Internal = M_Internal_Init;
            options_ = options_Init;
            oo_Internal = oo_Internal_Init;
            dynareOBC_ = dynareOBC_Init;
            M_Internal.params( PI ) = x;
        end
        [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = ModelSolution( Iteration == 0, M_Internal, options_, oo_Internal ,dynareOBC_ );
        if Iteration > 0
            if Info ~= 0
                StepSize = StepSize * 0.5;
                LastFailed = true;
                x = x + StepSize * fx;
                continue;
            else
                ofx = fx;
                ofxMax = fxMax;
            end
        else
            if Info ~= 0
                error( 'dynareOBC:FailedFirstStepGlobal', 'Failed to solve the model at the initial point while computing a global solution.' );
            else
                ofx = [];
                ofxMax = Inf;
                LastFailed = false;
            end
        end
        if Info ~= 0
            x = ox;
            fx = ofx;
            fxMax = ofxMax;
            StepSize = StepSize * 0.5;
            LastFailed = true;
            x = x + StepSize * fx;
        end
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
        
        nEndo = M_Internal.endo_nbr;
        nState = M_Internal.nspred;
        nVar_z = size( CholVar_z, 2 );
        nSigma = size( CholSigma, 2 );
        
        IntegrationDimension = nVar_z + nSigma;
        [ QuadratureNodes, QuadratureWeights ] = nwspgr( 'KPN', IntegrationDimension, dynareOBC_.Order + 2 );
        QuadratureWeights = QuadratureWeights / sum( QuadratureWeights );
        NumberOfQuadratureNodes = length( QuadratureWeights );

        Components = zeros( NumberOfQuadratureNodes, nSVAS );
        DensitySimulationLength = NumberOfQuadratureNodes * dynareOBC_.DensityEstimationSimulationLengthMultiplier;
        ShadowShocks = randn( DensitySimulationLength, nSS );
        ShadowShockComponents = ones( DensitySimulationLength, nSSC );
        for k = 1 : nSSC
            ShadowShockCombination = ShadowShockCombinations( k, : );
            ShockMeanOne = true;
            for l = 1 : nSS
                ShockPower = ShadowShockCombination( l );
                if ShockPower > 0
                    if mod( ShockPower, 2 ) == 1
                        ShockMeanOne = false;
                    end
                    ShadowShockComponents( :, k ) = ShadowShockComponents( :, k ) .* ( ShadowShocks( :, l ) .^ ShockPower );
                end
            end
            if ShockMeanOne
                ShadowShockComponents( :, k ) = ShadowShockComponents( :, k ) - 1;
            end
        end
        StdShadowShockCompoents = std( ShadowShockComponents );       

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
                CurrentNodes = QuadratureNodes( i, : );
                z = CholVar_z * CurrentNodes( 1:nVar_z )';
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

                Shock = CholSigma * CurrentNodes( (nVar_z+1):end )';
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
        
        OneIndex = all( Regressors == 1 );
        RegressorsWithout1 = Regressors( :, ~OneIndex );
        
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
                betaTmp = GHWRidge( ShadowInnovation, RegressorsWithout1 );
                beta = betaTmp;
                beta( OneIndex ) = betaTmp( 1 );
                beta( ~OneIndex ) = betaTmp( 2:end );
                Residuals( :, LinearIndex ) = ShadowInnovation - Regressors * beta;
                
                NewxIndex = xIndex + nSVASC;
                gx( ( xIndex+1 ):NewxIndex ) = beta;
                xIndex = NewxIndex;
            end
        end
        
        [ LDLCovResiduals, ~ ] = mchol( ( 1 / ( NumberOfQuadratureNodes - nSVASC ) ) * ( Residuals' * Residuals ) );
        
        Residuals = ( LDLCovResiduals \ ( Residuals' ) )';
        
        LinearIndex = 0;
        
        NewxIndex = xIndex + nOSSC;
        gx( ( xIndex+1 ):NewxIndex ) = LDLCovResiduals( LowerIndices );
        xIndex = NewxIndex;

        for i = 1 : ns
            for j = 1 : T
                
                LinearIndex = LinearIndex + 1;
                CurrentResiduals = Residuals( :, LinearIndex );
                
                StdResiduals = sqrt( ( 1 / ( NumberOfQuadratureNodes - nSVASC ) ) * ( CurrentResiduals' * CurrentResiduals ) );
                
                NewxIndex = xIndex + nSSC;
                if dynareOBC_.Order == 1
                    gx( ( xIndex+1 ):NewxIndex ) = [ StdResiduals; zeros( nSSC - 1, 1 ) ];
                else
                    MinMaxScale = ApproximateInverseCDFMaxGaussians( DensitySimulationLength, 0.95 ) / ApproximateInverseCDFMaxGaussians( NumberOfQuadratureNodes, 0.05 );

                    DensityMin = min( min( CurrentResiduals ), -2 * StdResiduals ) * MinMaxScale;
                    DensityMax = max( max( CurrentResiduals ), 2 * StdResiduals ) * MinMaxScale;
                    
                    nPoints = 2 ^ dynareOBC_.DensityAccuracy;
                    
                    [ ~, Density ] = kde( CurrentResiduals, nPoints, DensityMin, DensityMax, Density );
                    Density( Density < 0 ) = 0;
                    Density = Density / sum( Density );
                    
                    [~, ~, ~, ~, ~, BestEver ] = cmaes( @( Values ) DensityObjective( Values, ShadowShockComponents, DensitySimulationLength, nPoints, DensityMin, DensityMax, Density ), ...
                                                        x( ( xIndex+1 ):NewxIndex ), bsxfun( @rdivide, StdResiduals, StdShadowShockCompoents ), CMAESOptions );

                    gx( ( xIndex+1 ):NewxIndex ) = BestEver.x;
                end
                xIndex = NewxIndex;

            end
        end
        
        fx = gx - x;
        fxMax = max( abs( fx ) );
        
        skipline( );
        fprintf( 'End of iteration %d. Maximum change in parameters: %e\n', Iteration, fxMax );
        
        if fxMax < sqrt( eps )
            x = 0.5 * ( x + gx );
            skipline( );
            break;
        end
        
        if fxMax <= ofxMax
            M_ = M_Internal;
            oo_ = oo_Internal;
            save dynareOBCSemiGlobalResume.mat x M_ oo_;
            save_params_and_steady_state( 'dynareOBCSemiGlobalSteady.txt' );

            ox = x;
            x = x + StepSize * fx;
            StepSize = StepSize * 1.1;
            LastFailed = false;
        else
            x = ox;
            fx = ofx;
            fxMax = ofxMax;
            if LastFailed
                StepSize = -StepSize;
                LastFailed = false;
            else
                StepSize = StepSize * 0.5;
                LastFailed = true;
            end
            x = x + StepSize * fx;            
        end
        fprintf( 'New step size: %e\n', StepSize );
        skipline( );
        
        if 1 == 0
            ox = x;
            if Iteration > 0
                dfx = fx - ofx;
                if Iteration > 1
                    SF( :, end + 1 ) = dfx; %#ok<AGROW>
                    if size( SF, 2 ) > m
                        SF( :, 1 ) = [];
                    end
                else
                    SF = dfx;
                end
                gamma = pinv( SF ) * fx;
                x = gx - ( SX + SF ) * gamma;
            else
                x = gx;
            end

            dx = x - ox;
            if Iteration > 0
                SX( :, end + 1 ) = dx; %#ok<AGROW>
                if size( SX, 2 ) > m
                    SX( :, 1 ) = [];
                end
            else
                SX = dx;
            end
        end

        % x = 0.01 * gx + 0.99 * ox;
        
    end
    if fxMax < sqrt( eps )
        skipline( );
        disp( 'Convergence obtained.' );
        skipline( );
        M_ = M_Internal;
        oo_ = oo_Internal;
        save dynareOBCSemiGlobalResume.mat x M_ oo_;
        save_params_and_steady_state( 'dynareOBCSemiGlobalSteady.txt' );
    else
        skipline( );
        warning( 'dynareOBC:ReachedMaxIterations', 'The semi-global solution algorithm reached the maximum allowed number of interations without converging. Results may be inaccurate.' );
        skipline( );
    end
    M_Internal = M_Internal_Init;
    options_ = options_Init;
    oo_Internal = oo_Internal_Init;
    dynareOBC_ = dynareOBC_Init;
    M_Internal.params( PI ) = x;
    [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = ModelSolution( false, M_Internal, options_, oo_Internal ,dynareOBC_ );
    if Info ~= 0
        error( 'dynareOBC:GlobalNoSolution', 'At the final point, no determinate solution exists.' );
    end

end

function KL = DensityObjective( ValuesMatrix, ShadowShockComponents, DensitySimulationLength, nPoints, DensityMin, DensityMax, Density )

    nMultiple = size( ValuesMatrix, 2 );
    
    KL = zeros( 1, nMultiple );
    
    parfor i = 1 : nMultiple
        Values = ValuesMatrix( :, i );
        NewResiduals = ShadowShockComponents * Values;

        NewResiduals( ( NewResiduals > DensityMax ) || ( NewResiduals < DensityMin ) ) = [];
        Penalty = DensitySimulationLength - length( NewResiduals );

        [ ~, NewDensity ] = kde( NewResiduals, nPoints, DensityMin, DensityMax );
        NewDensity( NewDensity < 0 ) = 0;
        NewDensity = NewDensity / sum( NewDensity );

        KLTemp = log( Density ./ NewDensity ) .* Density;
        KLTemp( ~isfinite( KLTemp ) ) = 0;

        KL( i ) = sum( KLTemp ) + 10 * Penalty;
    end
    
end
function CholSigma = RRRoot( Sigma )
    FullSigma = full( 0.5 * ( Sigma + Sigma' ) );
    [ V, D ] = eig( FullSigma );
    d = diag( D );
    Select = d > 1.81898940354586e-12;
    CholSigma = V( :, Select ) * diag( sqrt( d( Select ) ) );
end