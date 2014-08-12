function [ Matched, dynareOBC_ ] = ProcessOtherArgument( Argument, dynareOBC_ )
    Matched = false;

    [ startindex, endindex ] = regexp( Argument, '(?<=(^savemacro\=)).*$', 'once' );
    if ~isempty( startindex )
        dynareOBC_.SaveMacroName = Argument( startindex:endindex );
        dynareOBC_.SaveMacro = 1;
        Matched = true;
        return
    end
    
    TokenNames = regexp( Argument, '^\s*(?<Key>\w+)\s*\=\s*(?<Value>\d+)\s*$', 'names', 'once' );
    
    if isempty( TokenNames )
        return;
    end
    
    FieldNames = fieldnames( dynareOBC_ );
    MatchedOptionIndex = find( strcmpi( TokenNames( 1 ).Key, FieldNames ), 1 );
    if isempty( MatchedOptionIndex )
        return;
    end
    
    try
        dynareOBC_.( FieldNames{ MatchedOptionIndex } ) = str2double( TokenNames( 1 ).Value );
        Matched = true;
    catch
    end
end

