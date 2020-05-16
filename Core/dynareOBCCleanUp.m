function dynareOBCCleanUp
    fprintf( '\n' );
    disp( 'Cleaning up.' );
    fprintf( '\n' );
    
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
        
        if isempty( ToSearch ) || contains( ToSearch, MatlabRoot ) 
            continue
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
        
        RemainingFiles = [ dir( 'dynareOBCTemp*.*' ); dir( 'timedProgressbar_*.*' ) ];
        
        for i = 1 : length( RemainingFiles )
            RemainingFile = RemainingFiles( i ).name;
            try
                delete( RemainingFile );
            catch
            end
        end
    
    end
    
    cd( CurrentDirectory );
    
    warning( WarningState );
    
end
