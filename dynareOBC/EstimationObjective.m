function [ TwoNLogLikelihood, EndoSelectWithControls, EndoSelect ] = EstimationObjective( p, M, options, oo, dynareOBC, EndoSelectWithControls, EndoSelect )
    TwoNLogLikelihood = Inf;
    [ T, N ] = size( dynareOBC.EstimationData );
       
    M.params( dynareOBC.EstimationParameterSelect ) = p( 1 : length( dynareOBC.EstimationParameterSelect ) );
    RootMEVar = p( ( length( dynareOBC.EstimationParameterSelect ) + 1 ):end );
    
    if nargin < 6
        SlowMode = true;
    else
        SlowMode = false;
    end
    
    [ Info, M, options, oo, dynareOBC ] = ModelSolution( 1, M, options, oo, dynareOBC, SlowMode );
    if Info ~= 0
        return
    end
    
    
    NEndo = M.endo_nbr;
    NExo = dynareOBC.OriginalNumVarExo;
    NEndoMult = ( 2 .^ ( dynareOBC.Order - 1 ) ) + 1;
    Nm = NEndoMult * NEndo;

    RootQ = chol( M.Sigma_e( 1:NExo, 1:NExo ), 'lower' ); % sparse

    OriginalVarSelect = false( NEndo );
    OriginalVarSelect( 1:dynareOBC.OriginalNumVar ) = true;
    LagIndices = dynareOBC.OriginalLeadLagIncidence( 1, : ) > 0;
    CurrentIndices = dynareOBC.OriginalLeadLagIncidence( 2, : ) > 0;
    LeadIndices = dynareOBC.OriginalLeadLagIncidence( 3, : ) > 0;
    FutureValues = nan( sum( LeadIndices ), 1 );
    NanShock = nan( 1, NExo );

    persistent FullMean;
    persistent FullRootCovariance;
    
    UpdateSelect = SlowMode || isempty( FullMean ) || isempty( FullRootCovariance ) || any( size( FullMean ) ~= [ Nm 1 ] ) || any( size( FullRootCovariance ) ~= [ Nm Nm ] ) || any( ~isfinite( FullMean ) ) || any( any( ~isfinite( FullRootCovariance ) ) );
    if UpdateSelect
        OldMean = zeros( Nm, 1 );
        dr = oo.dr;
        if dynareOBC.Order == 1
            TempOldRootCovariance = chol( dynareOBC.Var_z1( dr.inv_order_var, dr.inv_order_var ) + sqrt( eps ) * eye( NEndo ), 'lower' );
        else
            doubleInvOrderVar = [ dr.inv_order_var; dr.inv_order_var ];
            TempOldRootCovariance = chol( dynareOBC.Var_z2( doubleInvOrderVar, doubleInvOrderVar ) + sqrt( eps ) * eye( 2 * NEndo ), 'lower' );
        end

        OldRootCovariance = zeros( Nm, Nm );
        OldRootCovariance( 1:size( TempOldRootCovariance, 1 ), 1:size( TempOldRootCovariance, 2 ) ) = TempOldRootCovariance;
    else
        OldMean = FullMean;
        OldRootCovariance = FullRootCovariance;
    end
    
    AllEndoSelect = true( size( OldMean ) );
    
    if UpdateSelect
        if isfield( dr, 'state_var' )
            state_var = dr.state_var;
        else
            klag = dr.kstate( dr.kstate(:,2) <= M.maximum_lag+1, [1 2] );
            state_var = dr.order_var( klag(:,1) );
        end
    end
    
    for t = 1:dynareOBC.EstimationFixedPointMaxIterations
        if UpdateSelect
            EndoSelectWithControls = ( diag( OldRootCovariance * OldRootCovariance' ) > sqrt( eps ) );
            EndoSelect = EndoSelectWithControls & repmat( ismember( (1:NEndo)', state_var ), NEndoMult, 1 );
        end

        try
            [ Mean, RootCovariance ] = KalmanStep( nan( 1, N ), AllEndoSelect, EndoSelect, AllEndoSelect, OldMean, OldMean( EndoSelect ), OldRootCovariance( EndoSelect, EndoSelect ), RootQ, RootMEVar, M, options, oo, dynareOBC, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock );
        catch
            Mean = [];
        end
        if isempty( Mean )
            break;
        end
        CompNew = RootCovariance * RootCovariance';
        CompNew = [ CompNew(:); Mean ];
        CompOld = OldRootCovariance * OldRootCovariance';
        CompOld = [ CompOld(:); OldMean ];

        OldMean = Mean; % 0.5 * Mean + 0.5 * OldMean;
        RCSize = size( RootCovariance );
        OldRootCovariance = [ RootCovariance, zeros( RCSize(1), RCSize(1) - RCSize(2) ) ]; % 0.5 * RootCovariance + 0.5 * OldRootCovariance;
        
        LCompNew = log( abs( CompNew ) );
        SCompNew = isfinite( LCompNew );
        LCompOld = log( abs( CompOld ) );
        SCompOld = isfinite( LCompOld );
        if all( SCompNew == SCompOld )
            Error = max( max( abs( CompNew - CompOld ) ), max( abs( LCompNew( SCompNew ) - LCompOld( SCompOld ) ) ) );
            if Error < 1e-4
                FullMean = OldMean;
                FullRootCovariance = OldRootCovariance;
                break;
            end
        end
    end
    if isempty( OldMean ) || isempty( OldRootCovariance );
        return;
    end

    if UpdateSelect
        EndoSelectWithControls = ( diag( OldRootCovariance * OldRootCovariance' ) > sqrt( eps ) );
        EndoSelect = EndoSelectWithControls & repmat( ismember( (1:NEndo)', state_var ), NEndoMult, 1 );
    end

    CurrentFullMean = OldMean;
    OldMean = OldMean( EndoSelect );
    OldRootCovariance = OldRootCovariance( EndoSelect, EndoSelect );
    
    SubEndoSelect = EndoSelect( EndoSelectWithControls );
    
    for t = 1:dynareOBC.EstimationFixedPointMaxIterations
        try
            [ Mean, RootCovariance ] = KalmanStep( nan( 1, N ), EndoSelectWithControls, EndoSelect, SubEndoSelect, CurrentFullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M, options, oo, dynareOBC, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock );
        catch
            Mean = [];
        end
        if isempty( Mean )
            break;
        end
        CompNew = RootCovariance * RootCovariance';
        CompNew = [ CompNew(:); Mean ];
        CompOld = OldRootCovariance * OldRootCovariance';
        CompOld = [ CompOld(:); OldMean ];

        OldMean = Mean; % 0.5 * Mean + 0.5 * OldMean;
        OldRootCovariance = RootCovariance; % 0.5 * RootCovariance + 0.5 * OldRootCovariance;
        
        LCompNew = log( abs( CompNew ) );
        SCompNew = isfinite( LCompNew );
        LCompOld = log( abs( CompOld ) );
        SCompOld = isfinite( LCompOld );
        if all( SCompNew == SCompOld )
            Error = max( max( abs( CompNew - CompOld ) ), max( abs( LCompNew( SCompNew ) - LCompOld( SCompOld ) ) ) );
            if Error < 1e-4
                break;
            end
        end
    end

    TwoNLogLikelihood = 0;
    for t = 1:T
        [ Mean, RootCovariance, TwoNLogObservationLikelihood ] = KalmanStep( dynareOBC.EstimationData( t, : ), EndoSelectWithControls, EndoSelect, SubEndoSelect, CurrentFullMean, OldMean, OldRootCovariance, RootQ, RootMEVar, M, options, oo, dynareOBC, OriginalVarSelect, LagIndices, CurrentIndices, FutureValues, NanShock );
        if isempty( Mean )
            TwoNLogLikelihood = Inf;
            return;
        end
        OldMean = Mean;
        OldRootCovariance = RootCovariance;
        TwoNLogLikelihood = TwoNLogLikelihood + TwoNLogObservationLikelihood;
    end
end
