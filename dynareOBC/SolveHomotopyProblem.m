function [ alpha, exitflag, ReturnPath ] = SolveHomotopyProblem( V, dynareOBC_ )
% Approximately solves argmin [ OneVecS' * alpha | alpha' * alpha ] such that 0 = V(SelectIndices)' * alpha + (1/2) * alpha' * MsMatrixSymmetric * alpha, V + M alpha >= 0 and alpha >= 0

    alpha = SolveLinearProgrammingProblem( V, dynareOBC_, true, false );
       
    iMax = dynareOBC_.HomotopySteps - 1;
    
    for i = 0 : iMax
        [ new_alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC_, alpha, i / iMax );
        if exitflag >= 0
            alpha = new_alpha;
        end
    end
    
end
