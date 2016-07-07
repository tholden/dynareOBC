function CompileMEX( dynareOBCPath )
    fprintf( 1, '\n' );
    global spkron_use_mex ptest_use_mex;
    try
        spkron_use_mex = 1;
        if any( any( spkron( eye( 2 ), eye( 3 ) ) ~= eye( 6 ) ) )
            spkron_use_mex = [];
        end
    catch 
        try
            fprintf( 1, '\n' );
            disp( 'Attempting to compile spkron.' );
            fprintf( 1, '\n' );
            build_spkron;
            rehash path;
            movefile( which( 'spkron_internal_mex_mex' ), [ dynareOBCPath '/Core/' ], 'f' );
            rehash path;
            spkron_use_mex = 1;
            if any( any( spkron( eye( 2 ), eye( 3 ) ) ~= eye( 6 ) ) )
                spkron_use_mex = [];
            end
        catch
            spkron_use_mex = [];
        end
    end
    if ~isempty( spkron_use_mex )
        disp( 'Using the mex version of spkron.' );
    else
        disp( 'Not using the mex version of spkron.' );
    end
    try
        ptest_use_mex = 1;
        if ptest_mex(magic(4)*magic(4)') || ~(ptest_mex(magic(5)*magic(5)'))
            ptest_use_mex = [];
        end
    catch
        try
            fprintf( 1, '\n' );
            disp( 'Attempting to compile ptest.' );
            fprintf( 1, '\n' );
            build_ptest;
            rehash path;
            movefile( which( 'ptest_mex' ), [ dynareOBCPath '/Core/' ], 'f' );
            rehash path;
            ptest_use_mex = 1;
            if ptest_mex(magic(4)*magic(4)') || ~(ptest_mex(magic(5)*magic(5)'))
                ptest_use_mex = [];
            end
        catch
            ptest_use_mex = [];
        end
    end
    if ~isempty( ptest_use_mex )
        disp( 'Using the mex version of ptest.' );
    else
        disp( 'Not using the mex version of ptest.' );
    end
    fprintf( 1, '\n' );
end
