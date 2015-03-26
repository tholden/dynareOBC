function [ Info, M, options, oo ,dynareOBC ] = GlobalModelSolution( M, options, oo, dynareOBC )

    skipline( );
    disp( 'Beginning solving the fixed point problem.' );
    skipline( );
    
    StateVariablesAndShocks = dynareOBC.StateVariablesAndShocks;

    nSVASC = size( dynareOBC.StateVariableAndShockCombinations, 1 );
    
    PI = dynareOBC.ParameterIndices_StateVariableAndShockCombinations;
    m = min(nSVASC,ceil(4+4*(nSVASC-1).^(1/4))); % seems "reasonable" and fits http://users.wpi.edu/~walker/Papers/Walker-Ni,SINUM,V49,1715-1735.pdf
    
    nSVAS = length( StateVariablesAndShocks );
    
    StateVariableAndShockTypes = zeros( 2, nSVAS );
    for i = 1 : nSVAS
        CurrentStateVariableOrShock = StateVariablesAndShocks{i};
        if CurrentStateVariableOrShock == '1'
            StateVariableAndShockTypes( 1, i ) = 0;
            StateVariableAndShockTypes( 2, i ) = 1;
        elseif ismember( CurrentStateVariableOrShock, dynareOBC.StateVariables )
            StateVariableAndShockTypes( 1, i ) = 1;
            StateVariableAndShockTypes( 2, i ) = find( ismember( dynareOBC.EndoVariables, CurrentStateVariableOrShock(1:(end-4)) ), 1 ); % end - 4 remove (-1)
        elseif ismember( CurrentStateVariableOrShock, dynareOBC.Shocks )
            StateVariableAndShockTypes( 1, i ) = 2;
            StateVariableAndShockTypes( 2, i ) = find( ismember( dynareOBC.Shocks, CurrentStateVariableOrShock ), 1 );
        else
            error( 'dynareOBC:UnrecognisedStateVariableOrShock', 'Unrecognised state variable or shock.' );
        end
    end
    
    x = M.params( PI );
    if dynareOBC.Resume
        ResumeData = load( 'dynareOBCGlobalResume.mat' );
        ResumeParamNames = cellstr( ResumeData.M_.param_names );
        NewParamNames = cellstr( M.param_names );
        for i = 1 : length( ResumeParamNames )
            ParamName = ResumeParamNames{ i };
            j = find( strcmp( ParamName, NewParamNames ), 1 );
            M.params( j ) = ResumeData.M_.params( i );
        end
        x = M.params( PI );
    end
    
    MInit = M;
    optionsInit = options;
    ooInit = oo;
    dynareOBCInit = dynareOBC;
    
    global oo_ M_

    StepSize = 0.1;
    InnerIteration = 0;
    for Iteration = 0 : dynareOBC.MaxIterations
        M = MInit;
        options = optionsInit;
        oo = ooInit;
        dynareOBC = dynareOBCInit;
        [ fxNorm, gx, fx, M, oo ] = GlobalModelSolutionInternal( x, Iteration == 0, M, options, oo, dynareOBC, LowerIndices, PI, StateVariableAndShockTypes );
        if Iteration > 0
            if ~isfinite( fxNorm )
                if dynareOBC.FixedPointAcceleration
                    gx = Best_x;
                    fx = gx - x;
                end
            end
        else
            if ~isfinite( fxNorm )
                error( 'dynareOBC:FailedFirstStepGlobal', 'Failed to solve the model at the initial point while computing a global solution.' );
            else
                Best_fxNorm = Inf;
                if ~dynareOBC.FixedPointAcceleration
                    LastFailed = false;
                end
            end
        end
        
        skipline( );
        fprintf( 'End of iteration %d. Norm: %e\n', Iteration, fxNorm );
        
        Save_ofx = false;
        if fxNorm < Best_fxNorm
            M_ = M;
            oo_ = oo;
            save dynareOBCGlobalResume.mat x M_ oo_;
            save_params_and_steady_state( 'dynareOBCGlobalSteady.txt' );
            
            Best_x = x;
            Best_fx = fx;
            Best_fxNorm = fxNorm;
            Save_ofx = true;

            if ~dynareOBC.FixedPointAcceleration
                StepSize = StepSize * 1.1;
                LastFailed = false;
                if Iteration > 0
                    beta = max( 0, fx' * ( fx - ofx ) / ( ofx' * ofx ) );
                    sConj = fx + beta * sConj;
                else
                    beta = 0;
                    sConj = fx;
                end
                skipline( );
                fprintf( 'New conjugate gradient parameter: %e\n', beta );
            end
        else
            if ~dynareOBC.FixedPointAcceleration
                x = Best_x;
                fx = Best_fx;
                if LastFailed
                    StepSize = -StepSize;
                    LastFailed = false;
                else
                    StepSize = StepSize * 0.5;
                    LastFailed = true;
                end
            end
        end
        
        if fxNorm < sqrt( eps * nSVASC )
            x = 0.5 * ( x + gx );
            skipline( );
            disp( 'Convergence obtained.' );
            skipline( );
            break;
        end
        
        if abs( StepSize ) < sqrt( eps )
            x = Best_x;
            skipline( );
            disp( 'Stopping as step size is too small.' );
            skipline( );
            break;
        end       
         
        ox = x;
        if dynareOBC.FixedPointAcceleration
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
        else
            x = x + StepSize * sConj;
            fprintf( 'New step size: %e\n', StepSize );
            skipline( );
        end
        
        if Save_ofx
            ofx = fx;
        end
        
        InnerIteration = InnerIteration + 1;        
    end
    if Iteration >= dynareOBC.MaxIterations
        skipline( );
        warning( 'dynareOBC:ReachedMaxIterations', 'The semi-global solution algorithm reached the maximum allowed number of interations without converging. Results may be inaccurate.' );
        skipline( );
        x = ox;
    end
    M = MInit;
    options = optionsInit;
    oo = ooInit;
    dynareOBC = dynareOBCInit;
    M.params( PI ) = x;

    Info = -1;
    try
        [ dr, Info, M, options, oo ] = resol( 0, M, options, oo );
        oo.dr = dr;
    catch
    end
    if Info ~= 0
        error( 'dynareOBC:GlobalNoSolution', 'At the final point, no determinate solution exists.' );
    end
    M_ = M;
    oo_ = oo;
    save dynareOBCGlobalResume.mat x M_ oo_;
    save_params_and_steady_state( 'dynareOBCGlobalSteady.txt' );
end
