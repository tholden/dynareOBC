function [ basevarargin, dynareOBC_ ] = ProcessArgument( Argument, basevarargin, dynareOBC_ )
    LowerArgument = lower( Argument );
    switch LowerArgument
        case 'noclearall'
        case 'nolinemacro'
        case 'notmpterms'
            warning( 'dynareOBC:UnusedArgument', 'Ignoring option notmpterms.' );
        case 'onlymacro'
            warning( 'dynareOBC:UnusedArgument', 'Ignoring option onlymacro.' );
        case 'firstorderaroundrss'
            dynareOBC_.FirstOrderAroundRSS1OrMean2 = double( bitor( int32( dynareOBC_.FirstOrderAroundRSS1OrMean2 ), int32( 1 ) ) );
        case 'firstorderaroundmean'
            dynareOBC_.FirstOrderAroundRSS1OrMean2 = double( bitor( int32( dynareOBC_.FirstOrderAroundRSS1OrMean2 ), int32( 2 ) ) );
        case 'savemacro='
            error( 'dynareOBC:Arguments', 'savemacro was found without a file name. Please do not put a space between the equals sign and the file name.' );

        otherwise
            [ Matched, dynareOBC_ ] = ProcessOtherArgument( LowerArgument, dynareOBC_ );
            if ~Matched
                basevarargin{ end + 1 } = Argument; %#ok<*AGROW>
            end
    end
end

