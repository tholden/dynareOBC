function [ Info, M_Internal, options_, oo_Internal ,dynareOBC_ ] = GlobalModelSolution( M_Internal, options_, oo_Internal ,dynareOBC_ )

    skipline( );
    disp( 'Beginning the semi-global solution of the model.' );
    skipline( );
    
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
    
    nSVAS = length( StateVariablesAndShocks );
    nSS = dynareOBC_.ShadowShockNumberMultiplier;
    nSSC = size( ShadowShockCombinations, 1 );
    
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
    
    [ ShadowQuadratureWeights, ShadowQuadratureNodes, ShadowQuadratureLength ] = fwtpts( nSS, ceil( 0.5 * ( ( nSSC + 1 ) * dynareOBC_.ShadowOrder - 1 ) ) );
    
    ShadowShockComponents = ones( ShadowQuadratureLength, nSSC );
    for k = 1 : nSSC
        ShadowShockCombination = ShadowShockCombinations( k, : );
        ShockMeanOne = true;
        for l = 1 : nSS
            ShockPower = ShadowShockCombination( l );
            if ShockPower > 0
                if mod( ShockPower, 2 ) == 1
                    ShockMeanOne = false;
                end
                ShadowShockComponents( :, k ) = ShadowShockComponents( :, k ) .* ( ShadowQuadratureNodes( l, : )' .^ ShockPower );
            end
        end
        if ShockMeanOne
            ShadowShockComponents( :, k ) = ShadowShockComponents( :, k ) - 1;
        end
    end 
    
    fsolveOptions = optimset( 'display', 'off', 'Jacobian', 'on', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolFun', eps, 'TolX', eps );
    
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
    InnerIteration = 0;
    for Iteration = 0 : dynareOBC_.MaxIterations
        [ fxNorm, gx, fx, M_Internal, oo_Internal ] = GlobalModelSolutionInternal( x, Iteration == 0, M_Internal, options_, oo_Internal, dynareOBC_, LowerIndices, PI, StateVariableAndShockTypes, fsolveOptions, ShadowQuadratureWeights, ShadowShockComponents );
        if Iteration > 0
            if ~isfinite( fxNorm )
                if dynareOBC_.FixedPointAcceleration
                    x = 0.5 * x + 0.5 * ox;
                else
                    if LastFailed
                        StepSize = -StepSize;
                        LastFailed = false;
                    else
                        StepSize = StepSize * 0.5;
                        LastFailed = true;
                    end
                    x = ox + StepSize * fx;
                end
                continue;
            else
                ofx = fx;
                ofxNorm = fxNorm;
            end
        else
            if ~isfinite( fxNorm )
                error( 'dynareOBC:FailedFirstStepGlobal', 'Failed to solve the model at the initial point while computing a global solution.' );
            else
                ofx = [];
                ofxNorm = Inf;
                if ~dynareOBC_.FixedPointAcceleration
                    LastFailed = false;
                end
            end
        end
        
        skipline( );
        fprintf( 'End of iteration %d. Change in parameters: %e\n', Iteration, fxNorm );
        
        if fxNorm < sqrt( eps * nPI )
            x = 0.5 * ( x + gx );
            skipline( );
            break;
        end
        
        if fxNorm <= ofxNorm
            M_ = M_Internal;
            oo_ = oo_Internal;
            save dynareOBCSemiGlobalResume.mat x M_ oo_;
            save_params_and_steady_state( 'dynareOBCSemiGlobalSteady.txt' );

            if ~dynareOBC_.FixedPointAcceleration
                ox = x;
                x = ox + StepSize * fx;
                StepSize = StepSize * 1.1;
                LastFailed = false;
            end
        else
            if ~dynareOBC_.FixedPointAcceleration
                % x = ox;
                fx = ofx;
                fxNorm = ofxNorm;
                if LastFailed
                    StepSize = -StepSize;
                    LastFailed = false;
                else
                    StepSize = StepSize * 0.5;
                    LastFailed = true;
                end
                x = ox + StepSize * fx;
            end
        end
        if ~dynareOBC_.FixedPointAcceleration
            fprintf( 'New step size: %e\n', StepSize );
            skipline( );
        end
        
        if dynareOBC_.FixedPointAcceleration
            ox = x;
            if InnerIteration > 0
                dfx = fx - ofx;
                if InnerIteration > 1
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
            if InnerIteration > 0
                SX( :, end + 1 ) = dx; %#ok<AGROW>
                if size( SX, 2 ) > m
                    SX( :, 1 ) = [];
                end
            else
                SX = dx;
            end
        end

        InnerIteration = InnerIteration + 1;        
    end
    if fxNorm < sqrt( eps * nPI )
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
        x = ox;
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
