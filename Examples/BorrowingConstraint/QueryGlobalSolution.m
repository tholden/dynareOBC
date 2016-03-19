function [ Xnew, DXnew, DDXnew ] = QueryGlobalSolution( B, A )
    persistent V X Bv Av beta mu rho sigma Ybar R PP
    
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
            PP = Results.PP;
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
        PP = Results.PP;
    end
    [ ~, Xnew, ~ ] = EvaluateValueFunctionOffGrid( B, A, Bv, Av, PP, max( max( V ) ), X, beta, Ybar, R, mu, rho, sigma );
    DXnew = NaN( 2, 1 );
    DDXnew = NaN( 2, 2 );
end
