function dynareOBCCleanUp
    skipline( );
    disp( 'Cleaning up.' );
    skipline( );

    WarningState = warning( 'off', 'all' );
    try
        rmdir dynareOBCtemp* s
    catch
    end
    try
        delete dynareOBCtemp*.*;
    catch
    end
    try
        delete timedProgressbar*.*
    catch
    end
    warning( WarningState );
end