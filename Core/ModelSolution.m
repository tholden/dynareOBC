function [ Info, M, options, oo, dynareOBC ] = ModelSolution( SkipResol, M, options, oo, dynareOBC, SlowMode )

    if nargin < 6
        SlowMode = true;
    end

    if SlowMode
        fprintf( '\n' );
        disp( 'Solving the model for specific parameters.' );
        fprintf( '\n' );
    end

    % temporary work around for warning in dates object.
    options.initial_period = [];
    options.dataset = [];
    
    if SkipResol
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
                fprintf( '\n' );
                disp( 'Converting to sparse matrices.' );
                fprintf( '\n' );
            end
            DRFieldNames = fieldnames( oo.dr );
            for i = 1 : length( DRFieldNames )
                oo.dr.( DRFieldNames{i} ) = spsparse( oo.dr.( DRFieldNames{i} ) );
            end
            M.Sigma_e = spsparse( M.Sigma_e );
        end

        if SlowMode
            fprintf( '\n' );
            disp( 'Computing the first order approximation around the selected non-steady-state point.' );
            fprintf( '\n' );
        end
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
            fprintf( '\n' );
            disp( 'Converting to sparse matrices.' );
            fprintf( '\n' );
        end
        DRFieldNames = fieldnames( oo.dr );
        for i = 1 : length( DRFieldNames )
            oo.dr.( DRFieldNames{i} ) = spsparse( oo.dr.( DRFieldNames{i} ) );
        end
        M.Sigma_e = spsparse( M.Sigma_e );
    end

    if SlowMode
        fprintf( '\n' );
        disp( 'Saving NLMA parameters.' );
        fprintf( '\n' );
    end
    [ EmptySimulation, oo.dr ] = LanMeyerGohdePrunedSimulation( M, oo.dr, [], 0, dynareOBC.Order, 0 );
    dynareOBC.Constant = EmptySimulation.constant;
    
    if SlowMode
        fprintf( '\n' );
        disp( 'Retrieving IRFs to shadow shocks.' );
        fprintf( '\n' );
    end

    dynareOBC = GetIRFsToShadowShocks( M, oo, dynareOBC );

    if SlowMode
        fprintf( '\n' );
        disp( 'Pre-calculating the augmented state transition matrices and possibly conditional covariances.' );
        fprintf( '\n' );
    end

    dynareOBC = CacheConditionalCovariancesAndAugmentedStateTransitionMatrices( M, options, oo, dynareOBC );

    dynareOBC.FullNumVarExo = M.exo_nbr;

%     if SlowMode
%         fprintf( '\n' );
%         disp( 'Reducing the size of decision matrices.' );
%         fprintf( '\n' );
%     end
% 
%     [ M, oo, dynareOBC ] = ReduceDecisionMatrices( M, oo, dynareOBC );

    dynareOBC.ZeroVecS = sparse( dynareOBC.TimeToEscapeBounds * dynareOBC.NumberOfMax, 1 );
    dynareOBC.ParametricSolutionFound = zeros( dynareOBC.TimeToEscapeBounds, 1 );

    if SlowMode
        if ~exist( [ 'dynareOBCTempCustomLanMeyerGohdePrunedSimulation.' mexext ], 'file' ) && ( dynareOBC.CompileSimulationCode || dynareOBC.Estimation )
            fprintf( '\n' );
            disp( 'Attempting to build a custom version of the simulation code.' );
            fprintf( '\n' );
            try
                BuildCustomLanMeyerGohdePrunedSimulation( M, oo, dynareOBC, dynareOBC.Estimation );
            catch Error
                warning( 'dynareOBC:FailedCompilingCustomLanMeyerGohdePrunedSimulation', [ 'Failed to compile a custom version of the simulation code, due to the error: ' Error.message ] );
                dynareOBC.UseSimulationCode = false;
            end
        end

        fprintf( '\n' );
        disp( 'Performing initial checks on the model.' );
        fprintf( '\n' );
        
        dynareOBC = InitialChecks( dynareOBC );
    end

    if SlowMode
        fprintf( '\n' );
        disp( 'Forming optimizer.' );
        fprintf( '\n' );
    end
    dynareOBC = FormOptimizer( dynareOBC );
    
end
