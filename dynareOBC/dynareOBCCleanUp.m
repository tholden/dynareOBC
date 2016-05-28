function dynareOBCCleanUp
    fprintf( 1, '\n' );
    disp( 'Cleaning up.' );
    fprintf( 1, '\n' );
    
    try
        CurrentPool = gcp( 'nocreate' );
        delete( CurrentPool );
    catch
    end
    try        
        matlabpool close force; %#ok<DPOOL>
    catch
    end

    WarningState = warning( 'off', 'all' );
    try
        clear mex; %#ok<CLMEX>
    catch
    end
    try
        rmdir dynareOBCTemp* s
    catch
    end
    try
        rmdir codegen s
    catch
    end
    try
        delete dynareOBCTemp*.*;
    catch
    end
    try
        delete timedProgressbar*.*
    catch
    end
    warning( WarningState );
end