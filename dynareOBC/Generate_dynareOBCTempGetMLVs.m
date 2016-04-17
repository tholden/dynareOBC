function dynareOBC = Generate_dynareOBCTempGetMLVs( M, dynareOBC, FileName )
    % read in the _dynamic.m file
    FileText = fileread( [ FileName '.m' ] );
    % truncate the function after the last assignment to a MLV
    FileText = regexprep( FileText, '(?<=[\r\n]\s*)((?!(\w+__\s*=[^;]+;)).)*$', 'end' );
    % rename the function
    FileText = strrep( FileText, FileName, 'dynareOBCTempGetMLVs' );
    % replace the function's return value with our MLV array
    FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MLVs', 'once' );
    % make indexing into y two dimensional
    FileText = regexprep( FileText, '\<y\s*\(\s*(\d+)\s*\)', 'y($1,MLVRepeatIndex)' );
    % replace the initialisation of residual, with initialisation of our MLV array
    FileText = regexprep( FileText, 'residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', 'MLVs = zeros( MLVNameIndex, size( y, 2 ) );\nfor MLVRepeatIndex = 1 : size( y, 2 )', 'once' );
    
    % find the contemporaneous and lead variables
    ContemporaneousVariablesSearch = '\<x\(\s*it_\s*,\s*\d+\s*\)';
    for i = min( M.lead_lag_incidence( 2, M.lead_lag_incidence( 2, : ) > 0 ) ) : max( M.lead_lag_incidence( 2, : ) )
        ContemporaneousVariablesSearch = [ ContemporaneousVariablesSearch '|\<y\(' int2str( i ) ',MLVRepeatIndex\)' ]; %#ok<AGROW>
    end
    FutureVariablesSearch = '\<__AStringThatWillNotOccur';
    if size( M.lead_lag_incidence, 1 ) > 2
        for i = min( M.lead_lag_incidence( 3, M.lead_lag_incidence( 3, : ) > 0 ) ) : max( M.lead_lag_incidence( 3, : ) )
            FutureVariablesSearch = [ FutureVariablesSearch '|\<y\(' int2str( i ) '\)' ]; %#ok<AGROW>
        end
    end
    
    % split the file text into lines
    FileLines = StringSplit( FileText, { '\r', '\n' } );
    % initialize dynareOBC_.MLVNames
    dynareOBC.MLVNames = {};
    MLVNameIndex = 0;
    
    EmptyVarList = ( ~isfield( dynareOBC, 'VarList' ) ) || isempty( dynareOBC.VarList );
    
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
        if ( ~EmptyVarList && ismember( VariableName( 1:(end-2) ), dynareOBC.VarList ) ) || ( EmptyVarList && ( ( ( dynareOBC.MLVSimulationMode > 1 ) && ( ContainsContemporaneous || ContainsFuture ) ) || ( ContainsContemporaneous && ( ~ContainsFuture ) ) ) )
            % add the variable to our MLV array
            MLVNameIndex = MLVNameIndex + 1;
            FileLines{i} = regexprep( FileLine, '^\s*(\w+)(__\s*=[^;]+;)\s*$', [ '$1$2\tMLVs(' int2str( MLVNameIndex ) ',MLVRepeatIndex) = $1__;' ], 'lineanchors' );
            % and to dynareOBC_.MLVNames
            dynareOBC.MLVNames{ MLVNameIndex } = VariableName( 1:(end-2) );
        end
    end
    % save the new file
    newmfile = fopen( 'dynareOBCTempGetMLVs.m', 'w' );
    FileText = strjoin( FileLines, '\n' );
    FileText = strrep( FileText, 'MLVNameIndex', int2str( MLVNameIndex ) );
    fprintf( newmfile, '%s', FileText );
    fclose( newmfile );
    rehash;
    try
        BuildMLVSimulationCode( M, dynareOBC );
        rehash;
    catch Error
        warning( 'dynareOBC:FailedCompilingMLVSimulationCode', [ 'Failed to compile the MLV simulation code, due to the error: ' Error.message ] );
    end
    
end
