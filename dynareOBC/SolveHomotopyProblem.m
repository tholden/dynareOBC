function [ alpha, exitflag, ReturnPath ] = SolveHomotopyProblem( V, dynareOBC )
% Approximately solves argmin [ OneVecS' * alpha | alpha' * alpha ] such that 0 = V(SelectIndices)' * alpha + (1/2) * alpha' * MsMatrixSymmetric * alpha, V + M alpha >= 0 and alpha >= 0

    alpha = SolveLinearProgrammingProblem( V, dynareOBC, true, false );
       
    iMax = dynareOBC.HomotopySteps - 1;
    
    for i = 0 : iMax
        [ new_alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC, alpha, i / iMax );
        if exitflag >= 0
            alpha = new_alpha;
        end
    end
    
end
