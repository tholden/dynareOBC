function y = SolveBoundsProblem( q, dynareOBC )
    Ts = dynareOBC.TimeToEscapeBounds;
    
    Optimizer = dynareOBC.Optimizer;

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
    
    ParametricSolutionFound = dynareOBC.ParametricSolutionFound;
    
    if sum( ParametricSolutionFound ) > 0    
        qsScaled = qScaled( dynareOBC.sIndices );    
        ssIndices = dynareOBC.ssIndices;
    end
    
    if dynareOBC.FullHorizon
        InitTss = Ts;
    else
        InitTss = 1;
    end
    
    for Tss = InitTss : Ts
    
        CParametricSolutionFound = ParametricSolutionFound( Tss );
        
        if CParametricSolutionFound > 0
            
            strTss = int2str( Tss );
            CssIndices = ssIndices{ Tss };
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
