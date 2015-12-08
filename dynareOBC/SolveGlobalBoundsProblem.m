function y = SolveGlobalBoundsProblem( y, Ey, UnconstrainedReturnPathShortRun, UnconstrainedReturnPathLongRun, pWeight, dynareOBC )

    DesiredReturnPath = max( 0, UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * max( 0, y ) );
    
    W1 = repmat( pWeight, 1, size( UnconstrainedReturnPathLongRun, 2 ) );
    W2 = repmat( 1 - pWeight, 1, size( UnconstrainedReturnPathLongRun, 2 ) );
    W1 = W1(:);
    W2 = W2(:);
    
    y = sdpvar( length( y ), 1 );

    ConstrainedReturnPathLongRun = UnconstrainedReturnPathLongRun(:) + dynareOBC.MMatrixLongRun * y;
    ConstrainedReturnPathShortRun = UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * y;
    
    yResiduals = y - Ey;
    ConstraintResiduals = sdpvar( length( y ), 1 );
    Violations_0 = sdpvar( length( y ), 1 );
    Violations_x = sdpvar( length( y ), 1 );
    
    Constraints = [ -dynareOBC.Tolerance <= W1 .* ( DesiredReturnPath - ConstrainedReturnPathLongRun ) + W2 .* ConstraintResiduals <= dynareOBC.Tolerance, ConstrainedReturnPathLongRun >= -Violations_0, Violations_0 >= 0, y + ConstrainedReturnPathLongRun - ConstrainedReturnPathShortRun >= -Violations_x, Violations_x >= 0 ];
    Diagnostics = optimize( Constraints, ( ConstraintResiduals' * ConstraintResiduals ) * dynareOBC.GlobalConstraintStrength + yResiduals' * yResiduals + ( Violations_0' * Violations_0 + Violations_x' * Violations_x ) * dynareOBC.GlobalViolationStrength, dynareOBC.QPOptions );

    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveGlobalBoundsProblem', [ 'An apparently impossible quadratic progrmaming problem was encountered when solving the global bounds problem. Internal message: ' Diagnostics.info ] );
    end
    if max( value( Violations_0 ) ) > 1e-4
        warning( 'dynareOBC:InaccuracyInGlobalBoundsProblem', 'The solution to the global bounds problem may violate a constraint of the form E(max{0,x})>=0.' );
    end
    if max( value( Violations_x ) ) > 1e-4
        warning( 'dynareOBC:InaccuracyInGlobalBoundsProblem', 'The solution to the global bounds problem may violate a constraint of the form E(max{0,x})>=x.' );
    end
    y = value( y );

end
