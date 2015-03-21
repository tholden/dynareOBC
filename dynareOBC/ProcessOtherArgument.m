function [ Matched, dynareOBC_ ] = ProcessOtherArgument( Argument, dynareOBC_ )
    Matched = false;

    [ startindex, endindex ] = regexp( Argument, '(?<=(^savemacro\=)).*$', 'once' );
    if ~isempty( startindex )
        dynareOBC_.SaveMacroName = Argument( startindex:endindex );
        dynareOBC_.SaveMacro = true;
        Matched = true;
        return
    end

    [ startindex, endindex ] = regexp( Argument, '(?<=(^estimationdatafile\=)).*$', 'once' );
    if ~isempty( startindex )
        dynareOBC_.EstimationDataFile = Argument( startindex:endindex );
        dynareOBC_.Estimation = true;
        Matched = true;
        return
    end

    FieldNames = fieldnames( dynareOBC_ );
    if ~any( Argument == '=' )
        MatchedOptionIndex = find( strcmpi( Argument, FieldNames ), 1 );
        if isempty( MatchedOptionIndex )
            return
        else
            if islogical( dynareOBC_.( FieldNames{ MatchedOptionIndex } ) )
                dynareOBC_.( FieldNames{ MatchedOptionIndex } ) = true;
                Matched = true;
                return
            else
                error( 'dynareOBC:Arguments', [ Argument ' was found without a value. Please do not put a space between ' Argument ' and the equals sign.' ] );
            end
        end
    end
    if Argument( end ) == '='
        error( 'dynareOBC:Arguments', [ Argument ' was found without a value. Please do not put a space between the equals sign and the value.' ] );
    end
        
    TokenNames = regexp( Argument, '^\s*(?<Key>\w+)\s*\=\s*(?<Value>\d+)\s*$', 'names', 'once' );
    
    if isempty( TokenNames )
        return;
    end
    
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

