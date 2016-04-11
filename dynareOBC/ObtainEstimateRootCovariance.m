function RootCovariance = ObtainEstimateRootCovariance( Covariance, EstimationStdDevThreshold )
    [U,D] = schur( Covariance, 'complex' );
    % assert( isreal( U ) );
    diagD = diag( D );
    % assert( isreal( diagD ) );
    RootD = sqrt( diagD );
    IDv = RootD > EstimationStdDevThreshold;
    RootCovariance = U( :, IDv ) * diag( RootD( IDv ) );
end
