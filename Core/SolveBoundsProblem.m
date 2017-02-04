function y = SolveBoundsProblem( q )

    global dynareOBC_
    
    Tolerance = dynareOBC_.Tolerance;
    SkipFirstSolutions = dynareOBC_.SkipFirstSolutions;
    
    FullHorizon = dynareOBC_.FullHorizon;
    ReverseSearch = dynareOBC_.ReverseSearch;
    DisplayBoundsSolutionProgress = dynareOBC_.DisplayBoundsSolutionProgress;
    ZeroVecS = dynareOBC_.ZeroVecS;
    
    ySaved = [];
    
    Norm_q = norm( q, Inf );
    if Norm_q < Tolerance
        Norm_q = 1;
    end
    qScaled = q ./ Norm_q;
    
    if ~FullHorizon && ~ReverseSearch
    
        if DisplayBoundsSolutionProgress
            disp( 0 );
        end

        if all( qScaled >= -Tolerance )
            y = ZeroVecS;
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
    
    ParametricSolutionHorizon = dynareOBC_.ParametricSolutionHorizon;
    ParametricSolutionMode = dynareOBC_.ParametricSolutionMode;

    d1SubMMatrices = dynareOBC_.d1SubMMatrices;
    d1sSubMMatrices = dynareOBC_.d1sSubMMatrices;
    d2SubMMatrices = dynareOBC_.d2SubMMatrices;
    NormalizedSubMsMatrices = dynareOBC_.NormalizedSubMsMatrices;
    
    LargestPMatrix = dynareOBC_.LargestPMatrix;
    
    PMatrixSolutionOK = true;
    if ~FullHorizon && ~ReverseSearch && LargestPMatrix > 0 && isempty( ySaved )
        
        if ParametricSolutionHorizon > 0
            
            d1s = d1sSubMMatrices{ ParametricSolutionHorizon };
            d2 = d2SubMMatrices{ ParametricSolutionHorizon };
            
            CssIndices = ssIndices{ ParametricSolutionHorizon };
            qnssScaled = d1s .* qScaled( sIndices( CssIndices ) );
            
            try
                if ParametricSolutionMode > 1
                    yScaled = feval( 'dynareOBCTempSolution_mex', qnssScaled );
                else
                    yScaled = feval( 'dynareOBCTempSolution', qnssScaled );
                end
            catch Error
				warning( 'dynareOBC:ParametricEvaluationError', [ 'Error running the parametric solution: ' Error.message ] );
                PMatrixSolutionOK = false;
            end
            if numel( yScaled ) ~= numel( qnssScaled )
				warning( 'dynareOBC:ParametricEvaluationUnexpectedOutputSize', 'Unexpected output size returned from the parametric solution.' );
                PMatrixSolutionOK = false;
            end
			if PMatrixSolutionOK
				y = ZeroVecS;
				y( CssIndices ) = d2 .* max( 0, yScaled );
                
                w = qScaled + M * y;
                
                if all( w >= -Tolerance ) && all( min( w( sIndices ), y ) <= Tolerance )
                    y = y * Norm_q;
                    if DisplayBoundsSolutionProgress
                        disp( full( y ) );
                    end
                    if SkipFirstSolutions > 0
                        ySaved = y;
                        SkipFirstSolutions = SkipFirstSolutions - 1;
                    else
                        return;
                    end
                else
                    PMatrixSolutionOK = false;
                end
			end

        end
        
        if ~PMatrixSolutionOK
            d1s = d1sSubMMatrices{ LargestPMatrix };
            d2 = d2SubMMatrices{ LargestPMatrix };

            Mns = NormalizedSubMsMatrices{ LargestPMatrix };

            CssIndices = ssIndices{ LargestPMatrix };
            qnssScaled = d1s .* qScaled( sIndices( CssIndices ) );

            try
                [ yScaled, ~, ~, ExitFlag ] = lcp( Mns, qnssScaled, dynareOBC_.LemkeLCPOptions );
                PMatrixSolutionOK = ExitFlag > 0;
            catch Error
                warning( 'dynareOBC:LemkeLCPError', [ 'Error running the Lemke LCP algorithm: ' Error.message ] );
                PMatrixSolutionOK = false;
            end
            if PMatrixSolutionOK
                y = ZeroVecS;
                y( CssIndices ) = d2 .* max( 0, yScaled );

                w = qScaled + M * y;

                if all( w >= -Tolerance ) && all( min( w( sIndices ), y ) <= Tolerance )
                    y = y * Norm_q;
                    if DisplayBoundsSolutionProgress
                        disp( full( y ) );
                    end
                    if SkipFirstSolutions > 0
                        ySaved = y;
                        SkipFirstSolutions = SkipFirstSolutions - 1;
                    else
                        return;
                    end
                else
                    PMatrixSolutionOK = false;
                end
            end
        end
        
    end
	
    if ReverseSearch
        PMatrixSolutionOK = false;
    end
    
    if FullHorizon
        InitTss = Ts;
    else
        InitTss = LargestPMatrix + PMatrixSolutionOK;
    end
    
    if ReverseSearch
        TssSet = Ts : -1 : InitTss;
    else
        TssSet = InitTss : Ts;
    end
    
    for Tss = TssSet
    
        if DisplayBoundsSolutionProgress
            disp( Tss );
        end
    
        CssIndices = ssIndices{ Tss };
        
        d1 = d1SubMMatrices{ Tss };
        d2 = d2SubMMatrices{ Tss };

        qnScaled = d1 .* qScaled;

        OptOut = Optimizer{ Tss }{ qnScaled };
        yScaled = OptOut( 1 : ( end - 1 ), : );
        alpha = max( eps, OptOut( end ) );
        y = ZeroVecS;
        y( CssIndices ) = yScaled / alpha;

        if all( isfinite( y ) )
            y = d2 .* max( 0, y );
            w = qScaled + M * y;
            if all( w >= -Tolerance ) && all( min( w( sIndices ), y ) <= Tolerance )
                y = y * Norm_q;
                if ~isempty( ySaved ) && max( abs( y - ySaved ) ) <= Tolerance
                    continue;
                end
                if DisplayBoundsSolutionProgress
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
    
    if ~FullHorizon && ReverseSearch
        
        if DisplayBoundsSolutionProgress
            disp( 0 );
        end

        if all( qScaled >= -Tolerance )
            y = ZeroVecS;
            return;
        end
    
    end
    
    if ~isempty( ySaved )
        y = ySaved;
        return;
    end
    
    error( 'dynareOBC:InfeasibleProblem', 'Impossible problem encountered. Try increasing TimeToEscapeBounds, or reducing the magnitude of shocks.' );
    
end
