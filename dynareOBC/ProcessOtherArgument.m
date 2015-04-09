function [ Matched, dynareOBC ] = ProcessOtherArgument( Argument, dynareOBC )
    Matched = false;

    [ startindex, endindex ] = regexp( Argument, '(?<=(^savemacro\=)).*$', 'once' );
    if ~isempty( startindex )
        dynareOBC.SaveMacroName = Argument( startindex:endindex );
        dynareOBC.SaveMacro = true;
        Matched = true;
        return
    end

    [ startindex, endindex ] = regexp( Argument, '(?<=(^estimationdatafile\=)).*$', 'once' );
    if ~isempty( startindex )
        dynareOBC.EstimationDataFile = Argument( startindex:endindex );
        dynareOBC.Estimation = true;
        Matched = true;
        return
    end

    FieldNames = fieldnames( dynareOBC );
    if ~any( Argument == '=' )
        MatchedOptionIndex = find( strcmpi( Argument, FieldNames ), 1 );
        if isempty( MatchedOptionIndex )
            return
        else
            if islogical( dynareOBC.( FieldNames{ MatchedOptionIndex } ) )
                dynareOBC.( FieldNames{ MatchedOptionIndex } ) = true;
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
        
    TokenNames = regexp( Argument, '^\s*(?<Key>\w+)\s*\=\s*(?<Value>\S+)\s*$', 'names', 'once' );
    if isempty( TokenNames )
        return;
    end
    
    MatchedOptionIndex = find( strcmpi( TokenNames( 1 ).Key, FieldNames ), 1 );
    if isempty( MatchedOptionIndex )
        return;
    end
    
    if isempty( regexp( TokenNames( 1 ).Value, '^[-+]?(\d+\.?\d*|\d*\.?\d+)([eE][-+]?\d+)?$', 'once' ) )
        if ischar( dynareOBC.( FieldNames{ MatchedOptionIndex } ) )
            dynareOBC.( FieldNames{ MatchedOptionIndex } ) = TokenNames( 1 ).Value;
            Matched = true;
        else
            error( 'dynareOBC:NonNumericArgument', [ 'dynareOBC was expecting a numeric argument for ' FieldNames{ MatchedOptionIndex } '.' ] );
        end
    else
        try
            IsInteger = floor( dynareOBC.( FieldNames{ MatchedOptionIndex } ) ) == dynareOBC.( FieldNames{ MatchedOptionIndex } );
            dynareOBC.( FieldNames{ MatchedOptionIndex } ) = str2double( TokenNames( 1 ).Value );
            if IsInteger && ( floor( dynareOBC.( FieldNames{ MatchedOptionIndex } ) ) ~= dynareOBC.( FieldNames{ MatchedOptionIndex } ) )
                error( 'dynareOBC:NonIntegerArgument', [ 'dynareOBC was expecting an integer argument for ' FieldNames{ MatchedOptionIndex } '.' ] );
            end
            Matched = true;
        catch
            error( 'dynareOBC:Arguments', [ 'Unexpected problem dealing with argument ' Argument '.' ] );
        end
    end
   
end

