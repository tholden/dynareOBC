function dynareOBCCleanUp
    fprintf( 1, '\n' );
    disp( 'Cleaning up.' );
    fprintf( 1, '\n' );

    WarningState = warning( 'off', 'all' );
    try
        rmdir dynareOBCTemp* s
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