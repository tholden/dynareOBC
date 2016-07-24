function y = SolveBoundsProblem( q )

    global dynareOBC_
    
    Tolerance = dynareOBC_.Tolerance;
    
    if ~dynareOBC_.FullHorizon && ~dynareOBC_.ReverseSearch
    
        if dynareOBC_.DisplayBoundsSolutionProgress
            disp( 0 );
        end

        if all( q >= -Tolerance )
            y = dynareOBC_.ZeroVecS;
            return
        end
    
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
    end
    ssIndices = dynareOBC_.ssIndices;
    ZeroVecS = dynareOBC_.ZeroVecS;
    
    if dynareOBC_.FullHorizon
        InitTss = Ts;
    else
        InitTss = 1;
    end
    
    if dynareOBC_.ReverseSearch
        TssSet = Ts : -1 : InitTss;
    else
        TssSet = InitTss : Ts;
    end
    
    for Tss = TssSet
    
        if dynareOBC_.DisplayBoundsSolutionProgress
            disp( Tss );
        end
    
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
                CParametricSolutionFound = 0;
            end
            if numel( yScaled ) ~= numel( CssIndices )
                CParametricSolutionFound = 0;
            end
			if CParametricSolutionFound == 0
				warning( 'dynareOBC:ParametricEvaluationProblem', 'Problem running the parametric solution.' );
			else
				y = ZeroVecS;
				y( CssIndices ) = yScaled;
			end
            
        end
        
        if CParametricSolutionFound == 0
            OptOut = Optimizer{ Tss }{ qScaled };
            yScaled = OptOut( 1 : ( end - 1 ), : );
            alpha = max( eps, OptOut( end ) );
            y = ZeroVecS;
            y( CssIndices ) = yScaled / alpha;
        end
        
        if all( isfinite( y ) )
            y = max( 0, y );
            w = qScaled + M * y;
            if all( w >= -Tolerance ) && all( min( w( sIndices ), y ) <= Tolerance )
                y = y * Norm_q;
                if dynareOBC_.DisplayBoundsSolutionProgress
                    disp( full( y ) );
                end
                return;
            end
        end
        
    end
    
    if ~dynareOBC_.FullHorizon && dynareOBC_.ReverseSearch
    
        if dynareOBC_.DisplayBoundsSolutionProgress
            disp( 0 );
        end

        if all( q >= -Tolerance )
            y = dynareOBC_.ZeroVecS;
            return
        end
    
    end
    
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
