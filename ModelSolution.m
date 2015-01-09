function [ Info, M_, options_, oo_Internal ,dynareOBC_ ] = ModelSolution( FirstCall, M_, options_, oo_Internal ,dynareOBC_, Display )

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
        % M_.exo_nbr = dynareOBC_.FullNumVarExo;
        % M_.exo_names_orig_ord = 1:M_.exo_nbr;
        [dr,Info,M_,options_,oo_Internal] = resol(0,M_,options_,oo_Internal);
        oo_Internal.dr = dr;
        if Info ~= 0
            return
        end
    end

    if dynareOBC_.FirstOrderAroundRSS1OrMean2 > 0
        if ~dynareOBC_.NoSparse
            if Display
                skipline( );
                disp( 'Converting to sparse matrices.' );
                skipline( );
            end
            DRFieldNames = fieldnames( oo_Internal.dr );
            for i = 1 : length( DRFieldNames )
                oo_Internal.dr.( DRFieldNames{i} ) = spsparse( oo_Internal.dr.( DRFieldNames{i} ) );
            end
            M_.Sigma_e = spsparse( M_.Sigma_e );
        end

        if Display
            skipline( );
            disp( 'Computing the first order approximation around the selected non-steady-state point.' );
            skipline( );
        end
        dynareOBC_.Order = options_.order;
        deflect_ = compute_deflected_linear_approximation( M_, options_, oo_Internal, dynareOBC_.FirstOrderAroundRSS1OrMean2 );
        dynareOBC_.Order = 1;
    else
        deflect_ = [];
    end
    if ~isempty( deflect_ )
        oo_Internal.dr.ys = deflect_.y;
        oo_Internal.dr.ghx = deflect_.y_x;
        oo_Internal.dr.ghu = deflect_.y_u;
    end
    
    oo_Internal.steady_state = oo_Internal.dr.ys;
    
    if ~dynareOBC_.NoSparse
        if Display
            skipline( );
            disp( 'Converting to sparse matrices.' );
            skipline( );
        end
        DRFieldNames = fieldnames( oo_Internal.dr );
        for i = 1 : length( DRFieldNames )
            oo_Internal.dr.( DRFieldNames{i} ) = spsparse( oo_Internal.dr.( DRFieldNames{i} ) );
        end
        M_.Sigma_e = spsparse( M_.Sigma_e );
    end
    
    if Display
        skipline( );
        disp( 'Saving NLMA parameters.' );
        skipline( );
    end
    global oo_
    oo_ = oo_Internal;
    EmptySimulation = pruning_abounds( M_, options_, [], 0, dynareOBC_.Order, 'lan_meyer-gohde', 0 );
    oo_Internal = oo_;
    dynareOBC_.Constant = EmptySimulation.constant;
    
    if Display
        skipline( );
        disp( 'Retrieving IRFs to shadow shocks.' );
        skipline( );
    end

    dynareOBC_ = GetIRFsToShadowShocks( M_, options_, oo_Internal, dynareOBC_ );

    if Display
        skipline( );
        disp( 'Pre-calculating the augmented state transition matrices and possibly conditional covariances.' );
        skipline( );
    end

    if dynareOBC_.NumberOfMax > 0 || dynareOBC_.FastIRFs || dynareOBC_.Order2VarianceRequired
        dynareOBC_ = CacheConditionalCovariancesAndAugmentedStateTransitionMatrices( M_, options_, oo_Internal, dynareOBC_ );
    end
        
    dynareOBC_.FullNumVarExo = M_.exo_nbr;

    if Display
        skipline( );
        disp( 'Reducing the size of decision matrices.' );
        skipline( );
    end

    [ M_, oo_Internal, dynareOBC_ ] = ReduceDecisionMatrices( M_, oo_Internal, dynareOBC_ );

    if Display
        skipline( );
        disp( 'Performing initial checks on the model.' );
        skipline( );
    end

    dynareOBC_ = InitialChecks( dynareOBC_ );
    
end
