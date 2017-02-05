function [ ObservationLikelihoods, EstimationPersistentState ] = GetScoreVector( p, EstimationPersistentState )
    [ ~, EstimationPersistentState, ObservationLikelihoods ] = EstimationObjective( p, EstimationPersistentState, false );
    ObservationLikelihoods = -0.5 * ObservationLikelihoods;
end
