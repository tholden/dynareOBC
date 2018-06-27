function EnforceRequirementsAndGeneratePath( Update, OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin )
    Architecture = computer;
    warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );

    if Update
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Extern/Requirements/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Extern/Requirements/2012/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end
        [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Extern/Requirements/2013/' ] );
        if ~MKDirStatus
            error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
        end

        DLLInstalled = false;
        try
            if strcmp( Architecture, 'PCWIN' )
                warning( 'dynareOBC:Setup32Bit', 'DynareOBC is no longer supported on 32 bit MATLAB.\n While it may work (particularly if you have commercial solvers installed), absolutely no guarantees are made.\n We strongly recommend that you install a 64 bit version of MATLAB.' );
                DLLInstalled = CheckMSVCRequirement( '12.0', 40660, 'x86', 'http://download.microsoft.com/download/0/5/6/056dcda9-d667-4e27-8001-8a0c6971d6b1/vcredist_x86.exe', dynareOBCPath, '2013/vcredist_x86.exe', false ) || DLLInstalled;
                DLLInstalled = CheckMSVCRequirement( '14.0', 26429, 'x86', 'https://aka.ms/vs/15/release/VC_redist.x86.exe', dynareOBCPath, '2017/vcredist_x86_26429.exe', false ) || DLLInstalled;
                DLLInstalled = CheckRequirement( 'F1CD4F9E-0AB7-4368-A89A-05967B173A55', 301990098, 'https://software.intel.com/sites/default/files/managed/47/ed/ww_ifort_redist_msi_2018.3.210.zip', dynareOBCPath, 'ww_ifort_redist_msi_2018.3.210.zip', 'ww_ifort_redist_ia32_2018.3.210.msi' ) || DLLInstalled;
            elseif strcmp( Architecture, 'PCWIN64' )
                DLLInstalled = CheckMSVCRequirement( '14.0', 26429, 'x64', 'https://aka.ms/vs/15/release/VC_redist.x64.exe', dynareOBCPath, '2017/vcredist_x64_26429.exe', false ) || DLLInstalled;
                DLLInstalled = CheckRequirement( '8FFDB3FF-96BD-462B-A5AC-AA79D5DFA62C', 301990098, 'https://software.intel.com/sites/default/files/managed/47/ed/ww_ifort_redist_msi_2018.3.210.zip', dynareOBCPath, 'ww_ifort_redist_msi_2018.3.210.zip', 'ww_ifort_redist_intel64_2018.3.210.msi' ) || DLLInstalled;
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
        try
            if exist( [ dynareOBCPath '/FastStart.mat' ], 'file' )
                FastStartStruct = load( [ dynareOBCPath filesep 'FastStart.mat' ] );
                if ~isempty( FastStartStruct ) && isstruct( FastStartStruct ) && isfield( FastStartStruct, 'GlobalVariables' ) && isfield( FastStartStruct, 'PathsToAdd' ) && ~isempty( FastStartStruct.GlobalVariables ) && ~isempty( FastStartStruct.PathsToAdd )
                    fprintf( '\n' );
                    disp( [ 'Restoring paths and globals from: ' dynareOBCPath '/FastStart.mat' ] );
                    fprintf( '\n' );
                    GlobalVariables = FastStartStruct.GlobalVariables;
                    GlobalVariablesList = fieldnames( GlobalVariables );
                    IgnoreList = { 'dynareOBC_', 'UpdateWarningStrings', 'M_', 'options_', 'oo_', 'QuickPCheckUseMex', 'AltPTestUseMex', 'ptestUseMex', 'spkronUseMex', 'MatlabPoolSize' };
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
                else
                    fprintf( '\n' );
                    disp( [ 'Failed restoring paths and globals from: ' dynareOBCPath '/FastStart.mat due to apparent file corruption.' ] );
                    fprintf( '\n' );
                end
            end
        catch Error
            fprintf( '\n' );
            disp( [ 'Error: ' Error.message ' restoring paths and globals from: ' dynareOBCPath '/FastStart.mat' ] );
            fprintf( '\n' );
        end
    end

    addpath( [ dynareOBCPath '/Extern/glpkmex/' ] );

    if ( length( Architecture ) >= 7 ) && strcmp( Architecture(1:7), 'PCWIN64' )
        addpath( [ dynareOBCPath '/Extern/glpkmex/win64/' ] );
    elseif ( length( Architecture ) >= 5 ) && strcmp( Architecture(1:5), 'PCWIN' )
        addpath( [ dynareOBCPath '/Extern/glpkmex/win32/' ] );
    end
    
    if ( length( Architecture ) >= 5 ) && strcmp( Architecture(1:5), 'PCWIN' )
        OptiInstallInternal( Update, dynareOBCPath );
    end

    [ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/Extern/tbxmanager/' ] );
    if ~MKDirStatus
        error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
    end

    if Update
        TBXManagerDetails = dir( [ dynareOBCPath '/Extern/tbxmanager/tbxmanager.m' ] );
        if ~isempty( TBXManagerDetails )
            CurrentDate = now;
            TBXManagerDate = TBXManagerDetails.datenum;
            if CurrentDate - TBXManagerDate > 7
                TBXManagerDetails = [];
            end
        end

        if isempty( TBXManagerDetails )
            fprintf( '\n' );
            disp( 'Downloading the latest version of tbxmanager.' );
            fprintf( '\n' );
            [ NewTBXManagerContents, URLReadStatus ] = urlread( 'http://www.tbxmanager.com/tbxmanager.m' );
            if URLReadStatus
                NewTBXManagerContents = regexprep( NewTBXManagerContents, '^\s*(\w*)\s*=\s*input\s*\(\s*\w*\s*,\s*''s''\s*\)\s*;$', '$1=''y'';\nfprintf(''Agreed automatically. Please delete this folder if you do not agree.\\n\\n'');', 'lineanchors' );
                NewTBXManagerFile = fopen( [ dynareOBCPath '/Extern/tbxmanager/tbxmanager.m' ], 'w' );
                fprintf( NewTBXManagerFile, '%s', NewTBXManagerContents );
                fclose( NewTBXManagerFile );    
            else
                warning( 'dynareOBC:URLRead', 'Failed to download the latest MATLAB toolkit manager (tbxmanager).' );
            end
        end
    end

    addpath( [ dynareOBCPath '/Extern/tbxmanager/' ] );

    fprintf( '\n' );
    disp( 'Ensuring key packages are up to date.' );
    fprintf( '\n' );

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

    addpath( genpath( [ dynareOBCPath '/Extern/YALMIP/' ] ) );
    addpath( [ dynareOBCPath '/Extern/eigtool/num_comp/pseudo_radius/' ] );
    
    rmpath( [ fileparts( which( 'mpt_init' ) ) '/modules/parallel/' ] );
    warning( 'off', 'optim:quadprog:WillBeRemoved' );
    warning( 'off', 'MATLAB:nargchk:deprecated' );
    mpt_init;
    try
        rmpath( [ fileparts( which( 'mpt_init' ) ) '/modules/parallel/' ] );
    catch
    end
            
    addpath( fileparts( which( 'dynare' ) ) );
    
    if Update
        CurrentDay = now; %#ok<NASGU>
        save( [ dynareOBCPath '/LastDependencyUpdate.mat' ], 'CurrentDay' );
    end

    GlobalVariables = struct; %#ok<NASGU>
    GlobalVariablesList = who( 'global' );
    IgnoreList = { 'dynareOBC_', 'UpdateWarningStrings', 'M_', 'options_', 'oo_', 'QuickPCheckUseMex', 'AltPTestUseMex', 'ptestUseMex', 'spkronUseMex', 'MatlabPoolSize' };
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

function OptiInstallInternal( Update, dynareOBCPath )
    % cleanup old versions
    OptiVersionStrings = { 'OptiToolbox', 'OptiToolbox216', 'OptiToolbox221' };
    for i = 1 : length( OptiVersionStrings )
        OptiVersionString = OptiVersionStrings{i};
        if exist( [ dynareOBCPath '/Extern/' OptiVersionString '/' ], 'dir' )
            rmdir( [ dynareOBCPath '/Extern/' OptiVersionString '/' ], 's' );
        end
        if exist( [ dynareOBCPath '/Core/' OptiVersionString '/' ], 'dir' )
            rmdir( [ dynareOBCPath '/Core/' OptiVersionString '/' ], 's' );
        end
    end
    if exist( [ dynareOBCPath '/Extern/Requirements/OptiToolbox.zip' ], 'file' )
        delete( [ dynareOBCPath '/Extern/Requirements/OptiToolbox.zip' ] );
    end
    if exist( [ dynareOBCPath '/Core/Requirements/OptiToolbox.zip' ], 'file' )
        delete( [ dynareOBCPath '/Core/Requirements/OptiToolbox.zip' ] );
    end

    if Update && exist( [ dynareOBCPath '/Extern/OPTI_SCIP/Solvers/scip.m' ], 'file' )
        if exist( [ dynareOBCPath '/Extern/OPTI/Solvers/scip.m' ], 'file' )
            InstallSCIP = true;
        else
            fprintf( '\n' );
            disp( 'Do you want to install the SCIP mixed integer linear programming solver? [y/n]' );
            disp( 'SCIP is an efficient solver which should speed up DynareOBC, so if you agree with its license, you should definitely install it.' );
            disp( 'However, SCIP is only available under the ZIB Academic License, given here: http://scip.zib.de/academic.txt . ' );
            disp( 'Note, in particular, that the ZIB Academic License requires the user to be a member of a noncommercial and academic institution.' );
            fprintf( '\n' );
            SCIPSelection = input( 'Please type y to install SCIP, or n to not install SCIP: ', 's' );
            fprintf( '\n' );
            
            InstallSCIP = ( lower( strtrim( SCIPSelection( 1 ) ) ) == 'y' );
        end
        
        if InstallSCIP
            copyfile( [ dynareOBCPath '/Extern/OPTI_SCIP/*' ], [ dynareOBCPath '/Extern/OPTI/' ], 'f' );
        else
            rmdir( [ dynareOBCPath '/Extern/OPTI_SCIP/' ], 's' );
        end
    end
    
    addpath( [ dynareOBCPath '/Extern/OPTI/' ] );
    rehash path;
    opti_Install_Minimal( [ dynareOBCPath '/Extern/OPTI/' ], ~Update );
end
