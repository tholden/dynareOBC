function [ TwoNLogLikelihood, TwoNLogObservationLikelihoods, M, options, oo, dynareOBC ] = EstimationObjective( p, M, options, oo, dynareOBC, InitialRun )
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
    
    StateVariables = ismember( ( 1:NEndo )', oo.dr.order_var( dynareOBC.SelectState ) );
    AugStateVariables = repmat( StateVariables, NEndoMult, 1 );
    NState = sum( StateVariables );
    NAugState = NEndoMult * NState;
   
    StdDevThreshold = dynareOBC.StdDevThreshold;
    
    RootQ = ObtainEstimateRootCovariance( M.Sigma_e( 1:NExo, 1:NExo ), StdDevThreshold );

    LagIndices = find( dynareOBC.OriginalLeadLagIncidence( 1, : ) > 0 );
    % CurrentIndices = find( dynareOBC.OriginalLeadLagIncidence( 2, : ) > 0 );
    if size( dynareOBC.OriginalLeadLagIncidence, 1 ) > 2
        LeadIndices = dynareOBC.OriginalLeadLagIncidence( 3, : ) > 0;
    else
        LeadIndices = [];
    end
    FutureValues = nan( sum( LeadIndices ), 1 );
    NanShock = nan( 1, NExo );
    
    % get initial mean and covariance
    OldMean = full( dynareOBC.Mean_z );
    OldMean = OldMean( dynareOBC.CoreSelectInAugmented );
    OldMean = OldMean( AugStateVariables );
    dr = oo.dr;

    if dynareOBC.Order == 1
        TempCovariance = full( dynareOBC.Var_z1 );
        TempCovarianceSelect = dr.inv_order_var( StateVariables );
    else
        TempCovariance = full( dynareOBC.Var_z2 );
        TempCovarianceSelect = [ dr.inv_order_var( StateVariables ); NEndo + dr.inv_order_var( StateVariables ) ];
    end

    TempOldRootCovariance = ObtainEstimateRootCovariance( TempCovariance( TempCovarianceSelect, TempCovarianceSelect ), StdDevThreshold );

    OldRootCovariance = zeros( NAugState, size( TempOldRootCovariance, 2 ) );
    OldRootCovariance( 1:size( TempOldRootCovariance, 1 ), : ) = TempOldRootCovariance; % handles 3rd order
    % end getting initial mean and covariance
    
    OldCovariance = OldRootCovariance * OldRootCovariance';
    CompOld = [ OldCovariance(:); OldMean ];
    ErrorOld = Inf;
    StepSize = 1;
    
    MParams = M.params;
    OoDrYs = oo.dr.ys( 1:dynareOBC.OriginalNumVar );
    
    TempRequiredForMeasurementSelect = ismember( ( 1:NEndo )', dynareOBC.RequiredCurrentVariables );
    RequiredForMeasurementSelect = repmat( TempRequiredForMeasurementSelect, NEndoMult, 1 );
    RequiredForMeasurementSelect = RequiredForMeasurementSelect | AugStateVariables;
    MeasurementRHSSelect = ismember( find( RequiredForMeasurementSelect( 1:NEndo ) ), find( TempRequiredForMeasurementSelect ) );
    MeasurementLHSSelect = TempRequiredForMeasurementSelect( 1:dynareOBC.OriginalNumVar );
    
    SelectStateFromStateAndControls = ismember( find( RequiredForMeasurementSelect ), find( AugStateVariables ) );
        
    tCutOff = 100;
    
    StartTime = tic;
    
    for t = 1:dynareOBC.StationaryDistMaxIterations
        try
            [ Mean, RootCovariance ] = KalmanStep( nan( 1, N ), OldMean, OldRootCovariance, RootQ, MEVar, MParams, OoDrYs, dynareOBC, RequiredForMeasurementSelect, LagIndices, MeasurementLHSSelect, MeasurementRHSSelect, FutureValues, NanShock, AugStateVariables, SelectStateFromStateAndControls );
        catch
            Mean = [];
        end
        if isempty( Mean ) || toc( StartTime ) > dynareOBC.TimeOutLikelihoodEvaluation
            return;
        end
        
        Covariance = RootCovariance * RootCovariance';
        
        Mean = OldMean + StepSize * ( Mean - OldMean );
        Covariance = OldCovariance + StepSize * ( Covariance - OldCovariance );

        CompNew = [ Covariance(:); Mean ];
        
        OldMean = Mean;
        OldRootCovariance = ObtainEstimateRootCovariance( Covariance, StdDevThreshold );
        
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
    
    TwoNLogLikelihood = 0;
    for t = 1:T
        [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( dynareOBC.EstimationData( t, : ), OldMean, OldRootCovariance, RootQ, MEVar, MParams, OoDrYs, dynareOBC, RequiredForMeasurementSelect, LagIndices, MeasurementLHSSelect, MeasurementRHSSelect, FutureValues, NanShock, AugStateVariables, SelectStateFromStateAndControls );
        if isempty( Mean ) || toc( StartTime ) > dynareOBC.TimeOutLikelihoodEvaluation
            TwoNLogLikelihood = Inf;
            return;
        end
        TwoNLogObservationLikelihood = TwoNLogObservationLikelihood + ScaledPriorValue;
        if nargout > 1
            TwoNLogObservationLikelihoods( t ) = TwoNLogObservationLikelihood;
        end
        OldMean = Mean;
        OldRootCovariance = RootCovariance;
        TwoNLogLikelihood = TwoNLogLikelihood + TwoNLogObservationLikelihood;
    end
end
