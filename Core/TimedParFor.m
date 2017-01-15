function [ Out, RunTimes ] = TimedParFor( Function, Inputs, DefaultOutputs, Wait, DisplayTimeouts )
% Function is called on all of the scalars in Inputs.
% DefaultOutputs should be a cell array with as many elements as Function outputs.
% This function returns within at most Wait seconds.
    if ~iscell( DefaultOutputs )
        DefaultOutputs = { DefaultOutputs };
    end
    NOut = numel( DefaultOutputs );
    Out = cell( size( DefaultOutputs ) );
    UniformOutput = false( size( DefaultOutputs ) );
    for j = 1 : NOut
        if numel( DefaultOutputs{ j } ) == 1
            UniformOutput( j ) = true;
            Out{ j } = ones( size( Inputs ) ) * DefaultOutputs{ j };
        else
            Out{ j } = repmat( DefaultOutputs( j ), size( Inputs ) );
        end
    end
    NIn = numel( Inputs );
    f( NIn ) = parallel.FevalFuture;
    RunTimes = NaN( size( Inputs ) );
    
    try
        OpenPool;
        StoreGlobals;
        
        for i = 1 : NIn
            f( i ) = parfeval( @( in ) TimedWrapper( in, Function, NOut ), 2, Inputs( i ) );
        end
        wait( f, 'finished', Wait );
        for i = 1 : NIn
            Diary = f( i ).Diary;
            if ~isempty( Diary )
                fprintf( 'Output from problem %g:\n%s', Inputs( i ), Diary );
            end
            cancel( f( i ) );
            Error = f( i ).Error;
            if isempty( Error )
                [ TmpOut, TmpTime ] = fetchOutputs( f( i ) );
                for j = 1 : NOut
                    if UniformOutput( j )
                        Out{ j }( i ) = TmpOut{ j };
                    else
                        Out{ j }( i ) = TmpOut( j );
                    end
                end
                RunTimes( i ) = TmpTime;
            elseif DisplayTimeouts || ~( strcmp( Error.identifier, 'parallel:fevalqueue:ExecutionCancelled' ) || strcmp( Error.identifier, 'parallel:fevalqueue:NoResourcesForQueue' ) || strcmp( Error.identifier, 'parallel:fevalqueue:NoResultAvailable' ) )
                fprintf( 'Error from problem %g:\n', Inputs( i ) );
                DisplayError( Error );
            end
        end
    catch Error
        cancel( f );
        DisplayError( Error );
        try
            delete( gcp( 'nocreate' ) );
        catch
        end
        fprintf( 'Retrying iteration.\n' );
        [ Out, RunTimes ] = TimedParFor( Function, Inputs, DefaultOutputs, Wait, DisplayTimeouts );
    end

end

function [ out, time ] = TimedWrapper( in, Function, NOut )
    start = tic;
    out = cell( NOut, 1 );
    [out{:}] = Function( in );
    time = toc( start );
end
