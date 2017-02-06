function [ x, f, PersistentState ] = PACDWrapper( OptiFunction, x, lb, ub, OldPersistentState, varargin )

    OpenPool;

    InitialTimeOutLikelihoodEvaluation = Inf;
    
    [ x, f, PersistentState ] = PACDMinimisation( ...
        @( XV, PersistentState, DesiredNumberOfNonTimeouts ) ParallelWrapper( @( X ) OptiFunction( X, PersistentState ), XV, DesiredNumberOfNonTimeouts, InitialTimeOutLikelihoodEvaluation ),...
        x, lb, ub, [], [], OldPersistentState, false );
    
    x = max( lb, min( ub, x ) );
    
    f = -f;
    
end

