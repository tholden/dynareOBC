function dynareOBC = Generate_dynareOBCTempGetMLVs( M, dynareOBC, FileName )
    % read in the _dynamic.m file
    FileText = fileread( [ FileName '.m' ] );
    % truncate the function after the last assignment to a MLV
    FileText = regexprep( FileText, '(?<=[\r\n]\s*)((?!(\w+__\s*=[^;]+;)).)*$', '' );
    % rename the function
    FileText = regexprep( FileText, FileName, 'dynareOBCTempGetMLVs' );
    % replace the function's return value with our MLV struct
    FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MLVs' );
    % replace the initialisation of residual, with initialisation of our MLV struct
    FileText = regexprep( FileText, 'residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', 'MLVs = struct' );
    
    % find the contemporaneous and lead variables
    ContemporaneousVariablesSearch = '\<x\(\s*it_\s*,\s*\d+\s*\)';
    for i = min( M.lead_lag_incidence( 2, M.lead_lag_incidence( 2, : ) > 0 ) ) : max( M.lead_lag_incidence( 2, : ) )
        ContemporaneousVariablesSearch = [ ContemporaneousVariablesSearch '|\<y\(\s*' int2str( i ) '\s*\)' ]; %#ok<AGROW>
    end
    FutureVariablesSearch = '\<__AStringThatWillNotOccur';
    for i = min( M.lead_lag_incidence( 3, M.lead_lag_incidence( 3, : ) > 0 ) ) : max( M.lead_lag_incidence( 3, : ) )
        FutureVariablesSearch = [ FutureVariablesSearch '|\<y\(\s*' int2str( i ) '\s*\)' ]; %#ok<AGROW>
    end
    
    % split the file text into lines
    FileLines = StringSplit( FileText, { '\r', '\n' } );
    % initialize dynareOBC_.MLVNames
    dynareOBC.MLVNames = {};
    % iterate through the lines
    for i = 1 : length( FileLines )
        FileLine = FileLines{i};
        % See if this FileLine is defining a MLV
        [ VariableNameStart, VariableNameEnd ] = regexp( FileLine, '(?<=^\s*)\w+__(?=\s*=[^;]+;\s*$)', 'once' );
        if isempty( VariableNameStart )
            continue;
        end
        VariableName = FileLine( VariableNameStart:VariableNameEnd );
        % See if it contains contemporaneous variables
        if ~isempty( regexp( FileLine, [ '(' ContemporaneousVariablesSearch ')' ], 'once' ) )
            ContainsContemporaneous = true;
            ContemporaneousVariablesSearch = [ ContemporaneousVariablesSearch '|\<' VariableName ]; %#ok<AGROW>
        else
            ContainsContemporaneous = false;
        end
        % See if it contains future variables
        if ~isempty( regexp( FileLine, [ '(' FutureVariablesSearch ')' ], 'once' ) )
            ContainsFuture = true;
            FutureVariablesSearch = [ FutureVariablesSearch '|\<' VariableName ]; %#ok<AGROW>
        else
            ContainsFuture = false;
        end
        % skip dynareOBC variables
        if ~isempty( regexp( FileLine, '^\s*dynareOBC', 'once' ) )
            continue;
        end
        if ( isfield( dynareOBC, 'VarList' ) && ismember( VariableName, dynareOBC.VarList ) ) || ( ( dynareOBC.MLVSimulationMode > 1 ) && ( ContainsContemporaneous || ContainsFuture ) ) || ( ContainsContemporaneous && ( ~ContainsFuture ) )
            % add the variable to our MLV struct
            FileLines{i} = regexprep( FileLine, '^\s*(\w+)(__\s*=[^;]+;)\s*$', '$1$2\tMLVs.$1 = $1__;', 'lineanchors' );
            % and to dynareOBC_.MLVNames
            dynareOBC.MLVNames{ end + 1 } = VariableName( 1:(end-2) );
        end
    end
    % save the new file
    newmfile = fopen( 'dynareOBCTempGetMLVs.m', 'w' );
    fprintf( newmfile, '%s', strjoin( FileLines, '\n' ) );
    fclose( newmfile );
    rehash;
end

