function [ Info, M, options, oo, dynareOBC ] = ModelSolution( FirstCall, M, options, oo, dynareOBC, Display )

    if nargin < 6
        Display = true;
    end

    if Display
        skipline( );
        disp( 'Solving the model for specific parameters.' );
        skipline( );
    end

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
        if ~dynareOBC.NoSparse
            if Display
                skipline( );
                disp( 'Converting to sparse matrices.' );
                skipline( );
            end
            DRFieldNames = fieldnames( oo.dr );
            for i = 1 : length( DRFieldNames )
                oo.dr.( DRFieldNames{i} ) = spsparse( oo.dr.( DRFieldNames{i} ) );
            end
            M.Sigma_e = spsparse( M.Sigma_e );
        end

        if Display
            skipline( );
            disp( 'Computing the first order approximation around the selected non-steady-state point.' );
            skipline( );
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

    if ~dynareOBC.NoSparse
        if Display
            skipline( );
            disp( 'Converting to sparse matrices.' );
            skipline( );
        end
        DRFieldNames = fieldnames( oo.dr );
        for i = 1 : length( DRFieldNames )
            oo.dr.( DRFieldNames{i} ) = spsparse( oo.dr.( DRFieldNames{i} ) );
        end
        M.Sigma_e = spsparse( M.Sigma_e );
    end

    if Display
        skipline( );
        disp( 'Saving NLMA parameters.' );
        skipline( );
    end
    global oo_
    oo_ = oo;
    EmptySimulation = pruning_abounds( M, options, [], 0, dynareOBC.Order, 'lan_meyer-gohde', 0 );
    oo = oo_;
    dynareOBC.Constant = EmptySimulation.constant;

    if Display
        skipline( );
        disp( 'Retrieving IRFs to shadow shocks.' );
        skipline( );
    end

    dynareOBC = GetIRFsToShadowShocks( M, options, oo, dynareOBC );

    if Display
        skipline( );
        disp( 'Pre-calculating the augmented state transition matrices and possibly conditional covariances.' );
        skipline( );
    end

    if dynareOBC.NumberOfMax > 0 || ( ~dynareOBC.SlowIRFs ) || dynareOBC.Order2VarianceRequired
        dynareOBC = CacheConditionalCovariancesAndAugmentedStateTransitionMatrices( M, options, oo, dynareOBC );
    end

    dynareOBC.FullNumVarExo = M.exo_nbr;

    if Display
        skipline( );
        disp( 'Reducing the size of decision matrices.' );
        skipline( );
    end

    [ M, oo, dynareOBC ] = ReduceDecisionMatrices( M, oo, dynareOBC );

    if Display
        skipline( );
        disp( 'Performing initial checks on the model.' );
        skipline( );
    end

    dynareOBC = InitialChecks( dynareOBC );
        
end
