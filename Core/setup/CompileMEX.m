function CompileMEX( dynareOBCPath, Update )
    fprintf( '\n' );
    global spkronUseMex ptestUseMex;
    try
        spkronUseMex = 1;
        if any( any( spkron( eye( 2 ), eye( 3 ) ) ~= eye( 6 ) ) )
            spkronUseMex = [];
        end
    catch
        if Update
            try
                fprintf( '\n' );
                disp( 'Attempting to compile spkron.' );
                fprintf( '\n' );
                build_spkron;
                rehash path;
                movefile( which( 'spkron_internal_mex_mex' ), [ dynareOBCPath '/Core/' ], 'f' );
                rehash path;
                spkronUseMex = 1;
                if any( any( spkron( eye( 2 ), eye( 3 ) ) ~= eye( 6 ) ) )
                    spkronUseMex = [];
                end
            catch
                spkronUseMex = [];
            end
        else
            spkronUseMex = [];
        end
    end
    if ~isempty( spkronUseMex )
        disp( 'Using the mex version of spkron.' );
    else
        disp( 'Not using the mex version of spkron.' );
    end
    try
        ptestUseMex = 1;
        if ptest_mex(magic(4)*magic(4)') || ~(ptest_mex(magic(5)*magic(5)'))
            ptestUseMex = [];
        end
    catch
        if Update
            try
                fprintf( '\n' );
                disp( 'Attempting to compile ptest.' );
                fprintf( '\n' );
                build_ptest;
                rehash path;
                movefile( which( 'ptest_mex' ), [ dynareOBCPath '/Core/' ], 'f' );
                rehash path;
                ptestUseMex = 1;
                if ptest_mex(magic(4)*magic(4)') || ~(ptest_mex(magic(5)*magic(5)'))
                    ptestUseMex = [];
                end
            catch
                ptestUseMex = [];
            end
        else
            ptestUseMex = [];
        end
    end
    if ~isempty( ptestUseMex )
        disp( 'Using the mex version of ptest.' );
    else
        disp( 'Not using the mex version of ptest.' );
    end
    fprintf( '\n' );
end
