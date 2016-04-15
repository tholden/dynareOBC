function [ x, f ] = CMAESWrapper( OptiFunction, x, lb, ub, varargin )
    try
        pool = gcp;
        nw = pool.NumWorkers;
    catch
        nw = 1;
    end
    cmaesOptions = cmaes;
    cmaesOptions.EvalParallel = 1;
    cmaesOptions.PopSize = [ 'max( ' int2str( nw ) ', (4 + floor(3*log(N))) )' ];
    cmaesOptions.LBounds = lb;
    cmaesOptions.UBounds = ub;
    cmaesOptions.CMA.active = 1;
    for i = 1 : 2 : length( varargin )
        cmaesOptions.( varargin{ i } ) = varargin{ i + 1 };
    end
    sigma = ( ub - lb ) * 0.2;
    sigma( ~isfinite( sigma ) ) = 0.2;
    [~,~,~,~,~,best] = CMAES( @( XV ) CMAESParallelWrapper( OptiFunction, XV ), x, sigma, cmaesOptions );
    x = max( lb, min( ub, best.x ) );
    f = best.f;
end

