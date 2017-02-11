function [ x, f, PersistentState ] = CMAESResumeWrapper( OptiFunction, x, lb, ub, OldPersistentState, varargin )

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

    if isempty( OldPersistentState ) && exist( 'variablescmaes.mat', 'file' )
        LoadedVariablesCMAES = load( 'variablescmaes.mat' );
        OldPersistentState = LoadedVariablesCMAES.PersistentState;
    end

    cmaesOptions = cmaes;
    cmaesOptions.ResumeRun = true;
    cmaesOptions.PopSize = [ '(' int2str( nw ) '*ceil((4 + floor(3*log(N)))/' int2str( nw ) '))' ];
    cmaesOptions.DiagonalOnly = '(1+N)^2/lambda';
    cmaesOptions.Seed = randi( intmax, 'int32' );
    cmaesOptions.LBounds = lb;
    cmaesOptions.UBounds = ub;
    cmaesOptions.CMA.active = true;
    cmaesOptions.ExtraEvalScale = 20;
    cmaesOptions.StopOnStagnation = false;
    
    cmaesOptions.AlwaysAroundBest = false;
    
    for i = 1 : 2 : length( varargin )
        cmaesOptions.( varargin{ i } ) = varargin{ i + 1 };
    end
    
    Radius = 0.3;
    sigma = ( ub - lb ) * Radius;
    sigma( ~isfinite( sigma ) ) = max( Radius, Radius * abs( x( ~isfinite( sigma ) ) ) );
    
    InitialTimeOutLikelihoodEvaluation = 200;
    
    [~,~,~,~,~,best] = CMAESMinimisation( ...
        @( XV, PersistentState, DesiredNumberOfNonTimeouts ) ParallelWrapper( @( X ) OptiFunction( X, PersistentState ), XV, DesiredNumberOfNonTimeouts, InitialTimeOutLikelihoodEvaluation ),...
        x, sigma, OldPersistentState, cmaesOptions );
    
    x = max( lb, min( ub, best.x ) );
    f = -best.f;
    PersistentState = best.PersistentState;
    
end
