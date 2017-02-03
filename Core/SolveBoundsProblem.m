function y = SolveBoundsProblem( q )

    global dynareOBC_
    
    Tolerance = dynareOBC_.Tolerance;
    SkipFirstSolutions = dynareOBC_.SkipFirstSolutions;
    
    ySaved = [];
    
    Norm_q = norm( q, Inf );
    if Norm_q < Tolerance
        Norm_q = 1;
    end
    qScaled = q ./ Norm_q;
    
    if ~dynareOBC_.FullHorizon && ~dynareOBC_.ReverseSearch
    
        if dynareOBC_.DisplayBoundsSolutionProgress
            disp( 0 );
        end

        if all( qScaled >= -Tolerance )
            y = dynareOBC_.ZeroVecS;
            if SkipFirstSolutions > 0
                ySaved = y;
                SkipFirstSolutions = SkipFirstSolutions - 1;
            else
                return;
            end
        end
    
    end
    
    Ts = dynareOBC_.TimeToEscapeBounds;
    Optimizer = dynareOBC_.Optimizer;
    M = dynareOBC_.MMatrix;
    sIndices = dynareOBC_.sIndices;

    ssIndices = dynareOBC_.ssIndices;
    ZeroVecS = dynareOBC_.ZeroVecS;
    
    d1sSubMMatrices = dynareOBC_.d1sSubMMatrices;
    d2SubMMatrices = dynareOBC_.d2SubMMatrices;
    
    if dynareOBC_.FullHorizon
        InitTss = Ts;
    else
        InitTss = dynareOBC_.LargestPMatrix + 1;
    end
    
    if dynareOBC_.ReverseSearch
        TssSet = Ts : -1 : InitTss;
    else
        TssSet = InitTss : Ts;
    end
    
    
    if ~dynareOBC_.FullHorizon && ~dynareOBC_.ReverseSearch && dynareOBC_.LargestPMatrix > 0
        
        ParametricSolutionHorizon = dynareOBC_.ParametricSolutionHorizon;
        
        if ParametricSolutionHorizon > 0
            
            d1s = d1sSubMMatrices{ ParametricSolutionHorizon };
            d2 = d2SubMMatrices{ ParametricSolutionHorizon };
            
            CssIndices = ssIndices{ ParametricSolutionHorizon };
            qnssScaled = d1s .* qScaled( sIndices( CssIndices ) );
            
            try
                if dynareOBC_.ParametricSolutionMode > 1
                    yScaled = feval( 'dynareOBCTempSolution_mex', qnssScaled );
                else
                    yScaled = feval( 'dynareOBCTempSolution', qnssScaled );
                end
            catch
                ParametricSolutionHorizon = 0;
            end
            if numel( yScaled ) ~= numel( qnssScaled )
                ParametricSolutionHorizon = 0;
            end
			if ParametricSolutionHorizon == 0
				warning( 'dynareOBC:ParametricEvaluationProblem', 'Problem running the parametric solution.' );
			else
				y = ZeroVecS;
				y( CssIndices ) = d2 .* max( 0, yScaled );
                
                w = qScaled + M * y; % TODO: compare with normalized M?
                
                if all( w >= -Tolerance ) && all( min( w( sIndices ), y ) <= Tolerance )
                    y = y * Norm_q;
                    if ~isempty( ySaved ) && max( abs( y - ySaved ) ) <= Tolerance
                        error( 'TODO' );
                    end
                    if dynareOBC_.DisplayBoundsSolutionProgress
                        disp( full( y ) );
                    end
                    if SkipFirstSolutions > 0
                        ySaved = y;
                        SkipFirstSolutions = SkipFirstSolutions - 1;
                    else
                        return;
                    end
                end
			end

        end
        
    end
	
    for Tss = TssSet
    
        if dynareOBC_.DisplayBoundsSolutionProgress
            disp( Tss );
        end
    
        ParametricSolutionHorizon = ParametricSolutionFound( Tss );
        CssIndices = ssIndices{ Tss };
        
        if ParametricSolutionHorizon == 0
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
                if ~isempty( ySaved ) && max( abs( y - ySaved ) ) <= Tolerance
                    continue;
                end
                if dynareOBC_.DisplayBoundsSolutionProgress
                    disp( full( y ) );
                end
                if SkipFirstSolutions > 0
                    ySaved = y;
                    SkipFirstSolutions = SkipFirstSolutions - 1;
                else
                    return;
                end
            end
        end
        
    end
    
    if ~dynareOBC_.FullHorizon && dynareOBC_.ReverseSearch
        
        if dynareOBC_.LargestPMatrix > 0
            error( 'TODO' );
        end
    
        if dynareOBC_.DisplayBoundsSolutionProgress
            disp( 0 );
        end

        if all( q >= -Tolerance )
            y = dynareOBC_.ZeroVecS;
            return;
        end
    
    end
    
    if ~isempty( ySaved )
        y = ySaved;
        return;
    end
    
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
