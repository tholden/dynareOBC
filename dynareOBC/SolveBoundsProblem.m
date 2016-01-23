function y = SolveBoundsProblem( q, dynareOBC )

    Tolerance = dynareOBC.Tolerance;
    
    if all( q >= -Tolerance ) && ~dynareOBC.FullHorizon
        y = dynareOBC.ZeroVecS;
        return
    end
    
    Ts = dynareOBC.TimeToEscapeBounds;
    Optimizer = dynareOBC.Optimizer;
    M = dynareOBC.MMatrix;
    ZeroVecS = dynareOBC.ZeroVecS;
    sIndices = dynareOBC.sIndices;
    ssIndices = dynareOBC.ssIndices;

    Norm_q = norm( q, Inf );
    if Norm_q < Tolerance
        Norm_q = 1;
    end
    qScaled = q ./ Norm_q;
    
    ParametricSolutionFound = dynareOBC.ParametricSolutionFound;
    
    if sum( ParametricSolutionFound ) > 0    
        qsScaled = qScaled( sIndices );    
    end
    
    if dynareOBC.FullHorizon
        InitTss = Ts;
    else
        InitTss = 1;
    end
    
    for Tss = InitTss : Ts
    
        CParametricSolutionFound = ParametricSolutionFound( Tss );
        CssIndices = ssIndices{ Tss };
        
        if CParametricSolutionFound > 0
            
            strTss = int2str( Tss );
            qssScaled = qsScaled( CssIndices );
            
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
            OptOut = Optimizer{ [ qScaled; Tss ] };
            yScaled = OptOut( 1 : ( end - 1 ), : );
            alpha = OptOut( end );
            yScaled = yScaled / alpha;
        end
        
        if all( isfinite( yScaled ) )
            yScaled = max( 0, yScaled * Norm_q );
            y = ZeroVecS;
            y( CssIndices ) = yScaled;
            w = q + M * y;
            if all( w >= -Tolerance ) && all( abs( w( sIndices ) .* y ) <= Tolerance )
                return;
            end
        end
        
    end
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
