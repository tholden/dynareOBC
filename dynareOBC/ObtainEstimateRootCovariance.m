function RootCovariance = ObtainEstimateRootCovariance( Covariance, EstimationStdDevThreshold, MaximumDimension )
    [U,D] = schur( Covariance, 'complex' );
    % assert( isreal( U ) );
    diagD = diag( D );
    % assert( isreal( diagD ) );
    RootD = sqrt( diagD );
    IDv = RootD > EstimationStdDevThreshold;
    if nargin > 2
        IDv( 1 : ( end - MaximumDimension ) ) = false;
    end
    RootCovariance = U( :, IDv ) * diag( RootD( IDv ) );
end
