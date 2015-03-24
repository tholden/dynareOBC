function [ alpha, exitflag, ReturnPath ] = SolveQCQPProblem( V, dynareOBC )
% Solves argmin [ OneVecS' * alpha | alpha' * alpha ] such that 0 = V(SelectIndices)' * alpha + (1/2) * alpha' * MsMatrixSymmetric * alpha, V + M alpha >= 0 and alpha >= 0

    % Solve the quadratic optimisation problem

    M = dynareOBC.MMatrix;
    
    Hcon = dynareOBC.MsMatrixSymmetric;
    fcon = V( dynareOBC.SelectIndices );
    
    if dynareOBC.Objective == 1
        f = dynareOBC.OneVecS;
        H = dynareOBC.ZeroMatrixS;
    else
        f = dynareOBC.ZeroVecS;
        H = dynareOBC.EyeS;
    end
    
    if dynareOBC.UseFICOXpress
        
        T = dynareOBC.InternalIRFPeriods;
        ns = dynareOBC.NumberOfMax;
    
        Q = cell( T * ns + 1, 1 );
        Q{ end } = Hcon;
        [ alpha, FoundValue, exitflag ] = xprsqcqp( H, f, [ -M; fcon' ], Q, [ V; 0 ], [ dynareOBC.RowType 'L' ], dynareOBC.ZeroVecS, [ ], xprsoptimset( dynareOBC.FMinConOptions ) );

    else
        
        alpha = [];
    
    end
    if isempty( alpha )

        if dynareOBC.UseFICOXpress
            warning( 'dynareOBC:FicoFallBack', 'Fico express failed, falling back on standard Matlab routines' );
        end

        % Get an initial approximation for alpha to increase the stability and the speed of the computation
        init_alpha = SolveQuadraticProgrammingProblem( V, dynareOBC );

        [ alpha, FoundValue, exitflag ] = fmincon( @(x) QuadraticObjectiveFunction( x, f, H ), init_alpha, -M, V, [ ], [ ], dynareOBC.ZeroVecS, [ ], ....
            @(x) QuadraticEqualityConstraintFunction( x, fcon, Hcon ), optimset( dynareOBC.FMinConOptions, 'HessFcn', @(varargin) H ) );

    end
    
    [ alpha, exitflag, ReturnPath ] = PostProcessBoundsProblem( alpha, FoundValue, exitflag, M, V, dynareOBC, false );
    
end
