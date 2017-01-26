function [ LogObservationLikelihood, xnn, Ssnn, deltasnn, taunn, nunn, wnn, Pnn, deltann, xno, Psno, deltasno, tauno, nuno ] = ...
    KalmanStep( m, xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables )

%     LogObservationLikelihood = NaN;
%     xnn = [];
%     Ssnn = [];
%     deltasnn = [];
%     taunn = [];
%     nunn = [];
%     wnn = [];
%     Pnn = [];
%     deltann = [];
%     xno = [];
%     Psno = [];
%     deltasno = [];
%     tauno = [];
    
    NAugState1 = size( Ssoo, 1 );
    NAugState2 = size( Ssoo, 2 );
    NExo1 = size( RootExoVar, 1 );
    NExo2 = size( RootExoVar, 2 );
    
    IntDim = NAugState2 + NExo2 + 2;
    
    tcdf_tauoo_nuoo = StudentTCDF( tauoo, nuoo );
    
    if tcdf_tauoo_nuoo == 0
        IntDim = IntDim - 1;
        tmp_deltasoo = Ssoo \ deltasoo;
        if all( abs( ( Ssoo * tmp_deltasoo - deltasoo ) / max( eps, norm( deltasoo ) ) ) < sqrt( eps ) )
            % Ssoo * Ssoo' + deltasoo * deltasoo' = Ssoo * Ssoo' + Ssoo * tmp_deltasoo * tmp_deltasoo' * Ssoo' = Ssoo * ( I' * I + tmp_deltasoo * tmp_deltasoo' ) * Ssoo'
            Ssoo = Ssoo * cholupdate( eye( NAugState2 ), tmp_deltasoo );
        else
            Ssoo = [ Ssoo, deltasoo ];
        end
        deltasoo = zeros( size( deltasoo ) );
    end
    
    if isfinite( nuoo )
        [ CubatureWeights, CubaturePoints, NCubaturePoints ] = GetCubaturePoints( IntDim, dynareOBC.FilterCubatureDegree );
        PhiN10 = normcdf( CubaturePoints( end, : ) );
        if tcdf_tauoo_nuoo > 0
            N11Scaler = sqrt( 0.5 * ( nuoo + 1 ) ./ gammaincinv( PhiN10, 0.5 * ( nuoo + 1 ), 'upper' ) );
        else
            N11Scaler = sqrt( 0.5 * nuoo ./ gammaincinv( PhiN10, 0.5 * nuoo, 'upper' ) );
        end
        N11Scaler( ~isfinite( N11Scaler ) ) = 1;
    end
    
    if ~isfinite( nuoo ) || all( abs( N11Scaler - 1 ) <= sqrt( eps ) )
        IntDim = IntDim - 1;
        [ CubatureWeights, CubaturePoints, NCubaturePoints ] = GetCubaturePoints( IntDim, dynareOBC.FilterCubatureDegree );
        N11Scaler = ones( 1, NCubaturePoints );
    else
        CubaturePoints( end, : ) = [];
    end

    if tcdf_tauoo_nuoo > 0
        PhiN0 = normcdf( CubaturePoints( end, : ) );
        CubaturePoints( end, : ) = [];
        FInvEST = tinv( 1 - ( 1 - PhiN0 ) * tcdf_tauoo_nuoo, nuoo );
        N11Scaler = N11Scaler .* sqrt( ( nuoo + FInvEST .^ 2 ) / ( 1 + nuoo ) );
        N11Scaler( ~isfinite( N11Scaler ) ) = 1;
    else
        FInvEST = zeros( 1, NCubaturePoints );
    end

    StateExoPoints = bsxfun( @plus, [ Ssoo * bsxfun( @times, CubaturePoints( 1:NAugState2,: ), N11Scaler ) + bsxfun( @times, deltasoo, FInvEST ); RootExoVar * CubaturePoints( (NAugState2+1):end,: ) ], [ xoo; zeros( NExo1, 1 ) ] );
    
    Constant = dynareOBC.Constant;
    NEndo = length( Constant );
    NEndoMult = 2 .^ ( dynareOBC.Order - 1 );
    
    NAugEndo = NEndo * NEndoMult;

    StatePoints = StateExoPoints( 1:NAugState1, : );
    ExoPoints = StateExoPoints( (NAugState1+1):(NAugState1+NExo1), : );

    OldAugEndoPoints = zeros( NAugEndo, NCubaturePoints );
    OldAugEndoPoints( SelectAugStateVariables, : ) = StatePoints;
    
    Observed = find( isfinite( m ) );
    m = m( Observed )';
    nm = length( Observed );
       
    NewAugEndoPoints = zeros( NAugEndo, NCubaturePoints );
    
    for i = 1 : NCubaturePoints
        InitialFullState = GetFullStateStruct( OldAugEndoPoints( :, i ), dynareOBC.Order, Constant );
        try
            Simulation = SimulateModel( ExoPoints( :, i ), false, InitialFullState, true, true );
        catch Error
            rethrow( Error );
        end
        
        if dynareOBC.Order == 1
            NewAugEndoPoints( :, i ) = Simulation.first + Simulation.bound_offset;
        elseif dynareOBC.Order == 2
            NewAugEndoPoints( :, i ) = [ Simulation.first; Simulation.second + Simulation.bound_offset ];
        else
            NewAugEndoPoints( :, i ) = [ Simulation.first; Simulation.second; Simulation.first_sigma_2; Simulation.third + Simulation.bound_offset ];
        end
        if any( ~isfinite( NewAugEndoPoints( :, i ) ) )
            error( 'dynareOBC:EstimationNonFiniteSimultation', 'Non-finite values were encountered during simulation.' );
        end
    end
    
    if nm > 0
        LagValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( OldAugEndoPoints, NEndo, NEndoMult, NCubaturePoints ), 2 ), NEndo, NCubaturePoints ), Constant );
        LagValuesWithBoundsLagIndices = LagValuesWithBoundsBig( LagIndices, : );
        
        CurrentValuesWithBoundsBig = bsxfun( @plus, reshape( sum( reshape( NewAugEndoPoints, NEndo, NEndoMult, NCubaturePoints ), 2 ), NEndo, NCubaturePoints ), Constant );
        CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBoundsBig( CurrentIndices, : );
        
        MLVValues = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; repmat( FutureValues, 1, NCubaturePoints ) ], ExoPoints, MParams, OoDrYs );
        NewMeasurementPoints = MLVValues( Observed, : );
        if any( any( ~isfinite( NewMeasurementPoints ) ) )
            error( 'dynareOBC:EstimationNonFiniteMeasurements', 'Non-finite values were encountered during calculation of observation equations.' );
        end
    else
        NewMeasurementPoints = zeros( 0, NCubaturePoints );
    end

    StdDevThreshold = dynareOBC.StdDevThreshold;

    wm = [ NewAugEndoPoints; ExoPoints; zeros( nm, NCubaturePoints ); NewMeasurementPoints ];
    
    nwm = size( wm, 1 );
    
    Median_wm = wm( :, 1 );
    
    Mean_wm = sum( bsxfun( @times, wm, CubatureWeights ), 2 );
    ano = bsxfun( @minus, wm, Mean_wm );
    Weighted_ano = bsxfun( @times, ano, CubatureWeights );
    
    Variance_wm = zeros( nwm, nwm );
    ZetaBlock = ( nwm - 2 * nm + 1 ) : nwm;
    Lambda = diag( diagLambda( Observed ) );
    Variance_wm( ZetaBlock, ZetaBlock ) = [ Lambda, Lambda; Lambda, Lambda ];
    
    Variance_wm = Variance_wm + NearestSPD( ano * Weighted_ano' );
    Variance_wm = 0.5 * ( Variance_wm + Variance_wm' );
    cholVariance_wm = chol( Variance_wm );
    
    Mean_wmMMedian_wm = Mean_wm - Median_wm;
    cholVariance_wm_Mean_wmMMedian_wm = cholVariance_wm * Mean_wmMMedian_wm;
    cholVariance_wm_Mean_wmMMedian_wm2 = cholVariance_wm_Mean_wmMMedian_wm' * cholVariance_wm_Mean_wmMMedian_wm;
    
    if cholVariance_wm_Mean_wmMMedian_wm2 > eps && ~dynareOBC.NoSkewLikelihood
        Zcheck_wm = ( Mean_wmMMedian_wm' * ano ) / sqrt( cholVariance_wm_Mean_wmMMedian_wm2 );

        meanZcheck_wm = Zcheck_wm * CubatureWeights';
        Zcheck_wm = Zcheck_wm - meanZcheck_wm;
        meanZcheck_wm2 = Zcheck_wm.^2 * CubatureWeights';
        Zcheck_wm = Zcheck_wm / sqrt( meanZcheck_wm2 );

        sZ3 = Zcheck_wm.^3 * CubatureWeights';
        sZ4 = max( 3, Zcheck_wm.^4 * CubatureWeights' );

        if isempty( nuno )
            tauno_nuno = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), in( 2 ), Mean_wm, Median_wm, cholVariance_wm, sZ3, sZ4 ), [ max( -1e300, tauoo ); min( 1e300, nuoo ) ], [ -Inf; 4 + eps( 4 ) ], [], optimoptions( @lsqnonlin, 'display', 'off', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );
            tauno = tauno_nuno( 1 );
            nuno = tauno_nuno( 2 );
        else
            tauno = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), nuno, Mean_wm, Median_wm, cholVariance_wm, sZ3, [] ), max( -1e300, tauoo ), [], [], optimoptions( @lsqnonlin, 'display', 'off', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );
        end
    else
        tauno = -Inf;
        
        if isempty( nuno )
            Zcheck_wm = cholVariance_wm * ano;

            meanZcheck_wm = Zcheck_wm * CubatureWeights';
            Zcheck_wm = bsxfun( @minus, Zcheck_wm, meanZcheck_wm );
            meanZcheck_wm2 = Zcheck_wm.^2 * CubatureWeights';
            Zcheck_wm = bsxfun( @times, Zcheck_wm, 1 ./ sqrt( meanZcheck_wm2 ) );

            kurtDir = max( 0, Zcheck_wm.^4 * CubatureWeights' - 3 );

            if kurtDir' * kurtDir < eps
                kurtDir = Zcheck_wm.^4 * CubatureWeights';
            end

            kurtDir = kurtDir / norm( kurtDir );

            Zcheck_wm = kurtDir' * Zcheck_wm;

            meanZcheck_wm = Zcheck_wm * CubatureWeights';
            Zcheck_wm = Zcheck_wm - meanZcheck_wm;
            meanZcheck_wm2 = Zcheck_wm.^2 * CubatureWeights';
            Zcheck_wm = Zcheck_wm / sqrt( meanZcheck_wm2 );

            sZ4 = max( 3, Zcheck_wm.^4 * CubatureWeights' );
            nuno = 4 + 6 / ( sZ4 - 3 );
        end
    end
    
    [ ~, wmno, deltaetano, cholPRRQno ] = CalibrateMomentsEST( tauno, nuno, Mean_wm, Median_wm, cholVariance_wm, [], [] );

    assert( NAugEndo + NExo1 + nm + nm == nwm );
    
    wBlock = 1 : ( NAugEndo + NExo1 + nm );
    mBlock = ( nwm - nm + 1 ) : nwm;
    
    wno = wmno( wBlock );
    mno = wmno( mBlock );
    
    deltano = deltaetano( wBlock );
    etano = deltaetano( mBlock );
    
    cholPno = cholPRRQno( wBlock, wBlock );
    Pno = cholPno' * cholPno;
    tmpRno = cholPRRQno( wBlock, mBlock );
    Rno = cholPno' * tmpRno;
    tmpQno = cholPRRQno( mBlock, mBlock );
    Qno = tmpRno' * tmpRno + tmpQno' * tmpQno;
    
    xno = wno( 1:NAugState1 );
    deltasno = deltano( 1:NAugState1 );
    Psno = Pno( 1:NAugState1, 1:NAugState1 );
    
    if nm > 0
        cholPnoCheck = cholupdate( cholPno, deltano );
        RnoCheck = Rno + deltano * etano';
        [ ~, cholQnoCheck ] = NearestSPD( Qno + etano * etano' );

        RCheck_IcholQnoCheck = RnoCheck / cholQnoCheck;
        TIcholQnoCheck_mInnovation = cholQnoCheck' \ ( m - mno );
        TIcholQnoCheck_eta = cholQnoCheck' \ etano;
        
        PTildeno = cholPnoCheck * cholPnoCheck' - RCheck_IcholQnoCheck * RCheck_IcholQnoCheck';
        deltaTildeno = deltano - RCheck_IcholQnoCheck * TIcholQnoCheck_eta;
        
        wnn = RCheck_IcholQnoCheck * TIcholQnoCheck_mInnovation;
        scalePnn = ( nuno + TIcholQnoCheck_mInnovation' * TIcholQnoCheck_mInnovation ) / ( nuno + nm );
        scaledeltann = 1 / ( 1 - TIcholQnoCheck_eta' * TIcholQnoCheck_eta );
        Pnn = scalePnn * NearestSPD( PTildeno - ( deltaTildeno * deltaTildeno' ) * scaledeltann );
        deltann = sqrt( scalePnn * scaledeltann ) * deltaTildeno;
        taunn = sqrt( scaledeltann / scalePnn ) * ( TIcholQnoCheck_eta' * TIcholQnoCheck_mInnovation + tauno );
        nunn = nuno + nm;
        
        [ ~, logMVTStudentTPDF_TIcholQnoCheck_mInnovation_nuno ] = MVTStudentTPDF( TIcholQnoCheck_mInnovation, nuno );
        [ ~, log_tcdf_tauno_nuno ] = StudentTCDF( tauno, nuno );
        [ ~, log_tcdf_taunn_nunn ] = StudentTCDF( taunn, nunn );
        
        LogObservationLikelihood = -sum( log( abs( diag( cholQnoCheck ) ) ) ) + logMVTStudentTPDF_TIcholQnoCheck_mInnovation_nuno;

        if isfinite( log_tcdf_tauno_nuno ) || isfinite( log_tcdf_taunn_nunn )
            LogObservationLikelihood = LogObservationLikelihood - log_tcdf_tauno_nuno + log_tcdf_taunn_nunn;
        end
    else
        wnn = wno;
        Pnn = Pno;
        deltann = deltano;
        taunn = tauno;
        nunn = nuno;
        
        LogObservationLikelihood = 0;
    end
    
    xnn = wnn( 1:NAugState1 );
    deltasnn = deltann( 1:NAugState1 );
    Psnn = Pnn( 1:NAugState1, 1:NAugState1 );
    
    Ssnn = ObtainEstimateRootCovariance( Psnn, StdDevThreshold );
       
end

function [ CubatureWeights, CubaturePoints, NCubaturePoints ] = GetCubaturePoints( IntDim, FilterCubatureDegree )
    if FilterCubatureDegree > 0
        CubatureOrder = ceil( 0.5 * ( FilterCubatureDegree - 1 ) );
        [ CubatureWeights, CubaturePoints, NCubaturePoints ] = fwtpts( IntDim, CubatureOrder );
    else
        NCubaturePoints = 2 * IntDim + 1;
        wTemp = 0.5 * sqrt( 2 * NCubaturePoints );
        CubaturePoints = [ zeros( IntDim, 1 ), wTemp * eye( IntDim ), -wTemp * eye( IntDim ) ];
        CubatureWeights = 1 / NCubaturePoints;
    end
end

function FullStateStruct = GetFullStateStruct( CurrentState, Order, Constant )
    NEndo = length( Constant );
    FullStateStruct = struct;
    FullStateStruct.first = CurrentState( 1:NEndo );
    total = FullStateStruct.first + Constant;
    if Order >= 2
        FullStateStruct.second = CurrentState( (NEndo+1):(2*NEndo) );
        total = total + FullStateStruct.second;
        if Order >= 3
            FullStateStruct.first_sigma_2 = CurrentState( (2*NEndo+1):(3*NEndo) );
            FullStateStruct.third = CurrentState( (3*NEndo+1):(4*NEndo) );
            total = total + FullStateStruct.first_sigma_2 + FullStateStruct.third;
        end
    end
    FullStateStruct.bound_offset = zeros( NEndo, 1 );
    FullStateStruct.total = total;
    FullStateStruct.total_with_bounds = FullStateStruct.total;
end
