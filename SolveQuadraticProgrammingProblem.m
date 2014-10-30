function [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC_, init_alpha, Homotopy )
% Solves argmin V(SelectIndices)' * alpha + (1/2) * alpha' * MsMatrixSymmetric * alpha such that V + M * alpha >= 0 and alpha >= 0

    % Solve the quadratic optimisation problem

    M = dynareOBC_.MMatrix;
    
    H = dynareOBC_.MsMatrixSymmetric;
    f = V( dynareOBC_.SelectIndices );
    
    if nargin >= 4
        if dynareOBC_.Objective == 1
            fAlt = dynareOBC_.OneVecS;
            HAlt = dynareOBC_.ZeroMatrixS;
        else
            fAlt = dynareOBC_.ZeroVecS;
            HAlt = dynareOBC_.EyeS;
        end
        f = Homotopy * f + ( 1 - Homotopy ) * fAlt;
        H = Homotopy * H + ( 1 - Homotopy ) * HAlt;
    end

    if nargin < 3 && dynareOBC_.UseFICOXpress
        
        init_alpha = [];
        [ alpha, FoundValue, exitflag ] = xprsqp( H, f, -M, V, dynareOBC_.RowType, dynareOBC_.ZeroVecS, [ ], xprsoptimset( dynareOBC_.QuadProgOptions ) );

    else
        
        alpha = [];
    
    end
    if isempty( alpha )
        
        if dynareOBC_.UseFICOXpress
            warning( 'dynareOBC:FicoFallBack', 'Fico express failed, falling back on standard Matlab routines' );
        end

        % Get an initial approximation for alpha to increase the stability and the speed of the computation
        if nargin < 3 || isempty( init_alpha )
            WarningState = warning( 'off', 'all' );
            try
                init_alpha = SolveLinearProgrammingProblem( V, dynareOBC_, dynareOBC_.Algorithm ~= 1, false );
            catch
            end
            warning( WarningState );
        end

        [ alpha, FoundValue, exitflag ] = quadprog( H, f, -M, V, [ ], [ ], dynareOBC_.ZeroVecS, [ ], init_alpha, dynareOBC_.QuadProgOptions );

    end

    if isempty( alpha )
        alpha = init_alpha;
    end
    
    [ alpha, exitflag, ReturnPath ] = PostProcessBoundsProblem( alpha, FoundValue, exitflag, M, V, dynareOBC_, ( nargin == 4 ) && ( Homotopy < 1 ) );
    
end
