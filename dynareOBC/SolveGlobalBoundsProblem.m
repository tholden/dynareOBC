function y = SolveGlobalBoundsProblem( y, Ey, UnconstrainedReturnPathShortRun, UnconstrainedReturnPathLongRun, pWeight, dynareOBC )

    DesiredReturnPath = max( 0, UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * max( 0, y ) );
    
    W1 = repmat( pWeight, 1, size( UnconstrainedReturnPathLongRun, 2 ) );
    W2 = repmat( 1 - pWeight, 1, size( UnconstrainedReturnPathLongRun, 2 ) );
    
    y = sdpvar( length( y ), 1 );

    ConstrainedReturnPathLongRun = UnconstrainedReturnPathLongRun(:) + dynareOBC.MMatrixLongRun * y;
    ConstrainedReturnPathShortRun = UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * y;
    
    yResiduals = y - Ey;
    ConstraintResiduals = sdpvar( length( y ), 1 );
    Violations = sdpvar( length( y ), 1 );
    
    Constraints = [ 0 == W1 .* ( DesiredReturnPath - ConstrainedReturnPathLongRun ) + W2 .* ConstraintResiduals, ConstrainedReturnPathLongRun >= 0, y + ConstrainedReturnPathLongRun - ConstrainedReturnPathShortRun >= -Violations, Violations >= 0 ];
    Diagnostics = optimize( Constraints, ( ConstraintResiduals' * ConstraintResiduals ) * dynareOBC.GlobalConstraintStrength + yResiduals' * yResiduals + 1e8 * ( Violations' * Violations ), dynareOBC.LPOptions );
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveGlobalBoundsProblem', [ 'An apparently impossible quadratic progrmaming problem was encountered when solving the global bounds problem. Internal message: ' Diagnostics.info ] );
    end
    if max( value( Violations ) ) > sqrt( eps )
        warning( 'dynareOBC:InaccuracyInGlobalBoundsProblem', [ 'The solution to the global bounds problem may violate a constraint of the form max{0,x}>=x.' ] );
    end
    y = value( y );

end
