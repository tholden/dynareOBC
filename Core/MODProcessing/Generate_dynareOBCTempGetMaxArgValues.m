function Generate_dynareOBCTempGetMaxArgValues( DynareVersion, NumberOfMax, FileName )
    
    if DynareVersion >= 4.6
        
        FileName = [ '+' FileName '/static_resid_tt.m' ];
        FileText = fileread( [ FileName '.m' ] );
        FileText = regexprep( FileText, 'T\s*=\s*static_resid_tt', 'MaxArgValues = dynareOBCTempGetMaxArgValues' );
        
    else
        
        FileName = [ FileName '_static' ];
        FileText = fileread( [ FileName '.m' ] );
        FileText = regexprep( FileText, FileName, 'dynareOBCTempGetMaxArgValues' );
        FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MaxArgValues' );
        FileText = regexprep( FileText, 'residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', [ 'MaxArgValues = zeros( ' int2str( NumberOfMax ) ', 2 )' ] );
        FileText = regexprep( FileText, 'dynareOBCMaxArgA(\d+)__', 'MaxArgValues\($1,1\)' );
        FileText = regexprep( FileText, 'dynareOBCMaxArgB(\d+)__', 'MaxArgValues\($1,2\)' );
        if NumberOfMax > 0
            FileText = regexprep( FileText, '(\<dynareOBCMaxFunc\d+__\s+=\s+[^;]*;)(?!.*(\<dynareOBCMaxFunc\d+__\s+=\s+[^;]*;)).*$', '' );
        else
            FileText = regexprep( FileText, '(?<=(MaxArgValues = zeros[^;]*;)).*$', '' );
        end

    end
    
    newmfile = fopen( 'dynareOBCTempGetMaxArgValues.m', 'w' );
    fprintf( newmfile, '%s', FileText );
    fclose( newmfile );
    rehash;
    
end

