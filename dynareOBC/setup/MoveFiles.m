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
                copyfile( [ Source File.name ], [ Destination File.name ], 'f' );
                lastwarn( '' );
                WarningState = warning( 'off', 'all' );
                delete( [ Source File.name ] );
                warning( WarningState );
                [ ~, DeleteWarningIdentifier ] = lastwarn;
                if ~isempty( DeleteWarningIdentifier )
                    disp( [ 'Warning ' DeleteWarningIdentifier ' moving: ' Source File.name ' to ' Destination File.name ] );
                end
            catch MoveError
                disp( [ 'Error ' MoveError.identifier ' moving: ' Source File.name ' to ' Destination File.name ] );
            end
        end
    end
    
end
