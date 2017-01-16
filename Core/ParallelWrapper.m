function [ RV, BestPersistentState ] = ParallelWrapper( objective_function, XV, DesiredNumberOfNonTimeouts, InitialTimeOutLikelihoodEvaluation, varargin )
    persistent Timeout XStore LogLObsStore
    
    D = size( XV, 1 );
    N = size( XV, 2 );
    
    if isfinite( InitialTimeOutLikelihoodEvaluation )
        if isempty( Timeout )
            CTimeout = InitialTimeOutLikelihoodEvaluation;
            fprintf( 'Initial timeout: %g\n', CTimeout );
        else
            CTimeout = Timeout;
        end
    else
        CTimeout = Inf;
    end
    
    if isempty( XStore ) || isempty( LogLObsStore )
        if exist( 'ValueStore.mat', 'file' )
            ValueStore = load( 'ValueStore.mat' );
            XStore = ValueStore.XStore;
            LogLObsStore = ValueStore.LogLObsStore;
        else
            XStore = zeros( D - 1, 0 );
            LogLObsStore = cell( 0, 0 );
        end
    end
    
    [ TPVOut, RunTimes ] = TimedParFor( @( i ) objective_function( XV( :, i ), varargin{:} ), 1:N, { -Inf, [], [] }, CTimeout, false );
    RV = - TPVOut{ 1 };
    BestPersistentStates = TPVOut{ 2 };
    LogLObsV = TPVOut{ 3 };
    
    BestPersistentState = [];
    
    oIndices = isfinite( RV ) & isfinite( RunTimes ) & ~cellfun( @isempty, LogLObsV );
    
    XStore = [ XStore XV( :, oIndices ) ];
    LogLObsStore = [ LogLObsStore LogLObsV( oIndices ) ];
    save( 'ValueStore.mat', 'XStore', 'OriginalXStore', 'LogLObsStore' );
    
    sRV = RV( oIndices );
    RunTimes = RunTimes( oIndices );
    BestPersistentStates = BestPersistentStates( oIndices );
    if ~isempty( sRV )
        [ ~, sIndices ] = sort( sRV );
        if length( sIndices ) >= DesiredNumberOfNonTimeouts
            sIndices = sIndices( 1:DesiredNumberOfNonTimeouts );
        else
            fprintf( 'Timeout appears to be too low. You may wish to modify the logic in ParallelWrapper.m.\nDesired %d, received %d.\n', DesiredNumberOfNonTimeouts, length( sIndices ) );
        end
        RunTimes = RunTimes( sIndices );
        MaxRunTime = max( RunTimes );
        BestRunTime = RunTimes( 1 );
        
        CurrentPool = gcp;
        TargetScale = DesiredNumberOfNonTimeouts ./ CurrentPool.NumWorkers;
        TimeoutTarget = max( BestRunTime * ( TargetScale + 1 ), MaxRunTime * TargetScale );
        if isempty( Timeout )
            Timeout = TimeoutTarget;
        else
            Timeout = 0.95 * Timeout + 0.05 * max( Timeout * 0.8, TimeoutTarget );
        end
        
        BestPersistentState = BestPersistentStates{ sIndices( 1 ) };
    end
    fprintf( 'New timeout: %g\n', Timeout );
end
