function [ ObservationLikelihoods, EstimationPersistentState ] = GetScoreVector( p, EstimationPersistentState )
    [ ~, EstimationPersistentState, ObservationLikelihoods ] = EstimationObjective( p, EstimationPersistentState, false );
end
