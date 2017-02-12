function RootConditionalCovariance = ObtainRootConditionalCovariance( ConditionalCovariance, PruningCutOff, MaxDimension )
    [U,D] = schur( ConditionalCovariance, 'complex' );
    % assert( isreal( U ) );
    diagD = diag( D );
    % assert( isreal( diagD ) );
    max_diagD = max( diagD );
    diagD( diagD < PruningCutOff * max_diagD ) = 0;
    diagD( 1 : end - MaxDimension ) = 0;
    RootD = sqrt( diagD );
    IDv = RootD > sqrt( eps );
    RootConditionalCovariance = U( :, IDv ) * diag( RootD( IDv ) );
end
