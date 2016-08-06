function ObservationLikelihoods = GetScoreVector( p, M, options, oo, dynareOBC )
    [ ~, ObservationLikelihoods ] = EstimationObjective( p, M, options, oo, dynareOBC, false, false );
    ObservationLikelihoods = -0.5 * ObservationLikelihoods;
end
