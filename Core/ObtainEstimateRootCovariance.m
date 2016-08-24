function [ RootCovariance, InvRootCovariance, LogDetCovariance ] = ObtainEstimateRootCovariance( Covariance, StdDevThreshold )
    Covariance = full( 0.5 * ( Covariance + Covariance' ) );
    [ U, D ] = schur( Covariance, 'real' );
    diagD = diag( D );
    RootD = sqrt( max( 0, real( diagD ) ) );
    IDv = RootD > StdDevThreshold;
    Usub = real( U( :, IDv ) );
    RootCovariance = Usub * diag( RootD( IDv ) );
    if nargout > 1
        InvRootCovariance = diag( 1 ./ RootD( IDv ) ) * Usub';
        if nargout > 2
            LogDetCovariance = sum( log( RootD ) );
        end
    end
    % InvRootCovariance * RootCovariance = diag( 1 ./ RootD( IDv ) ) * Usub' * Usub * diag( RootD( IDv ) ) = eye
    % RootCovariance * InvRootCovariance = Usub * diag( RootD( IDv ) ) * diag( 1 ./ RootD( IDv ) ) * Usub' = Usub * Usub'
end
