function [ x, f, PersistentState ] = ACDResumeWrapper( OptiFunction, x, lb, ub, OldPersistentState, varargin )

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

    Radius = 0.3;
    sigma = ( ub - lb ) * Radius;
    sigma( ~isfinite( sigma ) ) = max( Radius, Radius * abs( x( ~isfinite( sigma ) ) ) );
    
    InitialTimeOutLikelihoodEvaluation = Inf;
    
    ProductSearchDimension = max( 1, floor( log( 1 + nw ) / log( 3 ) ) );
    Order = max( 1, ceil( ( -log( 2 ) + log( ( 20 * nw + 1 ) ^ ( 1 / ProductSearchDimension ) + 1 ) ) / log( 2 ) ) );
    
    [ x, f, PersistentState ] = ACDMinimisation( ...
        @( XV, PersistentState, DesiredNumberOfNonTimeouts ) ParallelWrapper( @( X ) OptiFunction( X, PersistentState ), XV, DesiredNumberOfNonTimeouts, InitialTimeOutLikelihoodEvaluation ),...
        x, sigma, eps, lb, ub, [], [], Inf, -Inf, 1, Order, 1, ProductSearchDimension, OldPersistentState, true );
    
    x = max( lb, min( ub, x ) );
    
    f = -f;
    
end

