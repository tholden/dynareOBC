function [ FileLines, TempCounter, MaxCounter, write_i ] = ProcessModelLines( line, FileLines, TempCounter, MaxCounter, write_i )
    % fully support: max, min, abs
    % imperfect support: sign, <, >, <=, >=
    % no support: ==, !=
    if ~isempty( strfind( line, '==' ) )
        error( 'dynareOBC:UnsupportedComparison', 'Error processing line:\n%s\ndynareOBC does not support ==.', line );
    end
    if ~isempty( strfind( line, '!=' ) )
        error( 'dynareOBC:UnsupportedComparison', 'Error processing line:\n%s\ndynareOBC does not support !=.', line );
    end
    [ tagstart, tagend ] = regexp( line, '^\[.*?\]', 'once' );
    tag = '';
    if( ~isempty( tagend ) )
        tag = line( tagstart:tagend );
        line = line( (tagend+1):end );
    end
    if strcmp( tag, '[static]' )
        return
    end
    equationsides = StringSplit( line(1:(end-1)), '(?<![<>])=', 'DelimiterType', 'RegularExpression' );
    ChangeMade = 0;
    newline = '';
    for j = 1 : length( equationsides )
        side = equationsides{ j };
        % convert inequalities into the sign function
        [ ineqindex, ineqindexend ] = regexp( side, '(\<|\>)\=?', 'once' );
        while ~isempty( ineqindex )
            warning( 'dynareOBC:LimitedInequalitySupport', 'Inequalities are only poorly supported. There is no difference between < and <= or > and >= as we assume they never hold exactly. Furthermore, they are implemented using the sign function, which is inaccurate, see later warnings for further details.' );
            [ left, right ] = GetScope( side, ineqindex );
            if side( ineqindex ) == '>'
                signs = '+-';
            else
                signs = '-+';
            end
            side = [ side( 1:(left-1) ) '((sign(0' signs(1) '(' side( left:(ineqindex-1) ) ')' signs(2) '(' side( (ineqindexend+1):right ) '))+1)/2)' side( (right+1):end ) ];
            ChangeMade = 1;
            [ ineqindex, ineqindexend ] = regexp( side, '(\<|\>)\=?', 'once' );
        end
        % convert the sign function into the abs function
        funcindex = regexp( side, '(?<!\w)sign(?!\w)', 'once' );
        while ~isempty( funcindex )
            warning( 'dynareOBC:LimitedSignSupport', 'The sign function is poorly supported. It is implemented as x/abs(x), where abs(x) is accurately implemented via our algorithm. However, a low-order perturbation approximation to x/y will generally be quite inaccurate away from steady-state, which means that our approximation to sign(x) will also be quite inaccurate.' );
            startindex = funcindex + 5;
            endindex = ScopeSearch( side, startindex, 1 );
            FileLines = [ FileLines(1:write_i), FileLines(write_i:end) ];
            TempCounter = TempCounter + 1;
            StringTempCounter = int2str( TempCounter );
            FileLines{ write_i } = [ '#dynareOBCtmp' StringTempCounter '=' side( startindex:endindex ) ';' ];
            write_i = write_i + 1;
            side = [ side( 1:(funcindex-1) ) '(dynareOBCtmp' StringTempCounter '/abs(dynareOBCtmp' StringTempCounter '))' side( (endindex+2):end ) ];
            ChangeMade = 1;
            funcindex = regexp( side, '(?<!\w)sign(?!\w)', 'once' );
        end
        % convert the abs function into the max function
        funcindex = regexp( side, '(?<!\w)abs(?!\w)', 'once' );
        while ~isempty( funcindex )
            startindex = funcindex + 4;
            endindex = ScopeSearch( side, startindex, 1 );
            FileLines = [ FileLines(1:write_i), FileLines(write_i:end) ];
            TempCounter = TempCounter + 1;
            StringTempCounter = int2str( TempCounter );
            FileLines{ write_i } = [ '#dynareOBCtmp' StringTempCounter '=' side( startindex:endindex ) ';' ];
            write_i = write_i + 1;
            side = [ side( 1:(funcindex-1) ) 'max(dynareOBCtmp' StringTempCounter ',-dynareOBCtmp' StringTempCounter ')' side( (endindex+2):end ) ];
            ChangeMade = 1;
            funcindex = regexp( side, '(?<!\w)abs(?!\w)', 'once' );
        end
        % convert the min function into the processed max function
        funcindex = regexp( side, '(?<!\w)min(?!\w)', 'once' );
        while ~isempty( funcindex )
            startindex = funcindex + 4;
            [ endindex, comma ] = ScopeSearch( side, startindex, 1 );
            FileLines = [ FileLines(1:write_i), { '', '' }, FileLines(write_i:end) ];
            MaxCounter = MaxCounter + 1;
            StringMaxCounter = int2str( MaxCounter );
            FileLines{ write_i } = [ '#dynareOBCMaxArgA' StringMaxCounter '=-(' side( startindex:(comma-1) ) ');' ];
            write_i = write_i + 1;
            FileLines{ write_i } = [ '#dynareOBCMaxArgB' StringMaxCounter '=-(' side( (comma+1):endindex ) ');' ];
            write_i = write_i + 1;
            FileLines{ write_i } = [ '#dynareOBCMaxFunc' StringMaxCounter '=max(dynareOBCMaxArgA' StringMaxCounter ',dynareOBCMaxArgB' StringMaxCounter ');' ];
            write_i = write_i + 1;
            side = [ side( 1:(funcindex-1) ) '(-dynareOBCMaxFunc' StringMaxCounter ')' side( (endindex+2):end ) ];
            ChangeMade = 1;
            funcindex = regexp( side, '(?<!\w)min(?!\w)', 'once' );
        end
        % convert the max function into the processed max function
        funcindex = regexp( side, '(?<!\w)max(?!(\w+|\(dynareOBCMaxArgA))', 'once' );
        while ~isempty( funcindex )
            startindex = funcindex + 4;
            [ endindex, comma ] = ScopeSearch( side, startindex, 1 );
            FileLines = [ FileLines(1:write_i), { '', '' }, FileLines(write_i:end) ];
            MaxCounter = MaxCounter + 1;
            StringMaxCounter = int2str( MaxCounter );
            FileLines{ write_i } = [ '#dynareOBCMaxArgA' StringMaxCounter '=(' side( startindex:(comma-1) ) ');' ];
            write_i = write_i + 1;
            FileLines{ write_i } = [ '#dynareOBCMaxArgB' StringMaxCounter '=(' side( (comma+1):endindex ) ');' ];
            write_i = write_i + 1;
            FileLines{ write_i } = [ '#dynareOBCMaxFunc' StringMaxCounter '=max(dynareOBCMaxArgA' StringMaxCounter ',dynareOBCMaxArgB' StringMaxCounter ');' ];
            write_i = write_i + 1;
            side = [ side( 1:(funcindex-1) ) '(dynareOBCMaxFunc' StringMaxCounter ')' side( (endindex+2):end ) ];
            ChangeMade = 1;
            funcindex = regexp( side, '(?<!\w)max(?!\w)', 'once' );
        end

        % append the modified side to our new line
        if isempty( newline )
            newline = side;
        else
            newline = [ newline '=' side ]; %#ok<AGROW>
        end
    end
    if ChangeMade
        FileLines{ write_i } = [ tag newline ';' ];
    end
end
