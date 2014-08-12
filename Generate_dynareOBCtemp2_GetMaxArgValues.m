function Generate_dynareOBCtemp2_GetMaxArgValues( NumberOfMax )
    StringNumberOfMax = int2str( NumberOfMax );
    FileText = fileread( 'dynareOBCtemp2_static.m' );
    FileText = regexprep( FileText, 'dynareOBCtemp2_static', 'dynareOBCtemp2_GetMaxArgValues' );
    FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MaxArgValues' );
    FileText = regexprep( FileText, 'residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', [ 'MaxArgValues = zeros( ' StringNumberOfMax ', 2 )' ] );
    FileText = regexprep( FileText, 'dynareOBCMaxArgA(\d+)__', 'MaxArgValues\($1,1\)' );
    FileText = regexprep( FileText, 'dynareOBCMaxArgB(\d+)__', 'MaxArgValues\($1,2\)' );
    FileText = regexprep( FileText, [ '(?<=(dynareOBCMaxFunc' StringNumberOfMax '__[^;]*;)).*$' ], '' );

    newmfile = fopen( 'dynareOBCtemp2_GetMaxArgValues.m', 'w' );
    fprintf( newmfile, '%s', FileText );
    fclose( newmfile );
    rehash;
end

