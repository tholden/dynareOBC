function OpenPool
    global spkronUseMex
    value_spkronUseMex = spkronUseMex;
    WarningState = warning( 'off', 'all' );
    OpenPoolInternal;
    try
        spmd
            InitializeWorkers( value_spkronUseMex );
        end
    catch
    end
    warning( WarningState );
end

function OpenPoolInternal
    global MatlabPoolSize
    try
        GCPStruct = gcp( 'nocreate' );
        if isempty( GCPStruct )
            PreOpen;
            parpool;
        end
        GCPStruct = gcp( 'nocreate' );
        MatlabPoolSize = GCPStruct.NumWorkers;
        GCPStruct.IdleTimeout = Inf;
        return
    catch
    end
    try
        if matlabpool( 'size' ) == 0 %#ok<DPOOL>
            PreOpen;
            matlabpool; %#ok<DPOOL>
        end
        MatlabPoolSize = matlabpool( 'size' ); %#ok<DPOOL>
        return
    catch
    end
    MatlabPoolSize = 0;
end

function InitializeWorkers( value_spkronUseMex )
    global spkronUseMex
    spkronUseMex = value_spkronUseMex;
    warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
    warning( 'off', 'MATLAB:nargchk:deprecated' );
end

function PreOpen
    try
        rmpath( fileparts( which( 'szasbvar' ) ) );
    catch
    end
    try
        distcomp.feature( 'LocalUseMpiexec', false );
    catch
    end
end
