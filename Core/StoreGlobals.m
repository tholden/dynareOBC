function StoreGlobals( M, options, oo, dynareOBC )
    InitializeWorkers( M, options, oo, dynareOBC );
    try
        if ~isempty( gcp( 'nocreate' ) )
            WarningState = warning( 'off', 'all' );
            try
                spmd
                    InitializeWorkers( M, options, oo, dynareOBC );
                end
            catch
            end
            warning( WarningState );
        end
        return;
    catch
    end
    try
        if matlabpool( 'size' ) ~= 0 %#ok<DPOOL>
            WarningState = warning( 'off', 'all' );
            try
                spmd
                    InitializeWorkers( M, options, oo, dynareOBC );
                end
            catch
            end
            warning( WarningState );
        end
        return;
    catch
    end
end

function InitializeWorkers( M, options, oo, dynareOBC )
    global M_ options_ oo_ dynareOBC_
    M_ = M;
    options_ = options;
    oo_ = oo;
    dynareOBC_ = dynareOBC;
end
