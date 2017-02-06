function [ x, f, PersistentState ] = PACDResumeWrapper( OptiFunction, x, lb, ub, OldPersistentState, varargin )

    OpenPool;

    InitialTimeOutLikelihoodEvaluation = Inf;
    
    [ x, f, PersistentState ] = PACDMinimisation( ...
        @( XV, PersistentState, DesiredNumberOfNonTimeouts ) ParallelWrapper( @( X ) OptiFunction( X, PersistentState ), XV, DesiredNumberOfNonTimeouts, InitialTimeOutLikelihoodEvaluation ),...
        x, lb, ub, [], [], OldPersistentState, true );
    
    x = max( lb, min( ub, x ) );
    
    f = -f;
    
end

