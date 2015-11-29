function MoveFiles( Source, Destination )

    WarningState = warning( 'off', 'all' );
    [ Success, ~, MKDirErrorIdentifier ] = mkdir( Destination );
    warning( WarningState );
    if ~Success
        disp( [ 'Error ' MKDirErrorIdentifier ' creating directory: ' Destination ] );
        return;
    end
    
    Files = dir( Source );
    
    for i = 1 : length( Files )
        File = Files( i );
        if strcmp( File.name, '.' ) || strcmp( File.name, '..' )
            continue;
        end
        if File.isdir
            MoveFiles( [ Source File.name '/' ], [ Destination File.name '/' ] );
        else
            if exist( [ Destination File.name ], 'file' ) == 2
                Different = true;
                srcFile = -1;
                destFile = -1;
                try
                    srcFile = fopen( [ Source File.name '/' ], 'r' );
                    srcData = fread( srcFile, Inf, '*uint8' );
                    destFile = fopen( [ Destination File.name '/' ], 'r' );
                    destData = fread( destFile, Inf, '*uint8' );
                    if numel( srcData ) == numel( destData ) && all( srcData == destData )
                        Different = false;
                    end
                catch
                end
                try
                    fclose( srcFile );
                catch
                end
                try
                    fclose( destFile );
                catch
                end
                if Different
                    SafeMove( [ Destination File.name ], [ Destination File.name '.bak' ] );
                end
            end
            SafeMove( [ Source File.name ], [ Destination File.name ] );
        end
    end
    
end

function SafeMove( SourceFile, DestinationFile )
    try
        copyfile( SourceFile, DestinationFile, 'f' );
        lastwarn( '' );
        WarningState = warning( 'off', 'all' );
        delete( SourceFile );
        warning( WarningState );
        [ ~, DeleteWarningIdentifier ] = lastwarn;
        if ~isempty( DeleteWarningIdentifier )
            disp( [ 'Warning ' DeleteWarningIdentifier ' moving: ' SourceFile ' to ' DestinationFile ] );
        end
    catch MoveError
        disp( [ 'Error ' MoveError.identifier ' moving: ' SourceFile ' to ' DestinationFile ] );
    end
end
