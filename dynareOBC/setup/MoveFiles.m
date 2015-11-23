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
            try
                movefile( [ Source File.name ], [ Destination File.name ], 'f' );
            catch
                try
                    copyfile( [ Source File.name ], [ Destination File.name ], 'f' );
                    delete( [ Source File.name ] );
                catch MoveError
                    disp( [ 'Error ' MoveError.identifier ' moving: ' Source File.name ' to ' Destination File.name ] );
                end
            end
        end
    end
    
end
