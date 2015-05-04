function RootConditionalCovariance = RetrieveConditionalCovariances( options, oo, dynareOBC, ReturnPathFirstOrder )
    if options.order == 1 || dynareOBC.FirstOrderConditionalCovariance
        RootConditionalCovariance = dynareOBC.RootConditionalCovariance;
    else
        T = dynareOBC.InternalIRFPeriods;
        Ts = dynareOBC.TimeToEscapeBounds;
        TsM2 = Ts - 2;
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
        [ Ci, Cj, Cs ] = find( dynareOBC.VarianceXiSkeleton );
            
        BCovXiB = cell( TsM2, 1 );
        
        VarianceY1State = dynareOBC.VarianceY1State;
        B2 = dynareOBC.B2;
        
        OpenPool;
        parfor i = 1 : TsM2
            % CornerCovXi = spkron( ReturnPathFirstOrder, Sigma );
            % BCovXiB{i}( Jdx3, Jdx1 ) = CornerCovXi;
            % BCovXiB{i}( Jdx1, Jdx3 ) = CornerCovXi';
            [ Tmpi, Tmpj, Tmps ] = spkron( ReturnPathFirstOrder( :, i ), Sigma );
            % BCovXiB{i}( Jdx3, Jdx3 ) = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + dynareOBC_.VarianceY1State{i}, Sigma );
            [ Tmpi2, Tmpj2, Tmps2 ] = spkron( ReturnPathFirstOrder * ReturnPathFirstOrder' + VarianceY1State{i}, Sigma ); %#ok<PFBNS>
            Tmpi = Tmpi + Offset3;
            Ci2 = [ Ci; Tmpi; Tmpj; Tmpi2 + Offset3 ];
            Cj2 = [ Cj; Tmpj; Tmpi; Tmpj2 + Offset3 ];
            Cs2 = [ Cs; Tmps; Tmps; Tmps2 ];
            
            BCovXiB{i} = sparse( Ci2, Cj2, Cs2, LengthXi, LengthXi );
            
            BCovXiB{i} = B2 * BCovXiB{i} * B2';
            BCovXiB{i}( abs(BCovXiB{i})<eps ) = 0;
            
        end
        
        A2Powers = dynareOBC.A2Powers;
        LengthZ2 = size( A2Powers{1}, 1 );
        
        VarianceZ2 = cell( TsM2, 1 );
        parfor k = 1 : TsM2
            VarianceZ2{ k } = sparse( LengthZ2, LengthZ2 );
            for i = 1 : k
                CurrentVariance = A2Powers{ k - i + 1 } * BCovXiB{ i } * A2Powers{ k - i + 1 }'; %#ok<PFBNS>
                CurrentVariance( abs(CurrentVariance)<eps ) = 0;
                VarianceZ2{ k } = VarianceZ2{ k } + CurrentVariance;
            end
        end
        
        ConditionalCovariance = zeros( T * ns, T * ns );
        StepIndices = 0:T:T*(ns-1);
        
        inv_order_var = oo.dr.inv_order_var;
        VarIndices_ZeroLowerBounded = dynareOBC.VarIndices_ZeroLowerBounded;
        
        LengthConditionalCovarianceTemp = 0.5 * TsM2 * ( TsM2 + 1 );
        ConditionalCovarianceTemp = cell( LengthConditionalCovarianceTemp, 1 );
        
        parfor i = 1 : LengthConditionalCovarianceTemp
            p = floor( 0.5 * ( 1 + sqrt( 8 * i - 7 ) ) );
            q = i - 0.5 * p * ( p - 1 );
            pWeight = 0.5 * ( 1 + cos( pi * ( p - 1 ) / TsM2 ) );
            qWeight = 0.5 * ( 1 + cos( pi * ( q - 1 ) / TsM2 ) );
            CurrentCov = A2Powers{ p - q + 1 } * VarianceZ2{ q }; %#ok<PFBNS>
            ReducedCov = full( CurrentCov( inv_order_var( VarIndices_ZeroLowerBounded ), inv_order_var( VarIndices_ZeroLowerBounded ) ) ); %#ok<PFBNS>
            ConditionalCovarianceTemp{i} = ( pWeight * qWeight * 0.5 ) * ( ReducedCov + ReducedCov' );
        end
        for p = 1 : TsM2
            for q = 1 : p
                i = 0.5 * p * ( p - 1 ) + q;
                ConditionalCovariance( 1 + p + StepIndices, 1 + q + StepIndices ) = ConditionalCovarianceTemp{i};
            end
            for q = (p+1) : TsM2
                i = 0.5 * q * ( q - 1 ) + p;
                ConditionalCovariance( 1 + p + StepIndices, 1 + q + StepIndices ) = ConditionalCovarianceTemp{i}';
            end
        end
        
        [U,D] = schur( ConditionalCovariance, 'complex' );
        assert( isreal( U ) );
        diagD = diag( D );
        assert( isreal( diagD ) );
        max_diagD = max( diagD );
        diagD( diagD < 0.01 * max_diagD ) = 0;
        diagD( 1 : end - dynareOBC.MaxCubatureDimension ) = 0;
        RootD = sqrt( diagD );
        IDv = RootD > sqrt( eps );
        RootConditionalCovariance = U( :, IDv ) * diag( RootD( IDv ) );

        % [L,D] = ldl( ConditionalCovariance );
        % assert( isdiag( D ) );
        % diagD = diag( D );
        % RootD = sqrt( max( 0, diagD ) );
        % NRootD = sort( RootD );
        % RootD( RootD <= NRootD( end - dynareOBC_.MaxCubatureDimension ) ) = 0;
        % IDv = RootD > sqrt( eps );
        % RootConditionalCovariance = L( :, IDv ) * diag( RootD( IDv ) );
    
    end
end
