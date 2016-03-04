function y = SolveGlobalBoundsProblem( y, GlobalVarianceShare, UnconstrainedReturnPathShortRun, UnconstrainedReturnPathLongRun, dynareOBC )

    DesiredReturnPath = max( 0, UnconstrainedReturnPathShortRun(:) + dynareOBC.MMatrix * max( 0, y ) );
    
    DesiredReturnPath = GlobalVarianceShare * DesiredReturnPath + ( 1 - GlobalVarianceShare ) * UnconstrainedReturnPathLongRun;
    
    y = pinv( dynareOBC.MMatrixLongRun ) * ( DesiredReturnPath - UnconstrainedReturnPathLongRun(:) );

end
