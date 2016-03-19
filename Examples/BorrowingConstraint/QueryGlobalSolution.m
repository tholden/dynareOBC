function [ Xnew, DXnew, DDXnew ] = QueryGlobalSolution( B, A )
    persistent V X Bv Av beta mu rho sigma Ybar R
    
    if coder.target('MATLAB')
        if isempty( Bv )
            Results = load( 'GlobalResults.mat' );
            V = Results.V;
            X = Results.X;
            Bv = Results.Bv;
            Av = Results.Av;
            beta = Results.beta;
            mu = Results.mu;
            rho = Results.rho;
            sigma = Results.sigma;
            Ybar = Results.Ybar;
            R = Results.R;
        end
    else
        Results = coder.load( 'GlobalResults.mat' );
        V = Results.V;
        X = Results.X;
        Bv = Results.Bv;
        Av = Results.Av;
        beta = Results.beta;
        mu = Results.mu;
        rho = Results.rho;
        sigma = Results.sigma;
        Ybar = Results.Ybar;
        R = Results.R;
    end
    [ ~, Xnew, ~ ] = EvaluateValueFunctionOffGrid( B, A, Bv, Av, V, X, beta, Ybar, R, mu, rho, sigma );
    DXnew = NaN( 2, 1 );
    DDXnew = NaN( 2, 2 );
end
