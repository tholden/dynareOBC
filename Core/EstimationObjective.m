function [ LogLikelihood, EstimationPersistentState, LogObservationLikelihoods ] = EstimationObjective( p, EstimationPersistentState, Smoothing )

    global M_ options_ oo_ dynareOBC_
    
    M_ = EstimationPersistentState.M;
    options_ = EstimationPersistentState.options;
    oo_ = EstimationPersistentState.oo;
    dynareOBC_ = EstimationPersistentState.dynareOBC;
    
    [ T, N ] = size( dynareOBC_.EstimationData );
    if nargout > 2
        LogObservationLikelihoods = NaN( T, 1 );
    end

    M_.params( dynareOBC_.EstimationParameterSelect ) = p( 1 : length( dynareOBC_.EstimationParameterSelect ) );
    diagLambda = exp( p( length( dynareOBC_.EstimationParameterSelect ) + ( 1 : N ) ) );
    
    options_.qz_criterium = 1 - 1e-6;
    try
        [ Info, M_, options_, oo_, dynareOBC_ ] = ModelSolution( false, M_, options_, oo_, dynareOBC_, EstimationPersistentState.InitialRun );
    catch Error
        rethrow( Error );
    end
    if Info ~= 0
        error( 'dynareOBC:EstimationBK', 'Apparent BK condition violation.' );
    end

    NEndo = M_.endo_nbr;
    NExo = dynareOBC_.OriginalNumVarExo;
    NEndoMult = 2 .^ ( dynareOBC_.Order - 1 );
    
    SelectStateVariables = ismember( ( 1:NEndo )', oo_.dr.order_var( dynareOBC_.SelectState ) );
    SelectAugStateVariables = find( repmat( SelectStateVariables, NEndoMult, 1 ) );
   
    StdDevThreshold = dynareOBC_.StdDevThreshold;
    
    RootExoVar = ObtainEstimateRootCovariance( M_.Sigma_e( 1:NExo, 1:NExo ), StdDevThreshold );

    LagIndices = find( dynareOBC_.OriginalLeadLagIncidence( 1, : ) > 0 );
    CurrentIndices = find( dynareOBC_.OriginalLeadLagIncidence( 2, : ) > 0 );
    if size( dynareOBC_.OriginalLeadLagIncidence, 1 ) > 2
        LeadIndices = dynareOBC_.OriginalLeadLagIncidence( 3, : ) > 0;
    else
        LeadIndices = [];
    end
    FutureValues = nan( sum( LeadIndices ), 1 );
    
    OldRNGState = rng( 'default' );
    ShockSequence = RootExoVar * randn( size( RootExoVar, 2 ), dynareOBC_.StationaryDistPeriods + dynareOBC_.StationaryDistDrop );
    rng( OldRNGState );
    
    try
        StatDistSimulation = SimulateModel( ShockSequence, false, [], true, true );
    catch Error
        rethrow( Error );
    end

    if dynareOBC_.Order == 1
        StatDistPoints = StatDistSimulation.first + StatDistSimulation.bound_offset;
    elseif dynareOBC_.Order == 2
        StatDistPoints = [ StatDistSimulation.first; StatDistSimulation.second + StatDistSimulation.bound_offset ];
    else
        StatDistPoints = [ StatDistSimulation.first; StatDistSimulation.second; StatDistSimulation.first_sigma_2; StatDistSimulation.third + StatDistSimulation.bound_offset ];
    end
    
    StatDistPoints = StatDistPoints( :, ( dynareOBC_.StationaryDistDrop + 1 ):end );
    
    if any( ~isfinite( StatDistPoints ) )
        error( 'dynareOBC:EstimationNonFiniteSimultation', 'Non-finite values were encountered during simulation.' );
    end
    
    MedianStatDist = zeros( size( StatDistPoints, 1 ), 1 );
    MeanStatDist = mean( StatDistPoints, 2 );
    DeMeanedStatDistPoints = bsxfun( @minus, StatDistPoints, MeanStatDist );
    [ ~, cholVarianceStatDist ] = NearestSPD( cov( StatDistPoints' ) );

    MeanStatDistMMedianStatDist = MeanStatDist - MedianStatDist;
    cholVarianceStatDist_MeanStatDistMMedianStatDist = cholVarianceStatDist * MeanStatDistMMedianStatDist;
    cholVarianceStatDist_MeanStatDistMMedianStatDist2 = cholVarianceStatDist_MeanStatDistMMedianStatDist' * cholVarianceStatDist_MeanStatDistMMedianStatDist;
    
    if dynareOBC_.NoTLikelihood
        nuoo = Inf;
        assert( length( p ) == length( dynareOBC_.EstimationParameterSelect ) + N );
    elseif dynareOBC_.DynamicNu
        nuoo = [];
        assert( length( p ) == length( dynareOBC_.EstimationParameterSelect ) + N );
    else
        nuoo = exp( p( end ) );
        assert( length( p ) == length( dynareOBC_.EstimationParameterSelect ) + N + 1 );
    end
    
    nuno = nuoo;
    
    if cholVarianceStatDist_MeanStatDistMMedianStatDist2 > eps && ~dynareOBC_.NoSkewLikelihood
        ZcheckStatDist = ( MeanStatDistMMedianStatDist' * DeMeanedStatDistPoints ) / sqrt( cholVarianceStatDist_MeanStatDistMMedianStatDist2 );

        sZ3 = skewness( ZcheckStatDist, 0 );
        sZ4 = max( 3, kurtosis( ZcheckStatDist, 0 ) );

        if isempty( nuoo )
            tauoo_nuoo = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), in( 2 ), MeanStatDist, MedianStatDist, cholVarianceStatDist, sZ3, sZ4 ), [ 2; 10 ], [ -Inf; 4 + eps( 4 ) ], [], optimoptions( @lsqnonlin, 'display', 'off', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );
            tauoo = tauoo_nuoo( 1 );
            nuoo = tauoo_nuoo( 2 );
        else
            tauoo = lsqnonlin( @( in ) CalibrateMomentsEST( in( 1 ), nuoo, MeanStatDist, MedianStatDist, cholVarianceStatDist, sZ3, [] ), 2, [], [], optimoptions( @lsqnonlin, 'display', 'off', 'MaxFunctionEvaluations', Inf, 'MaxIterations', Inf ) );
        end
    else
        tauoo = Inf;
        
        if isempty( nuoo )
            kurtDir = max( 0, kurtosis( DeMeanedStatDistPoints, 0, 2 ) - 3 );

            if kurtDir' * kurtDir < eps
                kurtDir = kurtosis( DeMeanedStatDistPoints, 0, 2 );
            end

            kurtDir = kurtDir / norm( kurtDir );

            ZcheckStatDist = kurtDir' * DeMeanedStatDistPoints;

            sZ4 = max( 3, kurtosis( ZcheckStatDist, 0 ) );
            nuoo = 4 + 6 / ( sZ4 - 3 );
        end
    end
    
    [ ~, xoo, deltasoo, cholPsoo ] = CalibrateMomentsEST( tauoo, nuoo, MeanStatDist, MedianStatDist, cholVarianceStatDist, [], [] );
    
    Psoo = cholPsoo * cholPsoo';
    Ssoo = ObtainEstimateRootCovariance( Psoo, StdDevThreshold );

    MParams = M_.params;
    OoDrYs = oo_.dr.ys( 1:dynareOBC_.OriginalNumVar );
    
    PriorFunc = str2func( dynareOBC_.Prior );
    PriorValue = PriorFunc( p );
    ScaledPriorValue = PriorValue / T;
    
    if Smoothing
        wnn_ = cell( T, 1 );
        Pnn_ = cell( T, 1 );
        deltann_ = cell( T, 1 );
        taunn_ = cell( T, 1 );
        nunn_ = cell( T, 1 );
        xno_ = cell( T, 1 );
        Psno_ = cell( T, 1 );
        deltasno_ = cell( T, 1 );
        tauno_ = cell( T, 1 );
        nuno_ = cell( T, 1 );
    end
    
    LogLikelihood = 0;
% function [ LogObservationLikelihood, xnn, Ssnn, deltasnn, taunn, nunn, wnn, Pnn, deltann, xno, Psno, deltasno, tauno, nuno ] = ...
%     KalmanStep( m, xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables )

    for t = 1:T
        if Smoothing
            if dynareOBC_.DynamicNu
                nuno = [];
            end
            [ LogObservationLikelihood, xnn, Ssnn, deltasnn, taunn, nunn, wnn, Pnn, deltann, xno, Psno, deltasno, tauno, nuno ] = ...
                KalmanStep( dynareOBC_.EstimationData( t, : ), xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC_, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables );
            wnn_{ t } = wnn;
            Pnn_{ t } = Pnn;
            deltann_{ t } = deltann;
            taunn_{ t } = taunn;
            nunn_{ t } = nunn;
            xno_{ t } = xno;
            Psno_{ t } = Psno;
            deltasno_{ t } = deltasno;
            tauno_{ t } = tauno;
            nuno_{ t } = nuno;
        else
            [ LogObservationLikelihood, xnn, Ssnn, deltasnn, taunn, nunn ] = ...
                KalmanStep( dynareOBC_.EstimationData( t, : ), xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC_, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables );
            if isempty( xnn )
                error( 'dynareOBC:EstimationEmptyKalmanReturn', 'KalmanStep returned an empty xnn.' );
            end
        end
        
        LogObservationLikelihood = LogObservationLikelihood + ScaledPriorValue;
        
        if nargout > 1
            LogObservationLikelihoods( t ) = LogObservationLikelihood;
        end
        
        xoo = xnn;
        Ssoo = Ssnn;
        deltasoo = deltasnn;
        tauoo = taunn;
        nuoo = nunn;
        
        LogLikelihood = LogLikelihood + LogObservationLikelihood;
    end
    
    if Smoothing
%         SmoothedWs = cell( T, 1 );
%         RootSmoothedWVariances = cell( T, 1 );
%         SmoothedWs{ T } = W;
%         RootSmoothedWVariances{ T } = RootWVariance;
%         
%         for t = ( T - 1 ):-1:1
%             W = FilteredWs{ t } + SmootherGain * ( xnn - PredictedX );
%             SmoothedWs{ t } = W;
%             VarianceTerm1 = RootFilteredWVariances{ t };
%             VarianceTerm2 = SmootherGain * RootPredictedXVariance;
%             VarianceTerm3 = SmootherGain * Ssnn;
%             WVariance = VarianceTerm1 * VarianceTerm1' - VarianceTerm2 * VarianceTerm2' + VarianceTerm3 * VarianceTerm3';
%             RootWVariance = ObtainEstimateRootCovariance( WVariance, 0 );
%             RootSmoothedWVariances{ t } = RootWVariance;
%             Ssnn = RootWVariance( SelectAugStateVariables, : );
%             SmootherGain = SmootherGains{ t };
%             PredictedX = PredictedXs{ t };
%             RootPredictedXVariance = RootPredictedXVariances{ t };
%         end
% 
%         dynareOBC.FilteredWs = FilteredWs;
%         dynareOBC.RootFilteredWVariances = RootFilteredWVariances;
%         dynareOBC.SmoothedWs = SmoothedWs;
%         RootSmoothedWVariances.RootSmoothedWVariances = RootSmoothedWVariances;

    end
    
    EstimationPersistentState.M = M_;
    EstimationPersistentState.options = options_;
    EstimationPersistentState.oo = oo_;
    EstimationPersistentState.dynareOBC = dynareOBC_;
    
end
