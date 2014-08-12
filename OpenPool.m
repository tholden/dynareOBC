function OpenPool
    global spkron_use_mex
    value_spkron_use_mex = spkron_use_mex;
    OpenPoolInternal;
    try
        spmd
            SetSPKronUseMex( value_spkron_use_mex );
        end
    catch
    end
end

function OpenPoolInternal
    global MatlabPoolSize
    try
        GCPStruct = gcp( 'nocreate' );
        if isempty( GCPStruct )
            parpool;
        end
        GCPStruct = gcp( 'nocreate' );
        MatlabPoolSize = GCPStruct.NumWorkers;
        return
    catch
    end
    try
        if matlabpool('size') == 0 %#ok<DPOOL>
            matlabpool; %#ok<DPOOL>
        end
        MatlabPoolSize = matlabpool('size'); %#ok<DPOOL>
        return
    catch
    end
    try
        matlabpool; %#ok<DPOOL> Really old Matlab don't have matlabpool('size')...
        spmd
            InternalMatlabPoolSize = numlabs;
        end
        MatlabPoolSize = InternalMatlabPoolSize{1};
        return
    catch
    end
    MatlabPoolSize = 0;
end

function SetSPKronUseMex( value_spkron_use_mex )
    global spkron_use_mex
    spkron_use_mex = value_spkron_use_mex;
end
