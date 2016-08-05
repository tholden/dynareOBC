function RootCovariance = ObtainEstimateRootCovariance( Covariance, StdDevThreshold )
    [ U, D ] = schur( full( Covariance ), 'complex' );
    % assert( isreal( U ) );
    diagD = diag( D );
    % assert( isreal( diagD ) );
    RootD = sqrt( max( 0, real( diagD ) ) );
    IDv = RootD > StdDevThreshold;
    RootCovariance = real( U( :, IDv ) ) * diag( RootD( IDv ) );
end
