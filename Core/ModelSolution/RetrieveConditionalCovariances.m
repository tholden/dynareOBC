function [ RootConditionalCovariance, GlobalVarianceShare ] = RetrieveConditionalCovariances( oo, dynareOBC, ReturnPathFirstOrder )
    
    if dynareOBC.FirstOrderConditionalCovariance
        
        RootConditionalCovariance = dynareOBC.RootConditionalCovariance;
        GlobalVarianceShare = dynareOBC.GlobalVarianceShare;
        
    else
        
        T = dynareOBC.InternalIRFPeriods;
        TM1 = T - 1;
        ns = dynareOBC.NumberOfMax;
        
        LengthXi = dynareOBC.LengthXi;
        Sigma = dynareOBC.OriginalSigma;
        
        ReturnPathFirstOrder = ReturnPathFirstOrder( oo.dr.order_var( dynareOBC.SelectState ), : );
        
        nExo = dynareOBC.FullNumVarExo;
        Offset3 = nExo + nExo * nExo;
        
        % Jdx1 = 1:M_.exo_nbr;
        % Jdx2 = (M_.exo_nbr+1):Offset3;
        % Jdx3 = (Offset3 + 1):LengthXi;

        % BCovXiB{i}( Jdx1, Jdx1 ) = Sigma;
        [ Vi, Vj, Vs ] = vfind( Sigma );
        [ Ci, Cj, Cs ] = vfind( dynareOBC.VarianceXiSkeleton );
            
        BCovXiB = cell( TM1, 1 );
        BCovXiBGlobal = cell( TM1, 1 );
        
        VarianceY1State = dynareOBC.VarianceY1State;
        
        Global = dynareOBC.Global;
        
        B2Trans = dynareOBC.B2Trans;
        
        PeriodsOfUncertainty = dynareOBC.PeriodsOfUncertainty;
        
        A2PowersTrans = dynareOBC.A2PowersTrans;
        LengthZ2 = size( A2PowersTrans{1}, 1 );
        
        ParallelMode = isempty( getCurrentTask ) && ( LengthZ2 >= dynareOBC.RetrieveConditionalCovariancesParallelizationCutOff );

        ReturnPathFirstOrderProduct = ReturnPathFirstOrder * ReturnPathFirstOrder.';
        
        if ParallelMode
            parfor i = 1 : PeriodsOfUncertainty
                iWeight = 0.5 * ( 1 + cos( pi * ( i - 1 ) / PeriodsOfUncertainty ) );

                CurrentSigma = iWeight * Sigma;
                % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
                % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
                % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
                [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), CurrentSigma );
                % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
                [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrderProduct + VarianceY1State{i}, CurrentSigma );
                Tmpi = Tmpi + Offset3;
                Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                Cs2 = [ Vs * iWeight; Cs * iWeight * iWeight; Tmps; Tmps; Tmps2 ];

                BCovXiBTmp = zeros( LengthXi ); % sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );
                BCovXiBTmp( sub2ind( [ LengthXi, LengthXi ], Ci2, Cj2 ) ) = Cs2;

                BCovXiB{i} = full( B2Trans.' * BCovXiBTmp * B2Trans );

            end

            if Global
                VarianceY1StateGlobal = dynareOBC.VarianceY1StateGlobal;

                parfor i = 1 : TM1
                    % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
                    % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
                    % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
                    [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), Sigma );
                    % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
                    [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrderProduct + VarianceY1StateGlobal{i}, Sigma );
                    Tmpi = Tmpi + Offset3;
                    Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                    Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                    Cs2 = [ Vs; Cs; Tmps; Tmps; Tmps2 ];

                    BCovXiBGlobalTmp = zeros( LengthXi ); % sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );
                    BCovXiBGlobalTmp( sub2ind( [ LengthXi, LengthXi ], Ci2, Cj2 ) ) = Cs2;

                    BCovXiBGlobal{i} = full( B2Trans.' * BCovXiBGlobalTmp * B2Trans );

                end
            end
        else
            for i = 1 : PeriodsOfUncertainty
                iWeight = 0.5 * ( 1 + cos( pi * ( i - 1 ) / PeriodsOfUncertainty ) );

                CurrentSigma = iWeight * Sigma;
                % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
                % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
                % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
                [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), CurrentSigma );
                % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
                [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrderProduct + VarianceY1State{i}, CurrentSigma );
                Tmpi = Tmpi + Offset3;
                Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                Cs2 = [ Vs * iWeight; Cs * iWeight * iWeight; Tmps; Tmps; Tmps2 ];

                BCovXiBTmp = zeros( LengthXi ); % sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );
                BCovXiBTmp( sub2ind( [ LengthXi, LengthXi ], Ci2, Cj2 ) ) = Cs2;

                BCovXiB{i} = full( B2Trans.' * BCovXiBTmp * B2Trans );

            end

            if Global
                VarianceY1StateGlobal = dynareOBC.VarianceY1StateGlobal;

                for i = 1 : TM1
                    % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
                    % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
                    % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
                    [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), Sigma );
                    % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
                    [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrderProduct + VarianceY1StateGlobal{i}, Sigma );
                    Tmpi = Tmpi + Offset3;
                    Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                    Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                    Cs2 = [ Vs; Cs; Tmps; Tmps; Tmps2 ];

                    BCovXiBGlobalTmp = zeros( LengthXi ); % sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );
                    BCovXiBGlobalTmp( sub2ind( [ LengthXi, LengthXi ], Ci2, Cj2 ) ) = Cs2;

                    BCovXiBGlobal{i} = full( B2Trans.' * BCovXiBGlobalTmp * B2Trans );

                end
            end            
        end
        
        VarianceZ2 = cell( TM1, 1 );
        VarianceZ2Global = cell( TM1, 1 );
        
        inv_order_var = oo.dr.inv_order_var;
        VarIndices_ZeroLowerBounded = dynareOBC.VarIndices_ZeroLowerBounded;
        
        inv_order_var_VarIndices_ZeroLowerBounded = inv_order_var( VarIndices_ZeroLowerBounded );
        
        LengthCrit = numel( inv_order_var_VarIndices_ZeroLowerBounded );
        
        if ParallelMode
            parfor k = 1 : TM1
                VarianceZ2{ k } = zeros( LengthZ2, LengthCrit );
                for i = 1 : min( k, PeriodsOfUncertainty )
                    CurrentVariance = A2PowersQuadraticForm( k - i + 1, BCovXiB{ i }, inv_order_var_VarIndices_ZeroLowerBounded ); %#ok<PFBNS>
                    % CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                    VarianceZ2{ k } = VarianceZ2{ k } + CurrentVariance;
                end
                if Global
                    VarianceZ2Global{ k } = zeros( LengthCrit, LengthCrit );
                    for i = 1 : k
                        CurrentVariance = A2PowersQuadraticFormGlobal( k - i + 1, BCovXiBGlobal{ i }, inv_order_var_VarIndices_ZeroLowerBounded ); %#ok<PFBNS>
                        % CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                        VarianceZ2Global{ k } = VarianceZ2Global{ k } + CurrentVariance;
                    end
                end
            end
        else
            for k = 1 : TM1
                VarianceZ2{ k } = zeros( LengthZ2, LengthCrit );
                for i = 1 : min( k, PeriodsOfUncertainty )
                    CurrentVariance = ( BCovXiB{ i }.' * A2PowersTrans{ k - i + 1 } ).' * A2PowersTrans{ k - i + 1 }( :, inv_order_var_VarIndices_ZeroLowerBounded ); 
                    % CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                    VarianceZ2{ k } = VarianceZ2{ k } + CurrentVariance;
                end
                if Global
                    VarianceZ2Global{ k } = zeros( LengthCrit, LengthCrit );
                    for i = 1 : k
                        CurrentVariance = ( BCovXiBGlobal{ i }.' * A2PowersTrans{ k - i + 1 }( :, inv_order_var_VarIndices_ZeroLowerBounded ) ).' * A2PowersTrans{ k - i + 1 }( :, inv_order_var_VarIndices_ZeroLowerBounded ); 
                        % CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                        VarianceZ2Global{ k } = VarianceZ2Global{ k } + CurrentVariance;
                    end
                end
            end
        end
        
        ConditionalCovariance = zeros( T * ns, T * ns );
        StepIndices = 0:T:T*(ns-1);
        
        LengthConditionalCovarianceTemp = 0.5 * TM1 * ( TM1 + 1 );
        ConditionalCovarianceTemp = cell( LengthConditionalCovarianceTemp, 1 );
        
        if ParallelMode
            parfor i = 1 : LengthConditionalCovarianceTemp
                p = floor( 0.5 * ( 1 + sqrt( 8 * i - 7 ) ) );
                q = i - 0.5 * p * ( p - 1 );
                % p and q are indexes of the lower triangle of a matrix, p>=q
                ConditionalCovarianceTemp{i} = A2PowersProduct( p - q + 1, VarianceZ2{ q }, inv_order_var_VarIndices_ZeroLowerBounded ); %#ok<PFBNS> % * A2Powers{ p - q + 1 }' = eye
            end
        else
            for i = 1 : LengthConditionalCovarianceTemp
                p = floor( 0.5 * ( 1 + sqrt( 8 * i - 7 ) ) );
                q = i - 0.5 * p * ( p - 1 );
                % p and q are indexes of the lower triangle of a matrix, p>=q
                ConditionalCovarianceTemp{i} = A2PowersTrans{ p - q + 1 }( :, inv_order_var_VarIndices_ZeroLowerBounded ).' * VarianceZ2{ q }; % * A2Powers{ p - q + 1 }' = eye
            end
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
        
        RootConditionalCovariance = ObtainRootConditionalCovariance( ConditionalCovariance, dynareOBC.CubaturePruningCutOff, dynareOBC.MaxCubatureDimension );

        % [L,D] = ldl( ConditionalCovariance );
        % assert( isdiag( D ) );
        % diagD = diag( D );
        % RootD = sqrt( max( 0, diagD ) );
        % NRootD = sort( RootD );
        % RootD( RootD <= NRootD( end - dynareOBC_.MaxCubatureDimension ) ) = 0;
        % IDv = RootD > sqrt( eps );
        % RootConditionalCovariance = L( :, IDv ) * diag( RootD( IDv ) );
        
        if Global
            ConditionalVarianceGlobal = zeros( T * ns, 1 );
            
            for p = 1 : TM1
                ConditionalVarianceGlobal( 1 + p + StepIndices, 1 ) = VarianceZ2Global{ p };
            end

            GlobalVarianceShare = max( 0, min( 1, diag( ConditionalCovariance ) ./ max( eps, ConditionalVarianceGlobal ) ) );
            GlobalVarianceShare( 1 + StepIndices, 1 ) = 1;

            EndVarianceShare = max( GlobalVarianceShare( T + StepIndices, 1 ) );
            if EndVarianceShare > eps
                error( 'dynareOBC:InternalIRFPeriodsTooLow', 'Please increase TimeToReturnToSteadyState as it is currently too low for global simulation. Current end variance share: %.17g', EndVarianceShare );
            end
        else
            GlobalVarianceShare = [];
        end
    
    end
    
end

function Out = A2PowersProduct( j, X, Select )
    global dynareOBC_
    A2PowersTrans = dynareOBC_.A2PowersTrans;
    Out = A2PowersTrans{ j }( :, Select ).' * X;
end

function Out = A2PowersQuadraticForm( j, X, Select )
    global dynareOBC_
    A2PowersTrans = dynareOBC_.A2PowersTrans;
    Out = ( X.' * A2PowersTrans{ j } ).' * A2PowersTrans{ j }( :, Select );
end

function Out = A2PowersQuadraticFormGlobal( j, X, Select )
    global dynareOBC_
    A2PowersTrans = dynareOBC_.A2PowersTrans;
    Out = ( X.' * A2PowersTrans{ j }( :, Select ) ).' * A2PowersTrans{ j }( :, Select );
end
