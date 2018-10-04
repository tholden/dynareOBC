function dynareOBC = CacheConditionalCovariancesAndAugmentedStateTransitionMatrices( M, options, oo, dynareOBC )

    T = dynareOBC.InternalIRFPeriods;
    TM1 = T - 1;
    ns = dynareOBC.NumberOfMax;
    SelectState = dynareOBC.SelectState;
    nEndo = M.endo_nbr;
    nExo = M.exo_nbr;
    
    Global = dynareOBC.Global;
    
    dynareOBC.MaxCubatureDimension = min( dynareOBC.MaxCubatureDimension, TM1 * ns );
    
    % pre-calculations for order=1 terms
    A1Trans = sparse( nEndo, nEndo );
    A1Trans( SelectState, : ) = oo.dr.ghx.';
    A1Trans( abs( A1Trans ) < eps ) = 0;

    B1Trans = spsparse( oo.dr.ghu.' );

    Sigma = spsparse( M.Sigma_e );
    dynareOBC.OriginalSigma = Sigma;

    Order2VarianceRequired = ( dynareOBC.Order >= 2 ) && ( dynareOBC.CalculateTheoreticalVariance || Global );
    JustCalculateMean = dynareOBC.NumberOfMax == 0 && dynareOBC.SlowIRFs && ( ~Order2VarianceRequired );
    
    if ( dynareOBC.Order == 1 ) || Order2VarianceRequired || dynareOBC.SimulateOnGridPoints
        dynareOBC.Var_z1 = SparseLyapunovSymm( A1Trans, B1Trans.' * Sigma * B1Trans );
    end
    if ( dynareOBC.Order == 1 ) && Global
        dynareOBC.UnconditionalVarXi = Sigma;
        dynareOBC.LengthXi = size( Sigma, 1 );
    end
    
    LengthZ1 = size( A1Trans, 1 );
        
    if ~JustCalculateMean
        A1PowersTrans = cell( TM1, 1 );
        A1PowersTrans{1} = speye( size( A1Trans ) );

        for k = 2 : TM1
            A1PowersTrans{ k } = A1PowersTrans{ k - 1 } * A1Trans;
            A1PowersTrans{ k }( abs( A1PowersTrans{ k } ) < eps ) = 0;
        end
        VarianceZ1 = cell( TM1, 1 );
        VarianceZ1Global = cell( TM1, 1 );

        BCovXiB = B1Trans.' * Sigma * B1Trans;

        PeriodsOfUncertainty = dynareOBC.PeriodsOfUncertainty;
    
        for k = 1 : TM1
            VarianceZ1{ k } = sparse( LengthZ1, LengthZ1 );
            for i = 1 : min( k, PeriodsOfUncertainty )
                iWeight = 0.5 * ( 1 + cos( pi * ( i - 1 ) / PeriodsOfUncertainty ) );
                CurrentVariance = A1PowersTrans{ k - i + 1 }.' * ( iWeight * BCovXiB ) * A1PowersTrans{ k - i + 1 };
                CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                VarianceZ1{ k } = VarianceZ1{ k } + CurrentVariance;
            end
            if Global
                VarianceZ1Global{ k } = sparse( LengthZ1, LengthZ1 );
                for i = 1 : k
                    CurrentVariance = A1PowersTrans{ k - i + 1 }.' * BCovXiB * A1PowersTrans{ k - i + 1 };
                    CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                    VarianceZ1Global{ k } = VarianceZ1Global{ k } + CurrentVariance;
                end
            end
        end 
    end
    
    if options.order == 1 || dynareOBC.Order == 1
        dynareOBC.SecondOrderConditionalCovariance = false;
    end
    Order2ConditionalCovariance = ( ~dynareOBC.NoCubature ) && dynareOBC.SecondOrderConditionalCovariance;
    
    if dynareOBC.Order > 1 || Order2ConditionalCovariance
        % pre-calculations common to finding the state transition when dynareOBC_.Order > 1 and to finding the conditional covariance when Order2ConditionalCovariance=true
        
        nState = length( SelectState );
        nExo2 = nExo * nExo;
        
        % Idx1 =  1:nEndo;
        % Idx2 = (nEndo+1):(2*nEndo);
        % Idx3 = (2*nEndo+1):LengthZ2;
        
        % A2( Idx1, Idx1 ) = A1;
        [ A1j, A1i, A1s ] = vfind( A1Trans );
        
        A2i = A1i;
        A2j = A1j;
        A2s = A1s;
        
        % A2( Idx2, Idx2 ) = A1;
        A2i = [ A2i; A2i + nEndo ];
        A2j = [ A2j; A2j + nEndo ];
        A2s = [ A2s; A2s ];
        
        % A2( Idx2, Idx3 ) = 0.5 * oo_.dr.ghxx;
        beta22 = spsparse( oo.dr.ghxx );
        [ Tmpi, Tmpj, Tmps ] = vfind( beta22 );
        A2i = [ A2i; Tmpi + nEndo ];
        A2j = [ A2j; Tmpj + 2*nEndo ];
        A2s = [ A2s; 0.5 * Tmps ];
        
        % A2( Idx3, Idx3 ) = spkron( oo_.dr.ghx( SelectState, : ), oo_.dr.ghx( SelectState, : ) );
        A1S = A1Trans( SelectState, SelectState ).';
        A1S2 = spkron( A1S, A1S );
        [ Tmpi, Tmpj, Tmps ] = vfind( A1S2 );
        A2i = [ A2i; Tmpi + 2*nEndo ];
        A2j = [ A2j; Tmpj + 2*nEndo ];
        A2s = [ A2s; Tmps ];
        
        nState2 = nState * nState;
        LengthZ2 = 2 * nEndo + nState2;
        
        A2Trans = sparse( A2j, A2i, A2s, LengthZ2, LengthZ2 );
 
        B1S = B1Trans( :, SelectState ).';
        B1S2 = spkron( B1S, B1S );
        
    end
    
    if dynareOBC.Order > 2 || Order2ConditionalCovariance || Order2VarianceRequired
        K_nState_nState = commutation_sparse( nState, nState );        
    end
    
    if Order2ConditionalCovariance || Order2VarianceRequired

        % Jdx1 = 1:nExo;
        % Jdx2 = (nExo+1):(nExo + nExo2);
        % Jdx3 = (nExo + nExo2 + 1):LengthXi;

        % B2( Idx1, Jdx1 ) = oo_.dr.ghu;
        [ B2j, B2i, B2s ] = vfind( B1Trans );

        % B2( Idx2, Jdx2 ) = 0.5 * oo_.dr.ghuu;
        [ Tmpi, Tmpj, Tmps ] = spfind( 0.5 * oo.dr.ghuu );
        B2i = [ B2i; Tmpi + nEndo ];
        B2j = [ B2j; Tmpj + nExo ];
        B2s = [ B2s; Tmps ];

        % B2( Idx2, Jdx3 ) = oo_.dr.ghxu;
        [ Tmpi, Tmpj, Tmps ] = spfind( oo.dr.ghxu );
        B2i = [ B2i; Tmpi + nEndo ];
        B2j = [ B2j; Tmpj + nExo + nExo2 ];
        B2s = [ B2s; Tmps ];

        % B2( Idx3, Jdx2 ) = spkron( oo_.dr.ghu( SelectState, : ), oo_.dr.ghu( SelectState, : ) );
        [ Tmpi, Tmpj, Tmps ] = vfind( B1S2 );
        B2i = [ B2i; Tmpi + 2*nEndo ];
        B2j = [ B2j; Tmpj + nExo ];
        B2s = [ B2s; Tmps ];

        % B2( Idx3, Jdx3 ) = ( speye( nState * nState ) + commutation_sparse( nState, nState ) ) * spkron( oo_.dr.ghx( SelectState, : ), oo_.dr.ghu( SelectState, : ) );
        [ Tmpi, Tmpj, Tmps ] = vfind( ( speye( nState2 ) + K_nState_nState ) * spkron( A1S, B1S ) );
        B2i = [ B2i; Tmpi + 2*nEndo ];
        B2j = [ B2j; Tmpj + nExo + nExo2 ];
        B2s = [ B2s; Tmps ];

        LengthXi = nExo + nExo2 + nState * nExo;

        B2Trans = sparse( B2j, B2i, B2s, LengthXi, LengthZ2 );  

        % BCovXiB{i}( Jdx1, Jdx1 ) = Sigma;

        % BCovXiB{i}( Jdx2, Jdx2 ) = dynareOBC_.Variance_exe;
        [ Ci, Cj, Cs ] = vfind( ( speye( nExo2 ) + commutation_sparse( nExo, nExo ) ) * spkron( Sigma, Sigma ) );
        Ci = Ci + nExo;
        Cj = Cj + nExo;
        
    end
        
    if Order2VarianceRequired
        
        [ Vi, Vj, Vs ] = vfind( Sigma );
        [ Tmpi, Tmpj, Tmps ] = spkron( dynareOBC.Var_z1( SelectState, SelectState ), Sigma );
        Ui = [ Vi; Ci; Tmpi + nExo + nExo2 ];
        Uj = [ Vj; Cj; Tmpj + nExo + nExo2 ];
        Us = [ Vs; Cs; Tmps ];

        UnconditionalVarXi = sparse( Ui, Uj, Us, LengthXi, LengthXi );
        dynareOBC.UnconditionalVarXi = UnconditionalVarXi;

        dynareOBC.Var_z2 = SparseLyapunovSymm( A2Trans, B2Trans.' * UnconditionalVarXi * B2Trans );
    end
    
    if dynareOBC.Order > 2
        
        A3i = A2i;
        A3j = A2j;
        A3s = A2s;
        
        T1 = sparse( nEndo, nEndo );
        T1( :, SelectState ) = 0.5 * oo.dr.ghxss_nlma;

        [ Tmpi, Tmpj, Tmps ] = spfind( T1 );
        A3i = [ A3i; Tmpi + LengthZ2 ];
        A3j = [ A3j; Tmpj ];
        A3s = [ A3s; Tmps ];
        
        k1 = LengthZ2 + nEndo;
        A3i = [ A3i; A1i + LengthZ2; A1i + k1 ];
        A3j = [ A3j; A1j + LengthZ2; A1j + k1 ];
        A3s = [ A3s; A1s; A1s ];
        
        IKVecSigma = spkron( speye( nState ), vec( Sigma ) );
        T1 = sparse( nEndo, nEndo );
        T1( :, SelectState ) = 0.5 * oo.dr.ghxuu * IKVecSigma;
        [ Tmpi, Tmpj, Tmps ] = spfind( T1 );
        A3i = [ A3i; Tmpi + k1 ];
        A3j = [ A3j; Tmpj ];
        A3s = [ A3s; Tmps ];
        
        k2 = k1 + nEndo;
        [ Tmpi, Tmpj, Tmps ] = vfind( beta22 );
        A3i = [ A3i; Tmpi + k1 ];
        A3j = [ A3j; Tmpj + k2 ];
        A3s = [ A3s; Tmps ];

        k3 = k2 + nState2;
        [ Tmpi, Tmpj, Tmps ] = spfind( (1/6) * oo.dr.ghxxx );
        A3i = [ A3i; Tmpi + k1 ];
        A3j = [ A3j; Tmpj + k3 ];
        A3s = [ A3s; Tmps ];
        
        T1 = sparse( nState2, nEndo );
        T1( :, SelectState ) = ( spkron( oo.dr.ghxu( SelectState, : ), B1S ) + 0.5 * K_nState_nState * spkron( A1S, oo.dr.ghuu( SelectState, : ) ) ) * IKVecSigma;
        [ Tmpi, Tmpj, Tmps ] = spfind( T1 );
        A3i = [ A3i; Tmpi + k2 ];
        A3j = [ A3j; Tmpj ];
        A3s = [ A3s; Tmps ];
        
        [ Tmpi, Tmpj, Tmps ] = vfind( A1S2 );
        A3i = [ A3i; Tmpi + k2 ];
        A3j = [ A3j; Tmpj + k2 ];
        A3s = [ A3s; Tmps ];
        
        [ Tmpi, Tmpj, Tmps ] = spkron( 0.5 * beta22( SelectState, : ), A1S );
        A3i = [ A3i; Tmpi + k2 ];
        A3j = [ A3j; Tmpj + k3 ];
        A3s = [ A3s; Tmps ];
        
        nState3 = nState2 * nState;
        T1 = sparse( nState3, nEndo );
        T1( :, SelectState ) = ( ( spkron( speye( nState2 ) + K_nState_nState, speye( nState ) ) + commutation_sparse( nState2, nState ) ) * spkron( A1S, B1S2 ) ) * IKVecSigma;
        [ Tmpi, Tmpj, Tmps ] = vfind( T1 );
        A3i = [ A3i; Tmpi + k3 ];
        A3j = [ A3j; Tmpj ];
        A3s = [ A3s; Tmps ];
        
        [ Tmpi, Tmpj, Tmps ] = spkron( A1S, A1S2 );
        A3i = [ A3i; Tmpi + k3 ];
        A3j = [ A3j; Tmpj + k3 ];
        A3s = [ A3s; Tmps ];
        
        LengthZ3 = k3 + nState3;
        A3Trans = sparse( A3j, A3i, A3s, LengthZ3, LengthZ3 );
        
    end
    
    % Save augmented state transition matrices
    if dynareOBC.Order == 1
        dynareOBC.ATrans = A1Trans;
        dynareOBC.AugmentedToTotal = speye( nEndo );
    elseif dynareOBC.Order == 2
        dynareOBC.ATrans = A2Trans;
        dynareOBC.AugmentedToTotal = [ speye( nEndo ) speye( nEndo ) sparse( nEndo, nState2 ) ];
    elseif dynareOBC.Order == 3
        dynareOBC.ATrans = A3Trans;
        dynareOBC.AugmentedToTotal = [ speye( nEndo ) speye( nEndo ) sparse( nEndo, nState2 ) speye( nEndo ) speye( nEndo ) sparse( nEndo, nState2 + nState3 ) ];
    else
        error( 'dynareOBC:UnsupportedOrder', 'Order %d is unsupported at present. The only currently supported orders are 1, 2 and 3.', dynareOBC.Order );
    end
    dynareOBC.CoreSelectInAugmented = any( dynareOBC.AugmentedToTotal );

    % Calculate mean
    if dynareOBC.Order == 1
        c = sparse( nEndo, 1 );
    else
        [ MOi, MOj, MOs ] = spfind( 0.5 * ( oo.dr.ghuu * vec( Sigma ) ) );
        [ Tmpi, Tmpj, Tmps ] = spfind( B1S2 * vec( Sigma ) );
        MOi = [ MOi + nEndo; Tmpi + 2*nEndo ];
        MOj = [ MOj; Tmpj ];
        MOs = [ MOs; Tmps ];
        if dynareOBC.Order == 2
            c = sparse( MOi, MOj, MOs, LengthZ2, 1 );
        else
            c = sparse( MOi, MOj, MOs, LengthZ3, 1 );
        end
    end
    dynareOBC.c = c;
    Mean_z = ( speye( size( dynareOBC.ATrans.' ) ) - dynareOBC.ATrans.' ) \ c;
    dynareOBC.Mean_z = Mean_z;
    
    % disp( eigs( dynareOBC_.A, 5 ) );
    
    RelativeMean = dynareOBC.AugmentedToTotal * Mean_z;
    dynareOBC.RelativeMean = RelativeMean( oo.dr.inv_order_var );
    dynareOBC.Mean = dynareOBC.RelativeMean + dynareOBC.Constant;
    
    if JustCalculateMean
        return
    end
    
    % Calculate conditional covariances
    if ~dynareOBC.NoCubature
        if ~Order2ConditionalCovariance

            ConditionalCovariance = zeros( T * ns, T * ns );
            StepIndices = 0:T:T*(ns-1);

            inv_order_var = oo.dr.inv_order_var;
            VarIndices_ZeroLowerBounded = dynareOBC.VarIndices_ZeroLowerBounded;

            LengthConditionalCovarianceTemp = 0.5 * TM1 * T;
            ConditionalCovarianceTemp = cell( LengthConditionalCovarianceTemp, 1 );

            for i = 1 : LengthConditionalCovarianceTemp
                p = floor( 0.5 * ( 1 + sqrt( 8 * i - 7 ) ) );
                q = i - 0.5 * p * ( p - 1 );
                % p and q are indexes of the lower triangle of a matrix, p>=q
                CurrentCov = A1PowersTrans{ p - q + 1 }.' * VarianceZ1{ q }; % * A1Powers{ q - q + 1 }' = eye; 
                ReducedCov = full( CurrentCov( inv_order_var( VarIndices_ZeroLowerBounded ), inv_order_var( VarIndices_ZeroLowerBounded ) ) );
                ConditionalCovarianceTemp{i} = ReducedCov;
            end

            for p = 1 : TM1
                for q = 1 : p
                    i = 0.5 * p * ( p - 1 ) + q;
                    ConditionalCovariance( 1 + p + StepIndices, 1 + q + StepIndices ) = ConditionalCovarianceTemp{i};
                end
                for q = (p+1) : TM1
                    i = 0.5 * q * ( q - 1 ) + p;
                    ConditionalCovariance( 1 + p + StepIndices, 1 + q + StepIndices ) = ConditionalCovarianceTemp{i}';
                end
            end

            ConditionalCovariance = 0.5 * ( ConditionalCovariance + ConditionalCovariance.' );
            
            dynareOBC.RootConditionalCovariance = ObtainRootConditionalCovariance( ConditionalCovariance, dynareOBC.CubaturePruningCutOff, dynareOBC.MaxCubatureDimension );
           
            if Global
                ConditionalVarianceGlobal = zeros( T * ns, 1 );
                
                for p = 1 : TM1
                    CurrentCov = VarianceZ1Global{ p };
                    ReducedCov = full( CurrentCov( inv_order_var( VarIndices_ZeroLowerBounded ), inv_order_var( VarIndices_ZeroLowerBounded ) ) );
                    ConditionalVarianceGlobal( 1 + p + StepIndices, 1 ) = ReducedCov;
                end
                
                GlobalVarianceShare = max( 0, min( 1, diag( ConditionalCovariance ) ./ max( eps, ConditionalVarianceGlobal ) ) );
                GlobalVarianceShare( 1 + StepIndices, 1 ) = 1;

                dynareOBC.GlobalVarianceShare = GlobalVarianceShare;
                
                EndVarianceShare = max( GlobalVarianceShare( T + StepIndices, 1 ) );
                if EndVarianceShare > eps
                    error( 'dynareOBC:InternalIRFPeriodsTooLow', 'Please increase TimeToReturnToSteadyState as it is currently too low for global simulation. Current end variance share: %.17g', EndVarianceShare );
                end
            else
                dynareOBC.GlobalVarianceShare = [];
            end
            
            dynareOBC.LengthXi = size( Sigma, 1 );

        else

            if options.order > 2
                warning( 'dynareOBC:ApproximatingConditionalCovariance', 'At present, dynareOBC approximates the conditional covariance of third order approximations with the conditional covariance of a second order approximation.' );
            end

            A2PowersTrans = cell( TM1, 1 );
            A2PowersTrans{1} = eye( size( A2Trans ) );

            for k = 2 : TM1
                A2PowersTrans{ k } = full( A2PowersTrans{ k - 1 } * A2Trans );
                % A2PowersTrans{ k }( abs( A2PowersTrans{ k } ) < eps ) = 0;
            end

            VarianceY1State = cell( TM1, 1 );
            VarianceY1State{1} = zeros( nState );
            
            VarianceY1StateGlobal = cell( TM1, 1 );
            if Global
                VarianceY1StateGlobal{1} = zeros( nState );
            end

            for k = 2 : TM1
                VarianceY1State{k} = VarianceZ1{ k - 1 }( SelectState, SelectState );
                if Global
                    VarianceY1StateGlobal{k} = VarianceZ1Global{ k - 1 }( SelectState, SelectState );
                end
            end

            % dynareOBC_.A1Powers = A1Powers;
            dynareOBC.A2PowersTrans = A2PowersTrans;
            dynareOBC.B2Trans = B2Trans;
            dynareOBC.VarianceY1State = VarianceY1State;
            dynareOBC.LengthXi = LengthXi;
            
            if Global
                dynareOBC.VarianceY1StateGlobal = VarianceY1StateGlobal;
            end

            dynareOBC.VarianceXiSkeleton = sparse( Ci, Cj, Cs, LengthXi, LengthXi );

        end
    end
end