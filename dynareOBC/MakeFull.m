function Struct = MakeFull( Struct )
    % Recursively traverses Struct, removing any cell arrays and strings and making
    % matrices full.
    FieldNames = fieldnames( Struct );
    for i = 1 : length( FieldNames )
        FieldName = FieldNames{i};
        FieldValue = Struct.( FieldName );
        if isstruct( FieldValue )
            Struct.( FieldName ) = MakeFull( FieldValue );
        elseif ~isnumeric( FieldValue )
            Struct = rmfield( Struct, FieldName );
        elseif issparse( FieldValue )
            Struct.( FieldName ) = full( FieldValue );
        end
    end
end
