function y = SolveBoundsProblem( q, dynareOBC )
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    Tolerance = dynareOBC.Tolerance;
    if all( q >= -Tolerance ) && ~dynareOBC.FullHorizon
        y = dynareOBC.ZeroVecS;
        return
    end
    
    M = dynareOBC.MMatrix;
    Ms = dynareOBC.MsMatrix;
    omega = dynareOBC.Omega;

    qs = q( dynareOBC.sIndices );
    
    ParametricSolutionFound = dynareOBC.ParametricSolutionFound;
    ssIndices = dynareOBC.ssIndices;
    
    ZeroVecS = dynareOBC.ZeroVecS;
    
    if dynareOBC.FullHorizon
        InitTs = Ts;
    else
        InitTs = 1;
    end
    
    for Tss = InitTs : Ts
    
        CssIndices = ssIndices{ Tss };
        CParametricSolutionFound = ParametricSolutionFound( Tss );
        
        qss = qs( CssIndices );
        Norm_qss = norm( qss, Inf );
        qss = qss ./ Norm_qss;
        
        if CParametricSolutionFound > 0
            if CParametricSolutionFound > 1
                yss = dynareOBCTempSolution_mex( qss );
            else
                yss = dynareOBCTempSolution( qss );
            end            
        else
            qt = q ./ Norm_qss;

            yss = sdpvar( Tss * ns, 1 );
            alpha = sdpvar( 1, 1 );
            z = binvar( Tss * ns, 1 );
            
            Constraints = [ 0 <= yss, yss <= z, 0 <= alpha, 0 <= alpha * qt + M( :, CssIndices ) * y, alpha * qss + Ms( CssIndices, CssIndices ) * yss <= omega * ( 1 - z ) ];
            Objective = -alpha;
            Diagnostics = optimize( Constraints, Objective, dynareOBC.MILPOptions );
            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveMILPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end
            yss = value( yss ) / value( alpha );
        end
        
        if all( isfinite( yss ) )
            yss = max( 0, yss * Norm_qss );
            y = ZeroVecS;
            y( CssIndices ) = yss;
            w = q + M * y;
            if all( w >= -Tolerance ) && all( abs( w( dynareOBC.sIndices ) .* y ) <= Tolerance )
                return;
            end
        end
        
    end
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
