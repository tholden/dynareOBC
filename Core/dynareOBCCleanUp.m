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
        rmdir codegen s
    catch
    end
    
    CurrentDirectory = cd;
    
    ToSearchList = strsplit( path, ';' );
    ToSearchList{ end + 1 } = CurrentDirectory;
    
    MatlabRoot = matlabroot;
    
    for DirIndex = 1 : length( ToSearchList )
        
        ToSearch = ToSearchList{ DirIndex };
        
        if isempty( ToSearch ) || ~isempty( strfind( ToSearch, MatlabRoot ) )
            continue;
        end
                
        try
            cd( ToSearch );
        catch
        end
        
        try
            rmdir dynareOBCTemp* s
        catch
        end
        try
            rmdir +dynareOBCTemp* s
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
    
    end
    
    cd( CurrentDirectory );
    
    warning( WarningState );
    
end
