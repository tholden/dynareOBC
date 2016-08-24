function [ TwoNLogLikelihood, TwoNLogObservationLikelihoods, M, options, oo, dynareOBC ] = EstimationObjective( p, M, options, oo, dynareOBC, InitialRun, Smoothing )

    TwoNLogLikelihood = Inf;
    [ T, N ] = size( dynareOBC.EstimationData );
    if nargout > 1
        TwoNLogObservationLikelihoods = NaN( T, 1 );
    end

    M.params( dynareOBC.EstimationParameterSelect ) = p( 1 : length( dynareOBC.EstimationParameterSelect ) );
    MEVar = p( ( length( dynareOBC.EstimationParameterSelect ) + 1 ):end );
    
    options.qz_criterium = 1 - 1e-6;
    try
        [ Info, M, options, oo, dynareOBC ] = ModelSolution( false, M, options, oo, dynareOBC, InitialRun );
    catch
        return
    end
    if Info ~= 0
        return
    end

    global M_ options_ oo_ dynareOBC_
    M_ = M;
    options_ = options;
    oo_ = oo;
    dynareOBC_ = dynareOBC;
    
    NEndo = M.endo_nbr;
    NExo = dynareOBC.OriginalNumVarExo;
    NEndoMult = 2 .^ ( dynareOBC.Order - 1 );
    
    SelectStateVariables = ismember( ( 1:NEndo )', oo.dr.order_var( dynareOBC.SelectState ) );
    SelectAugStateVariables = find( repmat( SelectStateVariables, NEndoMult, 1 ) );
    NState = sum( SelectStateVariables );
    NAugState = NEndoMult * NState;
   
    StdDevThreshold = dynareOBC.StdDevThreshold;
    
    RootQ = ObtainEstimateRootCovariance( M.Sigma_e( 1:NExo, 1:NExo ), StdDevThreshold );

    LagIndices = find( dynareOBC.OriginalLeadLagIncidence( 1, : ) > 0 );
    CurrentIndices = find( dynareOBC.OriginalLeadLagIncidence( 2, : ) > 0 );
    if size( dynareOBC.OriginalLeadLagIncidence, 1 ) > 2
        LeadIndices = dynareOBC.OriginalLeadLagIncidence( 3, : ) > 0;
    else
        LeadIndices = [];
    end
    FutureValues = nan( sum( LeadIndices ), 1 );
    
    % get initial mean and covariance
    OldX = full( dynareOBC.Mean_z );
    OldX = OldX( dynareOBC.CoreSelectInAugmented );
    OldX = OldX( SelectAugStateVariables );
    dr = oo.dr;

    if dynareOBC.Order == 1
        TempCovariance = full( dynareOBC.Var_z1 );
        TempCovarianceSelect = dr.inv_order_var( SelectStateVariables );
    else
        TempCovariance = full( dynareOBC.Var_z2 );
        TempCovarianceSelect = [ dr.inv_order_var( SelectStateVariables ); NEndo + dr.inv_order_var( SelectStateVariables ) ];
    end

    TempOldRootCovariance = ObtainEstimateRootCovariance( TempCovariance( TempCovarianceSelect, TempCovarianceSelect ), StdDevThreshold );

    RootOldXVariance = zeros( NAugState, size( TempOldRootCovariance, 2 ) );
    RootOldXVariance( 1:size( TempOldRootCovariance, 1 ), : ) = TempOldRootCovariance; % handles 3rd order
    % end getting initial mean and covariance
    
    OldXVariance = RootOldXVariance * RootOldXVariance';
    CompOld = [ OldXVariance(:); OldX ];
    ErrorOld = Inf;
    StepSize = 1;
    
    MParams = M.params;
    OoDrYs = oo.dr.ys( 1:dynareOBC.OriginalNumVar );
    
    tCutOff = 100;
    
    StartTime = tic;
    
    for t = 1:dynareOBC.StationaryDistMaxIterations
        try
            [ ~, X, RootXVariance, InvRootXVariance, ~, RootWVariance ] = KalmanStep( nan( 1, N ), OldX, RootOldXVariance, [], [], RootQ, MEVar, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables, false );
        catch
            X = [];
        end
        if ~Smoothing && ( isempty( X ) || toc( StartTime ) > dynareOBC.TimeOutLikelihoodEvaluation )
            return;
        end
        
        XVariance = RootXVariance * RootXVariance';
        
        X = OldX + StepSize * ( X - OldX );
        XVariance = OldXVariance + StepSize * ( XVariance - OldXVariance );

        CompNew = [ XVariance(:); X ];
        
        OldX = X;
        RootOldXVariance = ObtainEstimateRootCovariance( XVariance, StdDevThreshold );
        
        Error = max( abs( CompNew - CompOld ) );
        ErrorScale = sqrt( eps( max( abs( [ CompNew; CompOld ] ) ) ) );
        if Error < ErrorScale
            break;
        end
        if t > tCutOff
            if Error < ErrorOld
                StepSize = min( 1, StepSize * 1.01 );
            else
                StepSize = 0.5 * StepSize;
                tCutOff = t + 100;
            end
        end
        
        CompOld = CompNew;
        ErrorOld = Error;
    end

    PriorFunc = str2func( dynareOBC.Prior );
    PriorValue = PriorFunc( p );
    ScaledPriorValue = -2 * PriorValue / T;
    
    if Smoothing
        FilteredWs = cell( T, 1 );
        RootFilteredWVariances = cell( T, 1 );
        SmootherGains = cell( T, 1 );
        PredictedXs = cell( T, 1 );
        RootPredictedXVariances = cell( T, 1 );
    end
    
    TwoNLogLikelihood = 0;
    for t = 1:T
        InvRootOldXVariance = InvRootXVariance;
        RootOldWVariance = RootWVariance;
        if Smoothing
            [ TwoNLogObservationLikelihood, X, RootXVariance, InvRootXVariance, W, RootWVariance, SmootherGain, PredictedX, RootPredictedXVariance ] = ...
                KalmanStep( dynareOBC.EstimationData( t, : ), OldX, RootOldXVariance, InvRootOldXVariance, RootOldWVariance, RootQ, MEVar, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables, Smoothing );
            FilteredWs{ t } = W;
            RootFilteredWVariances{ t } = RootWVariance;
            SmootherGains{ t } = SmootherGain;
            PredictedXs{ t } = PredictedX;
            RootPredictedXVariances{ t } = RootPredictedXVariance;
        else
            [ TwoNLogObservationLikelihood, X, RootXVariance ] = ...
                KalmanStep( dynareOBC.EstimationData( t, : ), OldX, RootOldXVariance, [], [], RootQ, MEVar, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables, Smoothing );
            if isempty( X ) || toc( StartTime ) > dynareOBC.TimeOutLikelihoodEvaluation
                TwoNLogLikelihood = Inf;
                return;
            end
        end
        TwoNLogObservationLikelihood = TwoNLogObservationLikelihood + ScaledPriorValue;
        if nargout > 1
            TwoNLogObservationLikelihoods( t ) = TwoNLogObservationLikelihood;
        end
        OldX = X;
        RootOldXVariance = RootXVariance;
        TwoNLogLikelihood = TwoNLogLikelihood + TwoNLogObservationLikelihood;
    end
    
    if Smoothing
        SmoothedWs = cell( T, 1 );
        RootSmoothedWVariances = cell( T, 1 );
        SmoothedWs{ T } = W;
        RootSmoothedWVariances{ T } = RootWVariance;
        
        for t = ( T - 1 ):-1:1
            W = FilteredWs{ t } + SmootherGain * ( X - PredictedX );
            SmoothedWs{ t } = W;
            VarianceTerm1 = RootFilteredWVariances{ t };
            VarianceTerm2 = SmootherGain * RootPredictedXVariance;
            VarianceTerm3 = SmootherGain * RootXVariance;
            WVariance = VarianceTerm1 * VarianceTerm1' - VarianceTerm2 * VarianceTerm2' + VarianceTerm3 * VarianceTerm3';
            RootWVariance = ObtainEstimateRootCovariance( WVariance, 0 );
            RootSmoothedWVariances{ t } = RootWVariance;
            RootXVariance = RootWVariance( SelectAugStateVariables, : );
            SmootherGain = SmootherGains{ t };
            PredictedX = PredictedXs{ t };
            RootPredictedXVariance = RootPredictedXVariances{ t };
        end

        dynareOBC.FilteredWs = FilteredWs;
        dynareOBC.RootFilteredWVariances = RootFilteredWVariances;
        dynareOBC.SmoothedWs = SmoothedWs;
        RootSmoothedWVariances.RootSmoothedWVariances = RootSmoothedWVariances;

    end
end
