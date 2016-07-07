function EnforceRequirementsAndGeneratePath( Update, OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin )
    Architecture = computer;
    warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );

    if Update
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Core/requirements/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Core/requirements/2012/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Core/requirements/2013/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end

        DLLInstalled = false;
        try
            if strcmp( Architecture, 'PCWIN' )
                DLLInstalled = CheckRequirement( 'BD95A8CD-1D9F-35AD-981A-3E7925026EBB', 184610406, 'http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe', dynareOBCPath, '2012/vcredist_x86.exe' ) || DLLInstalled;
                DLLInstalled = CheckRequirement( '13A4EE12-23EA-3371-91EE-EFB36DDFFF3E', 201347597, 'http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe', dynareOBCPath, '2013/vcredist_x86.exe' ) || DLLInstalled;
                DLLInstalled = CheckRequirement( '5018D8E6-8D8E-4F76-9AFD-CB2EF1100E84', 234881261, 'https://software.intel.com/sites/default/files/managed/c1/90/w_ccompxe_redist_msi_2013_sp1.4.237.zip', dynareOBCPath, 'w_ccompxe_redist_msi_2013_sp1.4.237.zip', 'w_ccompxe_redist_ia32_2013_sp1.4.237.msi' ) || DLLInstalled;
                DLLInstalled = CheckRequirement( '71343AE0-11AC-4B7F-B15C-B9692CA3A23D', 251658419, 'https://software.intel.com/sites/default/files/managed/6a/21/w_fcompxe_redist_msi_2015.2.179.zip', dynareOBCPath, 'w_fcompxe_redist_msi_2015.2.179.zip', 'w_fcompxe_redist_ia32_2015.2.179.msi' ) || DLLInstalled;
            elseif strcmp( Architecture, 'PCWIN64' )
                DLLInstalled = CheckRequirement( 'CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97', 184610406, 'http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe', dynareOBCPath, '2012/vcredist_x64.exe' ) || DLLInstalled;
                DLLInstalled = CheckRequirement( 'A749D8E6-B613-3BE3-8F5F-045C84EBA29B', 201347597, 'http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe', dynareOBCPath, '2013/vcredist_x64.exe' ) || DLLInstalled;
                DLLInstalled = CheckRequirement( 'B548D238-D8C7-4A36-8C4E-496F62285BB3', 234881261, 'https://software.intel.com/sites/default/files/managed/c1/90/w_ccompxe_redist_msi_2013_sp1.4.237.zip', dynareOBCPath, 'w_ccompxe_redist_msi_2013_sp1.4.237.zip', 'w_ccompxe_redist_intel64_2013_sp1.4.237.msi' ) || DLLInstalled;
                DLLInstalled = CheckRequirement( '7FD876F7-BE2A-45B2-ADDC-0316304540CF', 251658419, 'https://software.intel.com/sites/default/files/managed/6a/21/w_fcompxe_redist_msi_2015.2.179.zip', dynareOBCPath, 'w_fcompxe_redist_msi_2015.2.179.zip', 'w_fcompxe_redist_intel64_2015.2.179.msi' ) || DLLInstalled;
            end
        catch
            warning( 'dynareOBC:FailedInstallingRequirement', 'Failed to install at least one requirement. Usually this means you are missing admin rights. Please see the source code above this warning to see the URLs of the requirements that should be installed by an administrator on your machine. DynareOBC will disable the OptiToolbox, though even with this change it may still not work correctly.' );
            DLLInstalled = false;
            Architecture = 'FAILURE';
        end
        if DLLInstalled
            RestartMatlab( OriginalPath, CurrentFolder, InputFileName, varargin{:} );
        end
    else
        if exist( [ dynareOBCPath '/FastStart.mat' ], 'file' )
            fprintf( 1, '\n' );
            disp( [ 'Restoring paths and globals from: ' dynareOBCPath '/FastStart.mat' ] );
            fprintf( 1, '\n' );
            FastStartStruct = load( [ dynareOBCPath filesep 'FastStart.mat' ] );
            GlobalVariables = FastStartStruct.GlobalVariables;
            GlobalVariablesList = fieldnames( GlobalVariables );
            IgnoreList = { 'dynareOBC_', 'UpdateWarningStrings', 'M_', 'options_', 'oo_', 'ptest_use_mex', 'spkron_use_mex', 'MatlabPoolSize' };
            for i = 1 : length( GlobalVariablesList )
                GlobalVariableName = GlobalVariablesList{i};
                if ismember( GlobalVariableName, IgnoreList )
                    continue;
                end
                eval( [ 'global ' GlobalVariableName '; ' GlobalVariableName ' = GlobalVariables.' GlobalVariableName ';' ] );
            end
            PathsToAdd = FastStartStruct.PathsToAdd;
            addpath( PathsToAdd{:} );
            rehash path;
            return;
        end
    end

    addpath( [ dynareOBCPath '/Core/sedumi/' ] );
    addpath( [ dynareOBCPath '/Core/glpkmex/' ] );

    if ( length( Architecture ) >= 5 ) && strcmp( Architecture(1:5), 'PCWIN' )
        OptiString = 'OptiToolbox216';
        
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Core/' OptiString '/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end

        % cleanup old versions
        if exist( [ dynareOBCPath '/Core/OptiToolbox/' ], 'file' )
            rmdir( [ dynareOBCPath '/Core/OptiToolbox/' ], 's' );
        end
        if exist( [ dynareOBCPath '/Core/requirements/OptiToolbox.zip' ], 'file' )
            delete( [ dynareOBCPath '/Core/requirements/OptiToolbox.zip' ] );
        end
        
        if Update && ~exist( [ dynareOBCPath '/Core/' OptiString '/opti_Install.m' ], 'file' )
            if ~exist( [ dynareOBCPath '/Core/requirements/' OptiString '.zip' ], 'file' )
                fprintf( 1, '\n' );
                disp( 'Do you want to install SCIP with the OptiToolbox? [y/n]' );
                disp( 'SCIP is an efficient solver which should speed up dynareOBC.' );
                disp( 'However, SCIP is only available under the ZLIB Academic License.' );
                disp( 'Thus, you are only allowed to retrieve SCIP for research purposes,' );
                disp( 'as a member of a non-commercial and academic institution.' );
                fprintf( 1, '\n' );
                SCIPSelection = input( 'Please type y to install SCIP, or n to not install SCIP: ', 's' );
                fprintf( 1, '\n' );

                if lower( strtrim( SCIPSelection( 1 ) ) ) == 'y'
                    OptiURL = 'https://www.dropbox.com/s/prisikmnp2s8rvg/OptiToolbox_edu_v2.16.zip?dl=1';
                else
                    OptiURL = 'https://www.dropbox.com/s/y21ie4cmez1o9kn/OptiToolbox_v2.16.zip?dl=1';
                end
                fprintf( 1, '\n' );
                disp( 'Downloading the OptiToolbox.' );
                disp( 'This may take several minutes even on fast university connections.' );
                fprintf( 1, '\n' );
                
                ErrCaught = false;
                try
                    aria_urlwrite( dynareOBCPath, OptiURL, [ dynareOBCPath '/Core/requirements/' OptiString '.zip' ] );
                catch
                    ErrCaught = true;
                end
                
                if ErrCaught || exist( [ dynareOBCPath '/Core/requirements/' OptiString '.zip' ], 'file' ) == 0
                    fprintf( 1, '\n' );
                    disp( 'Downloading the OptiToolbox from an alternative location.' );
                    if lower( strtrim( SCIPSelection( 1 ) ) ) == 'y'
                        OptiURL = 'http://www.i2c2.aut.ac.nz/Downloads/Files/OptiToolbox_edu_v2.16.zip';
                    else
                        OptiURL = 'http://www.i2c2.aut.ac.nz/Downloads/Files/OptiToolbox_v2.16.zip';
                    end
                    fprintf( 1, '\n' );
                    disp( 'This may take several minutes even on fast university connections.' );
                    fprintf( 1, '\n' );
                    aria_urlwrite( dynareOBCPath, OptiURL, [ dynareOBCPath '/Core/requirements/' OptiString '.zip' ] );
                end
            end

            fprintf( 1, '\n' );
            disp( [ 'Extracting files from ' OptiString '.zip.' ] );
            fprintf( 1, '\n' );
            unzip( [ dynareOBCPath '/Core/requirements/' OptiString '.zip' ], [ dynareOBCPath '/Core/' OptiString '/' ] );

            copyfile( [ dynareOBCPath '/Core/clobber/' OptiString '/' ], [ dynareOBCPath '/Core/' OptiString '/' ], 'f' );
            addpath( [ dynareOBCPath '/Core/' OptiString '/' ] );
            rehash path;
            opti_Install( [ dynareOBCPath '/Core/' OptiString '/' ], false );
        else
            copyfile( [ dynareOBCPath '/Core/clobber/' OptiString '/' ], [ dynareOBCPath '/Core/' OptiString '/' ], 'f' );
            addpath( [ dynareOBCPath '/Core/' OptiString '/' ] );
            rehash path;
            opti_Install( [ dynareOBCPath '/Core/' OptiString '/' ], true );
        end
    end

    [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Core/tbxmanager/' ] );
    if ~MKDirStatus
        error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
    end

    if Update
        TBXManagerDetails = dir( [ dynareOBCPath '/Core/tbxmanager/tbxmanager.m' ] );
        if ~isempty( TBXManagerDetails )
            CurrentDate = now;
            TBXManagerDate = TBXManagerDetails.datenum;
            if CurrentDate - TBXManagerDate > 7
                TBXManagerDetails = [];
            end
        end

        if isempty( TBXManagerDetails )
            fprintf( 1, '\n' );
            disp( 'Downloading the latest version of tbxmanager.' );
            fprintf( 1, '\n' );
            [ NewTBXManagerContents, URLReadStatus ] = urlread( 'http://www.tbxmanager.com/tbxmanager.m' );
            if URLReadStatus
                NewTBXManagerContents = regexprep( NewTBXManagerContents, '^\s*(\w*)\s*=\s*input\s*\(\s*\w*\s*,\s*''s''\s*\)\s*;$', '$1=''y'';\nfprintf(''Agreed automatically. Please delete this folder if you do not agree.\\n\\n'');', 'lineanchors' );
                NewTBXManagerFile = fopen( [ dynareOBCPath '/Core/tbxmanager/tbxmanager.m' ], 'w' );
                fprintf( NewTBXManagerFile, '%s', NewTBXManagerContents );
                fclose( NewTBXManagerFile );    
            else
                warning( 'dynareOBC:URLRead', 'Failed to download the latest MATLAB toolkit manager (tbxmanager).' );
            end
        end
    end

    addpath( [ dynareOBCPath '/Core/tbxmanager/' ] );

    fprintf( 1, '\n' );
    disp( 'Ensuring key packages are up to date.' );
    fprintf( 1, '\n' );

    if Update
        try
            tbxmanager install mpt mptdoc cddmex fourier hysdel lcp espresso;
        catch
            tbxmanager require mpt mptdoc cddmex fourier hysdel lcp espresso;
        end
    else
        tbxmanager require mpt mptdoc cddmex fourier hysdel lcp espresso;
    end
    tbxmanager restorepath;

    addpath( genpath( [ dynareOBCPath '/Core/YALMIP/' ] ) );
    addpath( [ dynareOBCPath '/Core/nlma/' ] );
    
    rmpath( [ fileparts( which( 'mpt_init' ) ) '/modules/parallel/' ] );
    warning( 'off', 'optim:quadprog:WillBeRemoved' );
    warning( 'off', 'MATLAB:nargchk:deprecated' );
    mpt_init;
    try
        rmpath( [ fileparts( which( 'mpt_init' ) ) '/modules/parallel/' ] );
    catch
    end
            
    if return_dynare_version( dynare_version ) < 4.4
        error( 'dynareOBC:OldDynare', 'Your version of dynare is too old to use with dynareOBC. Please update dynare.' );
    end
        
    addpath( [ dynareOBCPath '/Core/eigtool/num_comp/pseudo_radius/' ] );
    addpath( [ dynareOBCPath '/Core/' ] );
    addpath( fileparts( which( 'dynare' ) ) );
    
    if Update
        CurrentDay = now; %#ok<NASGU>
        save( [ dynareOBCPath '/LastDependencyUpdate.mat' ], 'CurrentDay' );
    end

    GlobalVariables = struct; %#ok<NASGU>
    GlobalVariablesList = who( 'global' );
    IgnoreList = { 'dynareOBC_', 'UpdateWarningStrings', 'M_', 'options_', 'oo_', 'ptest_use_mex', 'spkron_use_mex', 'MatlabPoolSize' };
    for i = 1 : length( GlobalVariablesList )
        GlobalVariableName = GlobalVariablesList{i};
        if ismember( GlobalVariableName, IgnoreList )
            continue;
        end
        eval( [ 'global ' GlobalVariableName '; GlobalVariables.' GlobalVariableName ' = ' GlobalVariableName ';' ] );
    end
    PathsToAdd = strsplit( path, ';' );
    PathsToAdd = PathsToAdd( ~cellfun( @isempty, strfind( PathsToAdd, 'dynareOBC' ) ) ); %#ok<NASGU>
    save( [ dynareOBCPath '/FastStart.mat' ], 'GlobalVariables', 'PathsToAdd' );
    
end
