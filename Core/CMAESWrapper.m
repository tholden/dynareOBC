function [ x, f ] = CMAESWrapper( OptiFunction, x, lb, ub, varargin )

    OpenPool;

    try
        pool = gcp;
        nw = pool.NumWorkers;
    catch
        try
            nw = matlabpool( 'size' ); %#ok<DPOOL>
        catch
            nw = 1;
        end
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
    Radius = 0.3;
    sigma = ( ub - lb ) * Radius;
    sigma( ~isfinite( sigma ) ) = max( Radius, Radius * abs( x( ~isfinite( sigma ) ) ) );
    [~,~,~,~,~,best] = CMAESMinimisation( @( XV ) CMAESParallelWrapper( OptiFunction, XV ), x, sigma, cmaesOptions );
    x = max( lb, min( ub, best.x ) );
    f = best.f;
    
end

