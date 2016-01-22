function y = SolveBoundsProblem( q, dynareOBC )
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    Tolerance = dynareOBC.Tolerance;
    if all( q >= -Tolerance ) && ~dynareOBC.FullHorizon
        y = dynareOBC.ZeroVecS;
        return
    end
    
    Norm_q = norm( q, Inf );
    if Norm_q < Tolerance
        Norm_q = 1;
    end
    qScaled = q ./ Norm_q;
    
    M = dynareOBC.MMatrix;
    Ms = dynareOBC.MsMatrix;
    omega = dynareOBC.Omega;

    qsScaled = qScaled( dynareOBC.sIndices );
    
    ParametricSolutionFound = dynareOBC.ParametricSolutionFound;
    ssIndices = dynareOBC.ssIndices;
    
    ZeroVecS = dynareOBC.ZeroVecS;
    
    if dynareOBC.FullHorizon
        InitTs = Ts;
    else
        InitTs = 1;
    end
    
    for Tss = InitTs : Ts
    
        strTss = int2str( Tss );
        
        CssIndices = ssIndices{ Tss };
        CParametricSolutionFound = ParametricSolutionFound( Tss );
        
        qssScaled = qsScaled( CssIndices );
        
        if CParametricSolutionFound > 0
            try
                if CParametricSolutionFound > 1
                    yScaled = feval( [ 'dynareOBCTempSolution' strTss '_mex' ], qssScaled );
                else
                    yScaled = feval( [ 'dynareOBCTempSolution' strTss ], qssScaled );
                end
            catch
                warning( 'dynareOBC:ParametricEvaluationProblem', 'Problem running the parametric solution.' );
                CParametricSolutionFound = 0;
            end
        end
        
        if CParametricSolutionFound == 0
            yScaled = sdpvar( Tss * ns, 1 );
            alpha = sdpvar( 1, 1 );
            z = binvar( Tss * ns, 1 );
            
            Constraints = [ 0 <= yScaled, yScaled <= z, 0 <= alpha, 0 <= alpha * qScaled + M( :, CssIndices ) * yScaled, alpha * qssScaled + Ms( CssIndices, CssIndices ) * yScaled <= omega * ( 1 - z ) ];
            Objective = -alpha;
            Diagnostics = optimize( Constraints, Objective, dynareOBC.MILPOptions );
            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveMILPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end
            yScaled = value( yScaled ) / value( alpha );
        end
        
        if all( isfinite( yScaled ) )
            yScaled = max( 0, yScaled * Norm_q );
            y = ZeroVecS;
            y( CssIndices ) = yScaled;
            w = q + M * y;
            if all( w >= -Tolerance ) && all( abs( w( dynareOBC.sIndices ) .* y ) <= Tolerance )
                return;
            end
        end
        
    end
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
