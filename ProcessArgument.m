function [ basevarargin, dynareOBC_ ] = ProcessArgument( Argument, basevarargin, dynareOBC_ )
    LowerArgument = lower( Argument );
    switch LowerArgument
        case 'savemacro'
            dynareOBC_.SaveMacro = true;
        case 'noclearall'
        case 'nolinemacro'
        case 'nograph'
            dynareOBC_.NoGraph = true;
        case 'notmpterms'
            warning( 'dynareOBC:UnusedArgument', 'Ignoring option notmpterms.' );
        case 'onlymacro'
            warning( 'dynareOBC:UnusedArgument', 'Ignoring option onlymacro.' );
        case 'nocleanup'
            dynareOBC_.NoCleanUp = true;
        case 'resume'
            dynareOBC_.Resume = true;
        case 'fastirfs'
            dynareOBC_.FastIRFs = true;
        case 'nosparse'
            dynareOBC_.Sparse = false;
        case 'irfsaroundzero'
            dynareOBC_.IRFsAroundZero = true;
        case 'useficoxpress'
            dynareOBC_.UseFICOXpress = true;
        case 'orderfivequadrature'
            dynareOBC_.OrderFiveQuadrature = true;
        case 'pseudoorderfivequadrature'
            dynareOBC_.PseudoOrderFiveQuadrature = true;
        case 'firstorderconditionalcovariance'
            dynareOBC_.FirstOrderConditionalCovariance = true;
        case 'removenegativequadratureweights'
            dynareOBC_.RemoveNegativeQuadratureWeights = true;
        case 'forceequalquadratureweights'
            dynareOBC_.ForceEqualQuadratureWeights = true;
        case 'firstorderaroundrss'
            dynareOBC_.FirstOrderAroundRSS1OrMean2 = double( bitor( int32( dynareOBC_.FirstOrderAroundRSS1OrMean2 ), int32( 1 ) ) );
        case 'firstorderaroundmean'
            dynareOBC_.FirstOrderAroundRSS1OrMean2 = double( bitor( int32( dynareOBC_.FirstOrderAroundRSS1OrMean2 ), int32( 2 ) ) );
        case 'savemacro='
            error( 'dynareOBC:Arguments', 'savemacro was found without a file name. Please do not put a space between the equals sign and the file name.' );

        otherwise
            Matched = true;
            if ~any( LowerArgument == '=' )
                if any( strcmpi( LowerArgument, fieldnames( dynareOBC_ ) ) )
                    error( 'dynareOBC:Arguments', [ LowerArgument ' was found without a number. Please do not put a space between ' LowerArgument ' and the equals sign.' ] );
                else
                    Matched = false;
                end
            end
            if LowerArgument( end ) == '='
                error( 'dynareOBC:Arguments', [ LowerArgument ' was found without a value. Please do not put a space between the equals sign and the value.' ] );
            end
            if Matched
                [ Matched, dynareOBC_ ] = ProcessOtherArgument( LowerArgument, dynareOBC_ );
            end
            if ~Matched
                basevarargin{ end + 1 } = Argument; %#ok<*AGROW>
            end
    end
end

