function RootConditionalCovariance = ObtainRootConditionalCovariance( ConditionalCovariance, dynareOBC )
    [U,D] = schur( ConditionalCovariance, 'complex' );
    % assert( isreal( U ) );
    diagD = diag( D );
    % assert( isreal( diagD ) );
    max_diagD = max( diagD );
    diagD( diagD < dynareOBC.CubaturePruningCutOff * max_diagD ) = 0;
    diagD( 1 : end - dynareOBC.MaxCubatureDimension ) = 0;
    RootD = sqrt( diagD );
    IDv = RootD > sqrt( eps );
    RootConditionalCovariance = U( :, IDv ) * diag( RootD( IDv ) );
end
