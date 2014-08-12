function [ alpha, exitflag ] = SolveQCQPProblem( V, dynareOBC_ )
% Solves argmin [ OneVecS' * alpha | alpha' * alpha ] such that 0 = V(SelectIndices)' * alpha + (1/2) * alpha' * MsMatrixSymmetric * alpha, V + M alpha >= 0 and alpha >= 0

    % Solve the quadratic optimisation problem

    M = dynareOBC_.MMatrix;
    
    Hcon = dynareOBC_.MsMatrixSymmetric;
    fcon = V( dynareOBC_.SelectIndices );
    
    if dynareOBC_.Objective == 1
        f = dynareOBC_.OneVecS;
        H = dynareOBC_.ZeroMatrixS;
    else
        f = dynareOBC_.ZeroVecS;
        H = dynareOBC_.EyeS;
    end
    
    if dynareOBC_.UseFICOXpress
        
        T = dynareOBC_.InternalIRFPeriods;
        ns = dynareOBC_.NumberOfMax;
    
        Q = cell( T * ns + 1, 1 );
        Q{ end } = Hcon;
        [ alpha, FoundValue, exitflag ] = xprsqcqp( H, f, [ -M; fcon' ], Q, [ V; 0 ], [ dynareOBC_.RowType 'L' ], dynareOBC_.ZeroVecS, [ ], xprsoptimset( dynareOBC_.FMinConOptions ) );

    else
        
        alpha = [];
    
    end
    if isempty( alpha )

        if dynareOBC_.UseFICOXpress
            warning( 'dynareOBC:FicoFallBack', 'Fico express failed, falling back on standard Matlab routines' );
        end

        % Get an initial approximation for alpha to increase the stability and the speed of the computation
        init_alpha = SolveQuadraticProgrammingProblem( V, dynareOBC_ );

        [ alpha, FoundValue, exitflag ] = fmincon( @(x) QuadraticObjectiveFunction( x, f, H ), init_alpha, -M, V, [ ], [ ], dynareOBC_.ZeroVecS, [ ], ....
            @(x) QuadraticEqualityConstraintFunction( x, fcon, Hcon ), optimset( dynareOBC_.FMinConOptions, 'HessFcn', @(varargin) H ) );

    end
    
    [ alpha, exitflag ] = PostProcessBoundsProblem( alpha, FoundValue, exitflag, M, V, dynareOBC_, false );
    
end
