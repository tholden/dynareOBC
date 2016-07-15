function CompileMEX( dynareOBCPath, Update )
    fprintf( '\n' );
    global spkronUseMex ptestUseMex AltPTestUseMex;
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
    try
        AltPTestUseMex = 1;
        if AltPTest_mex( magic(4)*magic(4)', false ) || ~( AltPTest_mex( magic(5)*magic(5)', false ) )
            AltPTestUseMex = [];
        end
    catch
        if Update
            try
                fprintf( '\n' );
                disp( 'Attempting to compile AltPTest.' );
                fprintf( '\n' );
                build_AltPTest;
                rehash path;
                movefile( which( 'AltPTest_mex' ), [ dynareOBCPath '/Core/' ], 'f' );
                rehash path;
                AltPTestUseMex = 1;
                if ( AltPTest( magic(4)*magic(4)' ) >= 1e-8 ) || ~( AltPTest( magic(5)*magic(5)' ) < 1e-8 )
                    AltPTestUseMex = [];
                end
            catch
                AltPTestUseMex = [];
            end
        else
            AltPTestUseMex = [];
        end
    end
    if ~isempty( AltPTestUseMex )
        disp( 'Using the mex version of AltPTest.' );
    else
        disp( 'Not using the mex version of AltPTest.' );
    end
    fprintf( '\n' );
end
