function [ PersistentState, StateSteadyState, StateVariableIndices ] = EstimationSolution( Parameters, PersistentState )

    global M_ options_ oo_ dynareOBC_ spkronUseMex
    
    M_ = PersistentState.M;
    options_ = PersistentState.options;
    oo_ = PersistentState.oo;
    dynareOBC_ = PersistentState.dynareOBC;
    spkronUseMex = PersistentState.spkronUseMex;
    
    M_.params( dynareOBC_.EstimationParameterSelect ) = Parameters( 1 : length( dynareOBC_.EstimationParameterSelect ) );
    
    options_.qz_criterium = 1 - 1e-6;
    
    try
        [ Info, M_, options_, oo_, dynareOBC_ ] = ModelSolution( false, M_, options_, oo_, dynareOBC_, PersistentState.InitialRun );
    catch Error
        rethrow( Error );
    end
    if Info ~= 0
        error( 'dynareOBC:EstimationBK', 'Apparent Blanchard-Kahn condition violation.' );
    end

    NEndo = M_.endo_nbr;
    NEndoMult = 2 .^ ( dynareOBC_.Order - 1 );
    
    StateVariableIndices = ismember( ( 1:NEndo )', oo_.dr.order_var( dynareOBC_.SelectState ) );
    StateVariableIndices = find( repmat( StateVariableIndices, NEndoMult, 1 ) );
   
    LagIndices = find( dynareOBC_.OriginalLeadLagIncidence( 1, : ) > 0 );
    CurrentIndices = find( dynareOBC_.OriginalLeadLagIncidence( 2, : ) > 0 );
    if size( dynareOBC_.OriginalLeadLagIncidence, 1 ) > 2
        LeadIndices = dynareOBC_.OriginalLeadLagIncidence( 3, : ) > 0;
    else
        LeadIndices = [];
    end
    FutureValues = nan( sum( LeadIndices ), 1 );
    
    PersistentState.M = M_;
    PersistentState.options = options_;
    PersistentState.oo = oo_;
    PersistentState.dynareOBC = dynareOBC_;
    
    PersistentState.LagIndices = LagIndices;
    PersistentState.CurrentIndices = CurrentIndices;
    PersistentState.FutureValues = FutureValues;
    
    StateSteadyState = zeros( length( StateVariableIndices ), 1 );
    
end
