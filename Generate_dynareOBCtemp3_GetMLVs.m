function Generate_dynareOBCtemp3_GetMLVs
    % read in the _dynamic.m file
    FileText = fileread( 'dynareOBCtemp3_dynamic.m' );
    % truncate the function after the last assignment to a MLV
    FileText = regexprep( FileText, '(?<=[\r\n]\s*)((?!(\w+__\s*=[^;]+;)).)*$', '' );
    % rename the function
    FileText = regexprep( FileText, 'dynareOBCtemp3_dynamic', 'dynareOBCtemp3_GetMLVs' );
    % replace the function's return value with our MLV struct
    FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MLVs' );
    % replace the initialisation of residual, with initialisation of our MLV struct
    FileText = regexprep( FileText, 'residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', 'MLVs = struct' );
    % add each MLV to our MLV struct
    FileText = regexprep( FileText, '^\s*(\w+)(__\s*=[^;]+;)\s*$', '$1$2\tMLVs.$1 = $1__;', 'lineanchors' );    
    % save the new file
    newmfile = fopen( 'dynareOBCtemp3_GetMLVs.m', 'w' );
    fprintf( newmfile, '%s', FileText );
    fclose( newmfile );
    rehash;
end

