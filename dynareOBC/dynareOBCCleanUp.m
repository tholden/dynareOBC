function dynareOBCCleanUp
    skipline( );
    disp( 'Cleaning up.' );
    skipline( );

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