function MoveFiles( Source, Destination )

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
                catch
                    disp( [ 'Error moving: ' Source File.name ' to ' Destination File.name ] );
                end
            end
        end
    end
    
end
