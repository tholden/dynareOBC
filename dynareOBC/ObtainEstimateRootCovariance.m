function RootCovariance = ObtainEstimateRootCovariance( Covariance, EstimationStdDevThreshold )
    [ U, D ] = schur( full( Covariance ), 'complex' );
    % assert( isreal( U ) );
    diagD = diag( D );
    % assert( isreal( diagD ) );
    RootD = sqrt( max( 0, real( diagD ) ) );
    IDv = RootD > EstimationStdDevThreshold;
    RootCovariance = real( U( :, IDv ) ) * diag( RootD( IDv ) );
end
