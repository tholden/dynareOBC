function dynareOBCCleanUp
    fprintf( '\n' );
    disp( 'Cleaning up.' );
    fprintf( '\n' );
    
    ClosePool;
    
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
        delete timedProgressbar_*.*
    catch
    end
    warning( WarningState );
end
