function Generate_dynareOBCTempGetMaxArgValues( NumberOfMax, FileName )
    StringNumberOfMax = int2str( NumberOfMax );
    FileText = fileread( [ FileName '.m' ] );
    FileText = regexprep( FileText, FileName, 'dynareOBCTempGetMaxArgValues' );
    FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MaxArgValues' );
    FileText = regexprep( FileText, 'residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', [ 'MaxArgValues = zeros( ' StringNumberOfMax ', 2 )' ] );
    FileText = regexprep( FileText, 'dynareOBCMaxArgA(\d+)__', 'MaxArgValues\($1,1\)' );
    FileText = regexprep( FileText, 'dynareOBCMaxArgB(\d+)__', 'MaxArgValues\($1,2\)' );
    if NumberOfMax > 0
        FileText = regexprep( FileText, [ '(?<=(dynareOBCMaxFunc' StringNumberOfMax '__[^;]*;)).*$' ], '' );
    else
        FileText = regexprep( FileText, '(?<=(MaxArgValues = zeros[^;]*;)).*$', '' );
    end

    newmfile = fopen( 'dynareOBCTempGetMaxArgValues.m', 'w' );
    fprintf( newmfile, '%s', FileText );
    fclose( newmfile );
    rehash;
end

