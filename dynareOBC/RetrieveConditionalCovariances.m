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
        [ Vi, Vj, Vs ] = find( Sigma );
        [ Ci, Cj, Cs ] = find( dynareOBC.VarianceXiSkeleton );
            
        BCovXiB = cell( TM1, 1 );
        
        VarianceY1State = dynareOBC.VarianceY1State;
        
        Global = dynareOBC.Global;
        
        if Global
            VarianceY1StateGlobal = dynareOBC.VarianceY1StateGlobal;
            BCovXiBGlobal = cell( TM1, 1 );
        end
        
        B2 = dynareOBC.B2;
        
        PeriodsOfUncertainty = dynareOBC.PeriodsOfUncertainty;
        
        if PeriodsOfUncertainty > 3
            parfor i = 1 : PeriodsOfUncertainty
                iWeight = 0.5 * ( 1 + cos( pi * ( i - 1 ) / PeriodsOfUncertainty ) );

                CurrentSigma = iWeight * Sigma;
                % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
                % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
                % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
                [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), CurrentSigma );
                % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
                [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + VarianceY1State{i}, CurrentSigma );
                Tmpi = Tmpi + Offset3;
                Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                Cs2 = [ Vs * iWeight; Cs * iWeight * iWeight; Tmps; Tmps; Tmps2 ];

                BCovXiB{i} = sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );

                BCovXiB{i} = B2 * BCovXiB{i} * B2';
                BCovXiB{i}( abs(BCovXiB{i})<eps ) = 0;

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
                [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + VarianceY1State{i}, CurrentSigma );
                Tmpi = Tmpi + Offset3;
                Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                Cs2 = [ Vs * iWeight; Cs * iWeight * iWeight; Tmps; Tmps; Tmps2 ];

                BCovXiB{i} = sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );

                BCovXiB{i} = B2 * BCovXiB{i} * B2';
                BCovXiB{i}( abs(BCovXiB{i})<eps ) = 0;

            end
        end
        
        if Global
            parfor i = 1 : TM1
                % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
                % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
                % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
                [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), Sigma );
                % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
                [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + VarianceY1StateGlobal{i}, Sigma ); %#ok<PFBNS>
                Tmpi = Tmpi + Offset3;
                Ci2 = [ Vi; Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
                Cj2 = [ Vj; Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
                Cs2 = [ Vs; Cs; Tmps; Tmps; Tmps2 ];

                BCovXiBGlobal{i} = sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );

                BCovXiBGlobal{i} = B2 * BCovXiBGlobal{i} * B2';
                BCovXiBGlobal{i}( abs(BCovXiBGlobal{i})<eps ) = 0;

            end
        end
        
        A2Powers = dynareOBC.A2Powers;
        LengthZ2 = size( A2Powers{1}, 1 );
        
        VarianceZ2 = cell( TM1, 1 );
        if Global
            VarianceZ2Global = cell( TM1, 1 );
        end
        parfor k = 1 : TM1
            VarianceZ2{ k } = sparse( LengthZ2, LengthZ2 );
            for i = 1 : min( k, PeriodsOfUncertainty )
                CurrentVariance = A2Powers{ k - i + 1 } * BCovXiB{ i } * A2Powers{ k - i + 1 }'; %#ok<PFBNS>
                CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                VarianceZ2{ k } = VarianceZ2{ k } + CurrentVariance;
            end
            if Global
                VarianceZ2Global{ k } = sparse( LengthZ2, LengthZ2 );
                for i = 1 : k
                    CurrentVariance = A2Powers{ k - i + 1 } * BCovXiBGlobal{ i } * A2Powers{ k - i + 1 }'; %#ok<PFBNS>
                    CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                    VarianceZ2Global{ k } = VarianceZ2Global{ k } + CurrentVariance;
                end
            end
        end
        
        ConditionalCovariance = zeros( T * ns, T * ns );
        StepIndices = 0:T:T*(ns-1);
        
        inv_order_var = oo.dr.inv_order_var;
        VarIndices_ZeroLowerBounded = dynareOBC.VarIndices_ZeroLowerBounded;
        
        LengthConditionalCovarianceTemp = 0.5 * TM1 * ( TM1 + 1 );
        ConditionalCovarianceTemp = cell( LengthConditionalCovarianceTemp, 1 );
        
        parfor i = 1 : LengthConditionalCovarianceTemp
            p = floor( 0.5 * ( 1 + sqrt( 8 * i - 7 ) ) );
            q = i - 0.5 * p * ( p - 1 );
            % p and q are indexes of the lower triangle of a matrix, p>=q
            CurrentCov = A2Powers{ p - q + 1 } * VarianceZ2{ q }; %#ok<PFBNS> % * A2Powers{ p - q + 1 }' = eye
            ReducedCov = full( CurrentCov( inv_order_var( VarIndices_ZeroLowerBounded ), inv_order_var( VarIndices_ZeroLowerBounded ) ) ); %#ok<PFBNS>
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
        
        ConditionalCovariance = 0.5 * ( ConditionalCovariance + ConditionalCovariance' );
        
        RootConditionalCovariance = ObtainRootConditionalCovariance( ConditionalCovariance, dynareOBC );

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
                CurrentCov = VarianceZ2Global{ p };
                ReducedCov = full( CurrentCov( inv_order_var( VarIndices_ZeroLowerBounded ), inv_order_var( VarIndices_ZeroLowerBounded ) ) );
                ConditionalVarianceGlobal( 1 + p + StepIndices, 1 ) = ReducedCov;
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
