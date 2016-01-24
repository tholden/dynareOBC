function StoreGlobals( M, options, oo, dynareOBC )
    InitializeWorkers( M, options, oo, dynareOBC );
    OpenPool;
    WarningState = warning( 'off', 'all' );
    try
        spmd
            InitializeWorkers( M, options, oo, dynareOBC );
        end
    catch
    end
    warning( WarningState );
end

function InitializeWorkers( M, options, oo, dynareOBC )
    global M_ options_ oo_ dynareOBC_
    M_ = M;
    options_ = options;
    oo_ = oo;
    dynareOBC_ = dynareOBC;
end
