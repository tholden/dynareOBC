function aria_urlwrite( dynareOBCPath, URL, FilePath )
    [ FolderName, DestinationName, Extension ] = fileparts( FilePath );
    DestinationName = [ DestinationName Extension ];
    SourceName = regexprep( regexprep( URL, '^.*/', '' ), '?.*$', '' );
    
    WarningState = warning( 'off', 'all' );
    delete( [ FolderName '/' SourceName ], [ FolderName '/' DestinationName ] );
    delete( [ FolderName '/' SourceName '.*' ], [ FolderName '/' DestinationName '.*' ] );
    warning( WarningState );
    
    try
        ArchitectureString = computer( 'arch' );
        system( [ '"' dynareOBCPath '/Core/aria2/' ArchitectureString '/aria2c" -x 4 -s 4 -d "' FolderName '" ' URL ], '-echo' );
        if ~strcmp( SourceName, DestinationName )
            movefile( [ FolderName '/' SourceName ], [ FolderName '/' DestinationName ] );
        end
    catch
        disp( [ 'Using the fallback download method. You may monitor progress by examining the size of the file: '  FilePath ] );
        urlwrite( URL, FilePath );
    end
end
