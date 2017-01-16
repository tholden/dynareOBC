function DisplayError( Error )
    WarningState = warning( 'off', 'MATLAB:structOnObject' );
    Error = struct( Error );
    warning( WarningState );
    fprintf( '%s: %s\n', Error.identifier, Error.message );
    if isfield( Error, 'stack' ) && ~isempty( Error.stack )
        for j = 1 : length( Error.stack )
            fprintf( '%s:%d ', Error.stack( j ).name, Error.stack( j ).line );
        end
        fprintf( '\n' );
    end
    if isfield( Error, 'cause' ) && ~isempty( Error.cause )
        for j = 1 : length( Error.cause )
            DisplayError( Error.cause{ j } );
        end
    end
    if isfield( Error, 'remotecause' ) && ~isempty( Error.remotecause )
        for j = 1 : length( Error.remotecause )
            DisplayError( Error.remotecause{ j } );
        end
    end
end
