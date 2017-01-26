function [ LogLikelihood, EstimationPersistentState, LogObservationLikelihoods, M, options, oo, dynareOBC ] = EstimationObjective( p, EstimationPersistentState, M, options, oo, dynareOBC, InitialRun, Smoothing )

    LogLikelihood = -Inf;
    [ T, N ] = size( dynareOBC.EstimationData );
    if nargout > 1
        LogObservationLikelihoods = NaN( T, 1 );
    end

    M.params( dynareOBC.EstimationParameterSelect ) = p( 1 : length( dynareOBC.EstimationParameterSelect ) );
    diagLambda = exp( p( length( dynareOBC.EstimationParameterSelect ) + ( 1 : N ) ) );
    
    options.qz_criterium = 1 - 1e-6;
    try
        [ Info, M, options, oo, dynareOBC ] = ModelSolution( false, M, options, oo, dynareOBC, InitialRun );
    catch Error
        rethrow( Error );
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
    
    RootExoVar = ObtainEstimateRootCovariance( M.Sigma_e( 1:NExo, 1:NExo ), StdDevThreshold );

    LagIndices = find( dynareOBC.OriginalLeadLagIncidence( 1, : ) > 0 );
    CurrentIndices = find( dynareOBC.OriginalLeadLagIncidence( 2, : ) > 0 );
    if size( dynareOBC.OriginalLeadLagIncidence, 1 ) > 2
        LeadIndices = dynareOBC.OriginalLeadLagIncidence( 3, : ) > 0;
    else
        LeadIndices = [];
    end
    FutureValues = nan( sum( LeadIndices ), 1 );
    
    if isempty( EstimationPersistentState )
        % get initial mean and covariance
        xoo = full( dynareOBC.Mean_z );
        xoo = xoo( dynareOBC.CoreSelectInAugmented );
        xoo = xoo( SelectAugStateVariables );
        dr = oo.dr;

        if dynareOBC.Order == 1
            TempPsoo = full( dynareOBC.Var_z1 );
            TempPsooSelect = dr.inv_order_var( SelectStateVariables );
        else
            TempPsoo = full( dynareOBC.Var_z2 );
            TempPsooSelect = [ dr.inv_order_var( SelectStateVariables ); NEndo + dr.inv_order_var( SelectStateVariables ) ];
        end

        TempSsoo = ObtainEstimateRootCovariance( TempPsoo( TempPsooSelect, TempPsooSelect ), StdDevThreshold );

        Ssoo = zeros( NAugState, size( TempSsoo, 2 ) );
        Ssoo( 1:size( TempSsoo, 1 ), : ) = TempSsoo; % handles 3rd order
        % end getting initial mean and covariance

        deltasoo = zeros( size( xoo ) );
        tauoo = -Inf;
        nuoo = Inf;
    else
        xoo = EstimationPersistentState.xoo;
        Ssoo = EstimationPersistentState.Ssoo;
        deltasoo = EstimationPersistentState.deltasoo;
        tauoo = EstimationPersistentState.tauoo;
        nuoo = EstimationPersistentState.nuoo;
    end
    
    Psoo = Ssoo * Ssoo';

    CompOld = [ Psoo(:); xoo; deltasoo ];
    
    if isfinite( tauoo )
        CompOld = [ CompOld; tauoo ];
    end
    if isfinite( nuoo )
        CompOld = [ CompOld; nuoo ];
    end    
    
    ErrorOld = Inf;
    StepSize = 1;
    
    MParams = M.params;
    OoDrYs = oo.dr.ys( 1:dynareOBC.OriginalNumVar );
    
    tCutOff = 100;
    
    if dynareOBC.NoTLikelihood
        nuno = Inf;
        assert( length( p ) == length( dynareOBC.EstimationParameterSelect ) + N );
    elseif dynareOBC.DynamicNu
        nuno = [];
        assert( length( p ) == length( dynareOBC.EstimationParameterSelect ) + N );
    else
        nuno = exp( p( end ) );
        assert( length( p ) == length( dynareOBC.EstimationParameterSelect ) + N + 1 );
    end

    for t = 1:dynareOBC.StationaryDistMaxIterations
        try
            [ ~, xnn, Ssnn, deltasnn, taunn, nunn ] = KalmanStep( nan( 1, N ), xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables );
        catch
            xnn = [];
        end
        if ~Smoothing && isempty( xnn )
            return;
        end
        
        Psnn = Ssnn * Ssnn';
        
        xnn = xoo + StepSize * ( xnn - xoo );
        Psnn = Psoo + StepSize * ( Psnn - Psoo );
        deltasnn = deltasoo + StepSize * ( deltasnn - deltasoo );

        CompNew = [ Psnn(:); xnn; deltasnn ];
        
        if isfinite( tauoo ) && isfinite( taunn )
            taunn = tauoo + StepSize * ( taunn - tauoo );
            CompNew = [ CompNew; taunn ]; %#ok<AGROW>
        end
        if isfinite( nuoo ) && isfinite( nunn )
            nunn = nuoo + StepSize * ( nunn - nuoo );
            CompNew = [ CompNew; nunn ]; %#ok<AGROW>
        end
        
        xoo = xnn;
        Ssoo = ObtainEstimateRootCovariance( Psnn, StdDevThreshold );
        deltasoo = deltasnn;
        tauoo = taunn;
        nuoo = nunn;
        
        nComp = min( length( CompNew ), length( CompOld ) );
        
        Error = max( abs( CompNew( 1:nComp ) - CompOld( 1:nComp ) ) );
        ErrorScale = sqrt( eps( max( abs( [ CompNew( 1:nComp ); CompOld( 1:nComp ) ] ) ) ) );
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

    EstimationPersistentState.xoo = xoo;
    EstimationPersistentState.Ssoo = Ssoo;
    EstimationPersistentState.deltasoo = deltasoo;
    EstimationPersistentState.tauoo = tauoo;
    EstimationPersistentState.nuoo = nuoo;

    PriorFunc = str2func( dynareOBC.Prior );
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
            if dynareOBC.DynamicNu
                nuno = [];
            end
            [ LogObservationLikelihood, xnn, Ssnn, deltasnn, taunn, nunn, wnn, Pnn, deltann, xno, Psno, deltasno, tauno, nuno ] = ...
                KalmanStep( dynareOBC.EstimationData( t, : ), xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables );
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
                KalmanStep( dynareOBC.EstimationData( t, : ), xoo, Ssoo, deltasoo, tauoo, nuoo, RootExoVar, diagLambda, nuno, MParams, OoDrYs, dynareOBC, LagIndices, CurrentIndices, FutureValues, SelectAugStateVariables );
            if isempty( xnn )
                LogLikelihood = Inf;
                return;
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
end
