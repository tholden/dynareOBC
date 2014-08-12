function [ alpha, exitflag ] = SolveBoundsProblem( V, dynareOBC_ )
    if all( V >= - dynareOBC_.Tolerance )
        alpha = dynareOBC_.ZeroVecS;
        exitflag = 1;
        return
    end
    switch dynareOBC_.Algorithm
        case 2
            [ alpha, exitflag ] = SolveHomotopyProblem( V, dynareOBC_ );
        case 3
            [ alpha, exitflag ] = SolveQCQPProblem( V, dynareOBC_ );
        otherwise
            [ alpha, exitflag ] = SolveQuadraticProgrammingProblem( V, dynareOBC_ );
    end
end
