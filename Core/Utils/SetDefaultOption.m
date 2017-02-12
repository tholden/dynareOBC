function OptionStruct = SetDefaultOption( OptionStruct, Field, Value )

    if ~isfield( OptionStruct, Field ) || isempty( OptionStruct.( Field ) )
        OptionStruct.( Field ) = Value;
        return
    end

end
