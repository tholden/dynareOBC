function y = SolveGlobalBoundsProblem( y, UnconstrainedReturnPathShortRun, UnconstrainedReturnPathLongRun, pWeight, ErrorWeight, dynareOBC )
    DesiredReturnPath = UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * y;
    DesiredReturnPath = vec( bsxfun( @times, pWeight, reshape( DesiredReturnPath, size( UnconstrainedReturnPathLongRun ) ) ) + bsxfun( @times, 1 - pWeight, UnconstrainedReturnPathLongRun ) );
    y = sdpvar( length( y ), 1 );
    ConstrainedReturnPathLongRun = UnconstrainedReturnPathLongRun(:) + dynareOBC.MMatrixLongRun * y;
    ConstrainedReturnPathShortRun = UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * y;
    Error = ConstrainedReturnPathLongRun - DesiredReturnPath;
    Error = reshape( Error, size( UnconstrainedReturnPathLongRun ) );
    lambdas = sdpvar( size( Error, 1 ), size( Error, 2 ), 'full' );
    kappas = sdpvar( length( y ), 1 );
    mus = sdpvar( size( ConstrainedReturnPathLongRun, 1 ), 1 );
    Constraints = [ 0 <= lambdas, 0 <= kappas, 0 <= mus, Error <= lambdas .* ErrorWeight, -Error <= lambdas .* ErrorWeight, ConstrainedReturnPathLongRun >= -mus, y >= ConstrainedReturnPathShortRun - ConstrainedReturnPathLongRun - kappas ];
    Diagnostics = optimize( Constraints, sum( lambdas(:) ) + sum( kappas(:) ), dynareOBC.LPOptions );
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
    end
    if max( value( lambdas(:) ) ) > sqrt( eps )
        warning( 'dynareOBC:GlobalInaccuracy', 'Inaccruacy in generating news shocks in the global solution. Try increasing TimeToReturnToSteadyState.' );
    end
    if max( value( kappas(:) ) ) > sqrt( eps )
        warning( 'dynareOBC:GlobalViolationSeverity1', 'The returned global solution appears to violate a condition of the form max{0,x} >= x.' );
    end
    if max( value( mus(:) ) ) > sqrt( eps )
        warning( 'dynareOBC:GlobalViolationSeverity2', 'The returned global solution appears to violate a condition of the form max{0,x} >= 0.' );
    end
    y = value( y );
end
