function y = SolveBoundsProblem( q, dynareOBC )
    Tolerance = dynareOBC.Tolerance;
    if all( q >= -Tolerance )
        y = dynareOBC.ZeroVecS;
         return
    end
    
    M = dynareOBC.MMatrix;
    Ms = dynareOBC.MsMatrix;
    omega = dynareOBC.Omega;

    qs = q( dynareOBC.sIndices );
    if dynareOBC.ParametricSolutionFound > 0
        qss = qs( dynareOBC.ssIndices );
        Norm_qss = max( abs( qss ) );
        qss = qss ./ Norm_qss;
        if dynareOBC.ParametricSolutionFound > 1
            ys = dynareOBCTempSolution_mex( qss );
        else
            ys = dynareOBCTempSolution( qss );
        end
        ys = ys * Norm_qss;
        if all( ys >= -Tolerance ) && all( isfinite( ys ) )
            y = dynareOBC.ZeroVecS;
            y( dynareOBC.ssIndices ) = ys;
            w = q + M * y;
            if all( w >= -Tolerance ) && all( abs( w( dynareOBC.sIndices ) .* y ) <= Tolerance )
                return;
            end
        end
    end
    
    Norm_qs = max( abs( qs ) );
    qs = qs ./ Norm_qs;

    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    y = sdpvar( Ts * ns, 1 );
    alpha = sdpvar( 1, 1 );
    z = binvar( Ts * ns, 1 );

    Constraints = [ 0 <= y, y <= z, 0 <= alpha * q + M * y, alpha * qs + Ms * y <= omega * ( 1 - z ) ]; %, dynareOBC.IntegerTolerance <= alpha, alpha * Norm_qs <= 1 + NormMs ];
    Objective = -alpha;
    Diagnostics = optimize( Constraints, Objective, dynareOBC.MILPOptions );
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveMILPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
    end
    if abs( value( alpha ) ) < eps
        error( 'dynareOBC:InfeasibleMILPProblem', 'Infeasible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    end
    if value( z( end ) )
        warning( 'dynareOBC:Inaccuracy', 'The constraint binds in the final period. This is indicative of TimeToEscapeBounds being too low.' );
    end
    y = value( y ) * ( Norm_qs / value( alpha ) );
    
end
