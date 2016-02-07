function [ Cnew, DCnew, DDCnew ] = QueryGlobalSolution( k, a )
    persistent kv av V CB alpha beta nu theta rho sigma;
    if isempty( kv )
        Results = load( 'GlobalResults.mat' );
        kv = Results.kv;
        av = Results.av;
        V = Results.V;
        CB = Results.CB;
        alpha = Results.alpha;
        beta = Results.beta;
        nu = Results.nu;
        theta = Results.theta;
        rho = Results.rho;
        sigma = Results.sigma;
    end
    [ ~, Cnew, ~ ] = EvaluateValueFunctionOffGrid_mex( k, a, kv, av, V, CB, alpha, beta, nu, theta, rho, sigma );
    DCnew = NaN( 2, 1 );
    DDCnew = NaN( 2, 2 );
end
