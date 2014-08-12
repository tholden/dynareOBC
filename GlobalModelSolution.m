function [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = GlobalModelSolution( M_Internal, options_, oo_Internal ,dynareOBC_ )

    % error( 'dynareOBC:NotImplemented', 'I am still working on accuracy=2...' );
    
    skipline( );
    disp( 'Beginning the semi-global solution of the model.' );
    skipline( );
    
    PositiveVarianceShocks = setdiff( 1:dynareOBC_.OriginalNumVarExo, find( diag(M_Internal.Sigma_e) == 0 ) );
    NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
    
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
    
    SimulationDrop = dynareOBC_.SimulationDrop;
    assert( SimulationDrop >= 1 );
    
    ActualSimulationLength = dynareOBC_.RegressionBaseSampleSize + dynareOBC_.RegressionSampleSizeMultiplier * ( 1 + nSVASC );
    TotalSimulationLength = SimulationDrop + ActualSimulationLength;
    
    ShockSequence = zeros( dynareOBC_.OriginalNumVarExo, TotalSimulationLength );
    CholSigma_e = chol( M_Internal.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );

    ShockSequence( PositiveVarianceShocks, : ) = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, TotalSimulationLength );
    
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
    
    Components = zeros( ActualSimulationLength, nSVAS );

    DensitySimulationLength = ActualSimulationLength * dynareOBC_.DensityEstimationSimulationLengthMultiplier;

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
        
    % StdSumShadowShockComponents = std( sum( ShadowShockComponents, 2 ) );
    StdShadowShockCompoents = std( ShadowShockComponents );
        
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

    for Iteration = 0 : dynareOBC_.MaxIterations
        if Iteration > 0
            M_Internal = M_Internal_Init;
            options_ = options_Init;
            oo_Internal = oo_Internal_Init;
            dynareOBC_ = dynareOBC_Init;
            M_Internal.params( PI ) = x;
        end
        [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = ModelSolution( Iteration == 0, M_Internal, options_, oo_Internal ,dynareOBC_ );
        if Info ~= 0
            error( 'dynareOBC:GlobalNoSolution', 'The iterative global solution procedure method got stuck in a parameter range in which no determinate solution exists.' );
        end
        
        Simulation = SimulateModel( ShockSequence, M_Internal, options_, oo_Internal, dynareOBC_, true );
        SimulationPath = Simulation.total_with_bounds;
        
        for i = 1 : nSVAS
            switch StateVariableAndShockTypes( 1, i )
                case 0
                    Components( :, i ) = ones( ActualSimulationLength, 1 );
                case 1
                    Components( :, i ) = SimulationPath( StateVariableAndShockTypes( 2, i ), (SimulationDrop+1):end ).';
                case 2
                    Components( :, i ) = ShockSequence( StateVariableAndShockTypes( 2, i ), (SimulationDrop+1):end ).';
                otherwise
                    error( 'dynareOBC:UnrecognisedStateVariableOrShockType', 'Unrecognised state variable or shock type.' );
            end
        end
            
        Regressors = ones( ActualSimulationLength, nSVASC );
        
        OpenPool;
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
        Residuals = zeros( ActualSimulationLength, Tns );
        
        for i = 1 : ns
            for j = 1 : T
                LinearIndex = LinearIndex + 1;
                ShadowInnovation = SimulationPath( dynareOBC_.VarIndices_Sum( j, i ), (SimulationDrop+1):end );
                if j < T
                    ShadowInnovation = ShadowInnovation - SimulationPath( dynareOBC_.VarIndices_Sum( j + 1, i ), SimulationDrop:(end-1) );
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
                
                % M_.params( PI_StateVariableAndShockCombinations( 1 : nSVASC, j, i ) ) = 0.5 * ( beta + old_beta );
            end
        end
        
        LDLCovResiduals = chol( ( 1 / ( ActualSimulationLength - nSVASC ) ) * ( Residuals' * Residuals ) + eps * eye( Tns ), 'lower' );
        LDLCovResiduals = LDLCovResiduals * diag( 1 ./ diag( LDLCovResiduals ) );
        
        Residuals = ( LDLCovResiduals \ ( Residuals' ) )';
        
        LinearIndex = 0;
        
        NewxIndex = xIndex + nOSSC;
        gx( ( xIndex+1 ):NewxIndex ) = LDLCovResiduals( LowerIndices );
        xIndex = NewxIndex;

        % M_.params( PI_OtherShadowShockCombinations ) = LDLResiduals( LowerIndices );
    
        for i = 1 : ns
            for j = 1 : T
                
                LinearIndex = LinearIndex + 1;
                CurrentResiduals = Residuals( :, LinearIndex );
                
                StdResiduals = sqrt( ( 1 / ( ActualSimulationLength - nSVASC ) ) * ( CurrentResiduals' * CurrentResiduals ) );
                
                NewxIndex = xIndex + nSSC;
                if dynareOBC_.Order == 1
                    gx( ( xIndex+1 ):NewxIndex ) = [ StdResiduals; zeros( nSSC - 1, 1 ) ];
                    % M_.params( dynareOBC_.ParameterIndices_ShadowShockCombinations( :, j, i ) ) = [ StdResiduals; zeros( nSSC - 1, 1 ) ];
                else
                    MinMaxScale = ApproximateInverseCDFMaxGaussians( DensitySimulationLength, 0.95 ) / ApproximateInverseCDFMaxGaussians( ActualSimulationLength, 0.05 );

                    DensityMin = min( min( CurrentResiduals ), -2 * StdResiduals ) * MinMaxScale;
                    DensityMax = max( max( CurrentResiduals ), 2 * StdResiduals ) * MinMaxScale;
                    
                    nPoints = 2 ^ dynareOBC_.DensityAccuracy;
                    
                    [ ~, Density ] = kde( CurrentResiduals, nPoints, DensityMin, DensityMax, Density );
                    Density( Density < 0 ) = 0;
                    Density = Density / sum( Density );
                    
                    [~, ~, ~, ~, ~, BestEver ] = cmaes( @( Values ) DensityObjective( Values, ShadowShockComponents, DensitySimulationLength, nPoints, DensityMin, DensityMax, Density ), ...
                                                        x( ( xIndex+1 ):NewxIndex ), bsxfun( @rdivide, StdResiduals, StdShadowShockCompoents ), CMAESOptions );

                    gx( ( xIndex+1 ):NewxIndex ) = BestEver.x;
                    % M_.params( PI_ShadowShockCombinations( 1 : nSSC, j, i ) ) = BestEver.x;
                end
                xIndex = NewxIndex;

            end
        end
        
        if Iteration > 0
            ofx = fx;
        end
        fx = gx - x;
        fxMax = max( abs( fx ) );
        
        skipline( );
        fprintf( 'End of iteration %d. Maximum change in parameters: %e\n', Iteration, fxMax );
        skipline( );
        
        M_ = M_Internal;
        oo_ = oo_Internal;
        save dynareOBCSemiGlobalResume.mat x M_ oo_;
        save_params_and_steady_state( 'dynareOBCSemiGlobalSteady.txt' );
        
        if fxMax < sqrt( eps )
            x = gx;
            break;
        end
        
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
