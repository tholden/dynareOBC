function Generate_dynareOBCTempGetMaxArgValues( DynareVersion, NumberOfMax, FileName )
    
    if DynareVersion >= 4.6
        
        warning( 'dynareOBC:Dynare46SupportExperimental', 'At present, support for Dynare 4.6.* is experimental, and may produce incorrect results. Dynare 4.5.* is fully supported, and is a safer choice.' );
        
        FileName = [ '+' FileName '/static_resid_tt.m' ];
        FileText = fileread( FileName );
        FileText = regexprep( FileText, '\<T\s*=\s*static_resid_tt\(\s*T,', 'MaxArgValues = dynareOBCTempGetMaxArgValues(' );
        
        TElements = regexp( FileText, '\<T\s*\(\s*(\d+)\s*\)\s*=\s*max\s*\(\s*T\s*\(\s*(\d+)\s*\)\s*,\s*T\s*\(\s*(\d+)\s*\)\s*\)\s*;', 'tokens' );
        
        assert( length( TElements ) == NumberOfMax );
        
        for i = 1 : length( TElements )
            TElement = TElements{ i };
            assert( numel( TElement ) == 3 );
            FileText = regexprep( FileText, [ '\<T\s*\(\s*' TElement{ 2 } '\s*\)' ], [ 'MaxArgValues\(' int2str( i ) ',1\)' ] );
            FileText = regexprep( FileText, [ '\<T\s*\(\s*' TElement{ 3 } '\s*\)' ], [ 'MaxArgValues\(' int2str( i ) ',2\)' ] );
        end
        
        FileText = regexprep( FileText, [ '\<T\s*\(\s*' TElement{ 1 } '\s*\).*' ], '' );
        
        TElements = regexp( FileText, '\<T\s*\(\s*(\d+)\s*\)\s*=', 'tokens' );
        
        if isempty( TElements )
            FileText = regexprep( FileText, '\<assert\s*\(\s*length\(\s*T\s*\)\s*>=\s*\d+\s*\)\s*;', [ 'MaxArgValues = zeros( ' int2str( NumberOfMax ) ', 2 );' ] );
        else
            TElement = TElements{ end };
            FileText = regexprep( FileText, '\<assert\s*\(\s*length\(\s*T\s*\)\s*>=\s*\d+\s*\)\s*;', [ 'T = zeros( ' TElement{ 1 } ', 1 ); MaxArgValues = zeros( ' int2str( NumberOfMax ) ', 2 );' ] );
        end
        
    else
        
        FileName = [ FileName '_static' ];
        FileText = fileread( [ FileName '.m' ] );
        FileText = regexprep( FileText, FileName, 'dynareOBCTempGetMaxArgValues' );
        FileText = regexprep( FileText, '\[(\s*residual\s*)?(,)?(\s*g1\s*)?(,)?(\s*g2\s*)?(,)?(\s*g3\s*)?\]', 'MaxArgValues' );
        FileText = regexprep( FileText, '\<residual\s*=\s*zeros\(\s*\d+\s*,\s*\d+\s*\)', [ 'MaxArgValues = zeros( ' int2str( NumberOfMax ) ', 2 )' ] );
        FileText = regexprep( FileText, '\<dynareOBCMaxArgA(\d+)__', 'MaxArgValues\($1,1\)' );
        FileText = regexprep( FileText, '\<dynareOBCMaxArgB(\d+)__', 'MaxArgValues\($1,2\)' );
        if NumberOfMax > 0
            FileText = regexprep( FileText, '(\<dynareOBCMaxFunc\d+__\s+=\s+[^;]*;)(?!.*(\<dynareOBCMaxFunc\d+__\s+=\s+[^;]*;)).*$', '' );
        else
            FileText = regexprep( FileText, '(?<=(\<MaxArgValues = zeros[^;]*;)).*$', '' );
        end

    end
    
    newmfile = fopen( 'dynareOBCTempGetMaxArgValues.m', 'w' );
    fprintf( newmfile, '%s', FileText );
    fclose( newmfile );
    rehash;
    
end

