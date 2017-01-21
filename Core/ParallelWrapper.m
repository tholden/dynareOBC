function [ RV, BestPersistentState ] = ParallelWrapper( objective_function, XV, DesiredNumberOfNonTimeouts, InitialTimeOut, varargin )
    persistent BestRunTime MaxRunTime XStore LogLObsStore
    
    D = size( XV, 1 );
    N = size( XV, 2 );
    
    if isempty( BestRunTime ) || isempty( MaxRunTime )
        Timeout = InitialTimeOut;
    else
        CurrentPool = gcp;
        TargetScale = DesiredNumberOfNonTimeouts ./ CurrentPool.NumWorkers;
        Timeout = max( BestRunTime * ( TargetScale + 2 ), MaxRunTime * ( TargetScale + 1 ) );
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
    
    fprintf( 'Using timeout: %g\n', Timeout );
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
        NewMaxRunTime = max( RunTimes );
        NewBestRunTime = RunTimes( 1 );
        
        if isempty( MaxRunTime )
            MaxRunTime = NewMaxRunTime;
        else
            MaxRunTime = 0.95 * MaxRunTime + 0.05 * max( MaxRunTime * 0.8, NewMaxRunTime );
        end
        if isempty( BestRunTime )
            BestRunTime = NewBestRunTime;
        else
            BestRunTime = 0.95 * BestRunTime + 0.05 * max( BestRunTime * 0.8, NewBestRunTime );
        end
        
        BestPersistentState = BestPersistentStates{ sIndices( 1 ) };
    end
end
