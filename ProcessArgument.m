function [ basevarargin, dynareOBC_ ] = ProcessArgument( Argument, basevarargin, dynareOBC_ )
    LowerArgument = lower( Argument );
    switch LowerArgument
        case 'savemacro'
            dynareOBC_.SaveMacro = 1;
        case 'noclearall'
        case 'nolinemacro'
        case 'nograph'
            dynareOBC_.NoGraph = 1;
        case 'notmpterms'
            warning( 'dynareOBC:UnusedArgument', 'Ignoring option notmpterms.' );
        case 'onlymacro'
            warning( 'dynareOBC:UnusedArgument', 'Ignoring option onlymacro.' );
        case 'nocleanup'
            dynareOBC_.NoCleanUp = 1;
        case 'resume'
            dynareOBC_.Resume = 1;
        case 'fastirfs'
            dynareOBC_.FastIRFs = 1;
        case 'nosparse'
            dynareOBC_.Sparse = 0;
        case 'irfsaroundzero'
            dynareOBC_.IRFsAroundZero = 1;
        case 'useficoxpress'
            dynareOBC_.UseFICOXpress = 1;
        case 'orderfivequadrature'
            dynareOBC_.OrderFiveQuadrature = 1;
        case 'pseudoorderfivequadrature'
            dynareOBC_.PseudoOrderFiveQuadrature = 1;
        case 'firstorderconditionalcovariance'
            dynareOBC_.FirstOrderConditionalCovariance = 1;
        case 'removenegativequadratureweights'
            dynareOBC_.RemoveNegativeQuadratureWeights = 1;
        case 'forceequalquadratureweights'
            dynareOBC_.ForceEqualQuadratureWeights = 1;
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

