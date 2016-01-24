function [ Info, M, options, oo, dynareOBC ] = ModelSolution( FirstCall, M, options, oo, dynareOBC, SlowMode )

    if nargin < 6
        SlowMode = true;
    end

    if SlowMode
        fprintf( 1, '\n' );
        disp( 'Solving the model for specific parameters.' );
        fprintf( 1, '\n' );
    end

    % temporary work around for warning in dates object.
    options.initial_period = [];
    options.dataset = [];
    
    if FirstCall
        Info = 0;
    else
        [ dr, Info, M, options, oo ] = resol( 0, M, options, oo );
        oo.dr = dr;
        if Info ~= 0
            return
        end
    end

    if dynareOBC.FirstOrderAroundRSS1OrMean2 > 0
        if dynareOBC.Sparse
            if SlowMode
                fprintf( 1, '\n' );
                disp( 'Converting to sparse matrices.' );
                fprintf( 1, '\n' );
            end
            DRFieldNames = fieldnames( oo.dr );
            for i = 1 : length( DRFieldNames )
                oo.dr.( DRFieldNames{i} ) = spsparse( oo.dr.( DRFieldNames{i} ) );
            end
            M.Sigma_e = spsparse( M.Sigma_e );
        end

        if SlowMode
            fprintf( 1, '\n' );
            disp( 'Computing the first order approximation around the selected non-steady-state point.' );
            fprintf( 1, '\n' );
        end
        dynareOBC.Order = options.order;
        deflect_ = compute_deflected_linear_approximation( M, options, oo, dynareOBC.FirstOrderAroundRSS1OrMean2 );
        dynareOBC.Order = 1;
    else
        deflect_ = [];
    end
    if ~isempty( deflect_ )
        oo.dr.ys = deflect_.y;
        oo.dr.ghx = deflect_.y_x;
        oo.dr.ghu = deflect_.y_u;
    end

    oo.steady_state = oo.dr.ys;

    if dynareOBC.Sparse
        if SlowMode
            fprintf( 1, '\n' );
            disp( 'Converting to sparse matrices.' );
            fprintf( 1, '\n' );
        end
        DRFieldNames = fieldnames( oo.dr );
        for i = 1 : length( DRFieldNames )
            oo.dr.( DRFieldNames{i} ) = spsparse( oo.dr.( DRFieldNames{i} ) );
        end
        M.Sigma_e = spsparse( M.Sigma_e );
    end

    if SlowMode
        fprintf( 1, '\n' );
        disp( 'Saving NLMA parameters.' );
        fprintf( 1, '\n' );
    end
    [ EmptySimulation, oo.dr ] = LanMeyerGohdePrunedSimulation( M, oo.dr, [], 0, dynareOBC.Order, 0 );
    dynareOBC.Constant = EmptySimulation.constant;
    
    if SlowMode
        fprintf( 1, '\n' );
        disp( 'Retrieving IRFs to shadow shocks.' );
        fprintf( 1, '\n' );
    end

    dynareOBC = GetIRFsToShadowShocks( M, oo, dynareOBC );

    if SlowMode
        fprintf( 1, '\n' );
        disp( 'Pre-calculating the augmented state transition matrices and possibly conditional covariances.' );
        fprintf( 1, '\n' );
    end

    Order2VarianceRequired = ( dynareOBC.Order >= 2 ) && ( dynareOBC.CalculateTheoreticalVariance || dynareOBC.Global );
    if dynareOBC.NumberOfMax > 0 || ( ~dynareOBC.SlowIRFs ) || Order2VarianceRequired
        dynareOBC = CacheConditionalCovariancesAndAugmentedStateTransitionMatrices( M, options, oo, dynareOBC );
    end

    dynareOBC.FullNumVarExo = M.exo_nbr;

%     if SlowMode
%         fprintf( 1, '\n' );
%         disp( 'Reducing the size of decision matrices.' );
%         fprintf( 1, '\n' );
%     end
% 
%     [ M, oo, dynareOBC ] = ReduceDecisionMatrices( M, oo, dynareOBC );

    dynareOBC.ZeroVecS = sparse( dynareOBC.TimeToEscapeBounds * dynareOBC.NumberOfMax, 1 );
    dynareOBC.ParametricSolutionFound = 0;

    if SlowMode
        if ~exist( [ 'dynareOBCTempCustomLanMeyerGohdePrunedSimulation.' mexext ], 'file' ) && ( dynareOBC.CompileSimulationCode || dynareOBC.Estimation )
            if SlowMode
                fprintf( 1, '\n' );
                disp( 'Attempting to build a custom version of the simulation code.' );
                fprintf( 1, '\n' );
            end
            try
                BuildCustomLanMeyerGohdePrunedSimulation( M, oo, dynareOBC, dynareOBC.Estimation );
            catch Error
                warning( 'dynareOBC:FailedCompilingCustomLanMeyerGohdePrunedSimulation', [ 'Failed to compile a custom version of the simulation code, due to the error: ' Error.message ] );
                dynareOBC.UseSimulationCode = false;
            end
        end

        fprintf( 1, '\n' );
        disp( 'Performing initial checks on the model.' );
        fprintf( 1, '\n' );
        
        dynareOBC = InitialChecks( dynareOBC );
    end

    if SlowMode
        fprintf( 1, '\n' );
        disp( 'Forming optimizer.' );
        fprintf( 1, '\n' );
    end
    dynareOBC = FormOptimizer( dynareOBC );
    
    dynareOBC = orderfields( dynareOBC );

    StoreGlobals( M, options, oo, dynareOBC );
    
end
