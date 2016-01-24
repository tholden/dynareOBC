function y = SolveBoundsProblem( q )

    global dynareOBC_
    
    Tolerance = dynareOBC_.Tolerance;
    
    if all( q >= -Tolerance ) && ~dynareOBC_.FullHorizon
        y = dynareOBC_.ZeroVecS;
        return
    end
    
    Ts = dynareOBC_.TimeToEscapeBounds;
    Optimizer = dynareOBC_.Optimizer;
    M = dynareOBC_.MMatrix;
    sIndices = dynareOBC_.sIndices;

    Norm_q = norm( q, Inf );
    if Norm_q < Tolerance
        Norm_q = 1;
    end
    qScaled = q ./ Norm_q;
    
    ParametricSolutionFound = dynareOBC_.ParametricSolutionFound;
    
    if sum( ParametricSolutionFound ) > 0    
        qsScaled = qScaled( sIndices );    
        ssIndices = dynareOBC_.ssIndices;
        ZeroVecS = dynareOBC_.ZeroVecS;
    end
    
    if dynareOBC_.FullHorizon
        InitTss = Ts;
    else
        InitTss = 1;
    end
    
    for Tss = InitTss : Ts
    
        CParametricSolutionFound = ParametricSolutionFound( Tss );
        
        if CParametricSolutionFound > 0
            
            CssIndices = ssIndices{ Tss };
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
            y = ZeroVecS;
            y( CssIndices ) = yScaled;
            
        end
        
        if CParametricSolutionFound == 0
            OptOut = Optimizer{ [ qScaled; Tss ] };
            yScaled = OptOut( 1 : ( end - 1 ), : );
            alpha = OptOut( end );
            y = yScaled / alpha;
        end
        
        if all( isfinite( y ) )
            y = max( 0, y * Norm_q );
            w = q + M * y;
            if all( w >= -Tolerance ) && all( abs( w( sIndices ) .* y ) <= Tolerance )
                return;
            end
        end
        
    end
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
