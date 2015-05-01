function dynareOBC( InputFileName, varargin )
%       This command runs dynareOBC with the model file specified in
%       the InputFileName arument.
%       Please type "dynareOBC help" to see the full instructions.
%
% INPUTS
%   InputFileName:  Input file name, "help", "addpath", "rmpath" or "testsolvers"
%   varargin:       List of arguments
%             
% OUTPUTS
%   none
%        
% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 2001-2015 Dynare Team and Tom Holden
%
% This file is part of dynareOBC.
%
% dynareOBC is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% dynareOBC is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with dynareOBC. If not, see <http://www.gnu.org/licenses/>.

	%% Initialization

	dynareOBCPath = fileparts( mfilename( 'fullpath' ) );

    if nargin < 1 || strcmpi( InputFileName, 'help' ) || strcmpi( InputFileName, '-help' ) || strcmpi( InputFileName, '-h' ) || strcmpi( InputFileName, '/h' ) || strcmpi( InputFileName, '-?' ) || strcmpi( InputFileName, '/?' )
        skipline( );
        disp( fileread( [ dynareOBCPath '/README.md' ] ) );
        skipline( );
        return;
    end
    
	OriginalPath = path;

	WarningState = warning( 'off', 'MATLAB:rmpath:DirNotFound' );
	rmpath( genpath( [ dynareOBCPath '/dynareOBC/' ] ) );
	warning( WarningState );

	if strcmpi( InputFileName, 'rmpath' )
		return;
	end

	EnforceRequirementsAndGeneratePath( dynareOBCPath, InputFileName, varargin{:} );

	CompileMEX( dynareOBCPath );

	if strcmpi( InputFileName, 'addpath' )
		return;
	end

	if ~ismember( 'noclearall', varargin )
		evalin( 'base', 'clear all;' );
	end

	global dynareOBC_;
	if isempty( dynareOBC_ )
		dynareOBC_ = struct;
	end

	FNameDots = strfind( InputFileName, '.' );
	if isempty( FNameDots )
		dynareOBC_.BaseFileName = InputFileName;
	else
		dynareOBC_.BaseFileName = InputFileName( 1:(FNameDots(end)-1) );
	end

	dynareOBC_ = SetDefaultOptions( dynareOBC_ );

	basevarargin = cell( 1, 0 );
	for i = 1:length( varargin )
		[ basevarargin, dynareOBC_ ] = ProcessArgument( varargin{ i }, basevarargin, dynareOBC_ );
	end

	if dynareOBC_.TimeToEscapeBounds <= 0
		error( 'dynareOBC:Arguments', 'TimeToEscapeBounds must be strictly positive.' );
	end
	if dynareOBC_.FirstOrderAroundRSS1OrMean2 > 2
		error( 'dynareOBC:Arguments', 'You cannot select both FirstOrderAroundRSS and FirstOrderAroundMean.' );
	end

	basevarargin( end + 1 : end + 6 ) = { 'noclearall', 'nolinemacro', 'console', 'nograph', 'nointeractive', '-DdynareOBC=1' };

    if dynareOBC_.MaxCubatureDimension <= 0 || ( ( ~dynareOBC_.FastCubature ) && dynareOBC_.MaxCubatureDegree <= 1 )
        dynareOBC_.NoCubature = true;
    end

    if strcmpi( InputFileName, 'TestSolvers' )
        yalmiptest;
        if ~isempty( dynareOBC_.MILPSolver )
            try
                yalmiptest( dynareOBC_.MILPSolver );
            catch Error
                warning( 'dynareOBC:TestSolversError', Error.message );
            end
        end
        try
            opti_Install_Test;
        catch Error
            warning( 'dynareOBC:TestSolversError', Error.message );
        end
        path( OriginalPath );
        return;
    end

    dynareOBC_ = dynareOBCCore( InputFileName, basevarargin, dynareOBC_ );
    
	%% Cleaning up

	if dynareOBC_.SaveMacro && ~isempty( dynareOBC_.SaveMacroName )
		copyfile( 'dynareOBCTemp1.mod', dynareOBC_.SaveMacroName, 'f' );
	end
	if ~dynareOBC_.NoCleanUp
		dynareOBCCleanUp;
	end

	evalin( 'base', 'global dynareOBC_' );

	path( OriginalPath );

end

function EnforceRequirementsAndGeneratePath( dynareOBCPath, InputFileName, varargin )
	[ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/dynareOBC/requirements/' ] );
	if ~MKDirStatus
		error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
	end
	[ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/dynareOBC/requirements/2012/' ] );
	if ~MKDirStatus
		error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
	end
	[ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/dynareOBC/requirements/2013/' ] );
	if ~MKDirStatus
		error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
	end

	DLLInstalled = false;
	Architecture = computer;
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
        warning( 'dynareOBC:FailedInstallingRequirement', 'Failed to install at least one requirement. Usually this means you are missing admin rights. Please see the source code above this warning to see the URLs of the requirements that should be installed by an administrator on your machine. dynareOBC will disable the OptiToolbox, though even with this change it may still not work correctly.' );
        DLLInstalled = false;
        Architecture = 'FAILURE';
    end
	if DLLInstalled
		skipline( );
		disp( 'dynareOBC needs to restart MATLAB. dynareOBC will attempt to continue after MATLAB is restarted.' );
		skipline( );
        input( 'Press return to continue, or Ctrl+C to cancel.' );
		system( [ 'start matlab.exe -sd "' pwd( ) '" -r "dynareOBC ' InputFileName ' ' strjoin( varargin ) '"' ] );
		system( [ 'taskkill /f /t /pid ' num2str( feature( 'getpid' ) ) ] );     
	end

	addpath( [ dynareOBCPath '/dynareOBC/sedumi/' ] );
	addpath( [ dynareOBCPath '/dynareOBC/glpkmex/' ] );

	if ( length( Architecture ) >= 5 ) && strcmp( Architecture(1:5), 'PCWIN' )
		[ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/dynareOBC/OptiToolbox/' ] );
		if ~MKDirStatus
			error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
		end

		if ~exist( [ dynareOBCPath '/dynareOBC/OptiToolbox/opti_Install.m' ], 'file' )
			skipline( );
			disp( 'Do you want to install SCIP with the OptiToolbox? [y/n]' );
			disp( 'SCIP is an efficient solver which should speed up dynareOBC. However, SCIP is available under the ZLIB Academic License.' );
			disp( 'Thus you are only allowed to retrieve SCIP for research purposes as a memor of a non-commercial and academic institution.' );
			skipline( );
			SCIPSelection = input( 'Please type y to install SCIP, or n to not install SCIP: ', 's' );
			skipline( );

			if lower( strtrim( SCIPSelection( 1 ) ) ) == 'y'
				OptiURL = 'https://www.dropbox.com/s/p1gyhkql8kgfgb8/OptiToolbox_edu_v2.12.zip?dl=1'; % 'http://www.i2c2.aut.ac.nz/Downloads/Files/OptiToolbox_edu_v2.12.zip'; % 
			else
				OptiURL = 'https://www.dropbox.com/s/9fkc8qd892ojfhr/OptiToolbox_v2.12.zip?dl=1'; % 'http://www.i2c2.aut.ac.nz/Downloads/Files/OptiToolbox_v2.12.zip'; % 
			end
			skipline( );
			disp( 'Downloading the OptiToolbox.' );
			disp( 'This may take several minutes even on fast university connections.' );
			skipline( );
            aria_urlwrite( dynareOBCPath, OptiURL, [ dynareOBCPath '/dynareOBC/requirements/OptiToolbox.zip' ] );

			skipline( );
			disp( 'Extracting files from OptiToolbox.zip.' );
			skipline( );
			unzip( [ dynareOBCPath '/dynareOBC/requirements/OptiToolbox.zip' ], [ dynareOBCPath '/dynareOBC/OptiToolbox/' ] );

			copyfile( [ dynareOBCPath '/dynareOBC/clobber/OptiToolbox/' ], [ dynareOBCPath '/dynareOBC/OptiToolbox/' ], 'f' );
			addpath( [ dynareOBCPath '/dynareOBC/OptiToolbox/' ] );
			rehash path;
			opti_Install( [ dynareOBCPath '/dynareOBC/OptiToolbox/' ], false );
		else
			copyfile( [ dynareOBCPath '/dynareOBC/clobber/OptiToolbox/' ], [ dynareOBCPath '/dynareOBC/OptiToolbox/' ], 'f' );
			addpath( [ dynareOBCPath '/dynareOBC/OptiToolbox/' ] );
			rehash path;
			opti_Install( [ dynareOBCPath '/dynareOBC/OptiToolbox/' ], true );
		end
	end

	[ MKDirStatus, ~, ~ ] = mkdir( [ dynareOBCPath '/dynareOBC/tbxmanager/' ] );
	if ~MKDirStatus
		error( 'dynareOBC:MKDir', 'Failed to make a new directory.' );
	end

	TBXManagerDetails = dir( [ dynareOBCPath '/dynareOBC/tbxmanager/tbxmanager.m' ] );
	if ~isempty( TBXManagerDetails )
		CurrentDate = now;
		TBXManagerDate = TBXManagerDetails.datenum;
		if CurrentDate - TBXManagerDate > 7
			TBXManagerDetails = [];
		end
	end

	if isempty( TBXManagerDetails )
		skipline( );
		disp( 'Downloading the latest version of tbxmanager.' );
		skipline( );
		[ NewTBXManagerContents, URLReadStatus ] = urlread( 'http://www.tbxmanager.com/tbxmanager.m' );
		if URLReadStatus
			NewTBXManagerContents = regexprep( NewTBXManagerContents, '^\s*(\w*)\s*=\s*input\s*\(\s*\w*\s*,\s*''s''\s*\)\s*;$', '$1=''y'';\nfprintf(''Agreed automatically. Please delete this folder if you do not agree.\\n\\n'');', 'lineanchors' );
			NewTBXManagerFile = fopen( [ dynareOBCPath '/dynareOBC/tbxmanager/tbxmanager.m' ], 'w' );
			fprintf( NewTBXManagerFile, '%s', NewTBXManagerContents );
			fclose( NewTBXManagerFile );    
		else
			warning( 'dynareOBC:URLRead', 'Failed to download the latest MATLAB toolkit manager (tbxmanager).' );
		end
	end

	addpath( [ dynareOBCPath '/dynareOBC/tbxmanager/' ] );

	skipline( );
	disp( 'Ensuring key packages are up to date.' );
	skipline( );

    try
        tbxmanager install yalmip mpt mptdoc cddmex fourier hysdel lcp espresso;
    catch
        tbxmanager require yalmip mpt mptdoc cddmex fourier hysdel lcp espresso;
    end
	tbxmanager restorepath;

	addpath( [ dynareOBCPath '/dynareOBC/nlma/' ] );
    
    if return_dynare_version( dynare_version ) < 4.4
        error( 'dynareOBC:OldDynare', 'Your version of dynare is too old to use with dynareOBC. Please update dynare.' );
    end
    
	addpath( [ dynareOBCPath '/dynareOBC/' ] );
    addpath( fileparts( which( 'dynare' ) ) );
end

function DLLInstalled = CheckRequirement( GUID, DesiredVersion, URL, dynareOBCPath, SavePath, UnzipPath )
    Version = int32( 0 );
    try
        Version = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{' GUID '}' ], 'Version' );
    catch
    end
    if Version < int32( DesiredVersion )
        try
            Version = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{' GUID '}' ], 'Version' );
        catch
        end
    end
    if Version < int32( DesiredVersion )
        if ~exist( [ dynareOBCPath '/dynareOBC/requirements/' SavePath ], 'file' )
            skipline( );
            disp( [ 'Downloading ' SavePath '.' ] );
            skipline( );
            aria_urlwrite( dynareOBCPath, URL, [ dynareOBCPath '/dynareOBC/requirements/' SavePath ] );
        end
        if nargin > 5
            if ~exist( [ dynareOBCPath '/dynareOBC/requirements/' UnzipPath ], 'file' )
                skipline( );
                disp( [ 'Extracting files from ' SavePath '.' ] );
                skipline( );
                unzip( [ dynareOBCPath '/dynareOBC/requirements/' SavePath ], fileparts( [ dynareOBCPath '/dynareOBC/requirements/' UnzipPath ] ) );
            end
            ExePath = UnzipPath;
        else
            ExePath = SavePath;
        end
        skipline( );
        disp( [ 'Running ' ExePath '.' ] );
        skipline( );
        system( [ 'start "Installing dynareOBC requirement" /wait "' dynareOBCPath '/dynareOBC/requirements/' ExePath '" /passive /norestart' ] );
        DLLInstalled = true;
    else
        DLLInstalled = false;
    end
end

function CompileMEX( dynareOBCPath )
	skipline( );
	global spkron_use_mex ptest_use_mex;
	try
		spkron_use_mex = 1;
		if any( any( spkron( eye( 2 ), eye( 3 ) ) ~= eye( 6 ) ) )
			spkron_use_mex = [];
		end
    catch 
		try
			skipline( );
			disp( 'Attempting to compile spkron.' );
			skipline( );
			build_spkron;
			rehash path;
            movefile( which( 'spkron_internal_mex_mex' ), [ dynareOBCPath '/dynareOBC/' ], 'f' );
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
			skipline( );
			disp( 'Attempting to compile ptest.' );
			skipline( );
			build_ptest;
			rehash path;
            movefile( which( 'ptest_mex' ), [ dynareOBCPath '/dynareOBC/' ], 'f' );
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
	skipline( );
end

function aria_urlwrite( dynareOBCPath, URL, FilePath )
    [ FolderName, DestinationName, Extension ] = fileparts( FilePath );
    DestinationName = [ DestinationName Extension ];
    SourceName = regexprep( regexprep( URL, '^.*/', '' ), '?.*$', '' );
    
    WarningState = warning( 'off', 'all' );
    delete( [ FolderName '/' SourceName ], [ FolderName '/' DestinationName ] );
    delete( [ FolderName '/' SourceName '.*' ], [ FolderName '/' DestinationName '.*' ] );
    warning( WarningState );
    
    try
        system( [ '"' dynareOBCPath '/dynareOBC/aria2/aria2c.exe" --file-allocation=falloc -x 4 -s 4 -d "' FolderName '" ' URL ], '-echo' );
        if ~strcmp( SourceName, DestinationName )
            movefile( [ FolderName '/' SourceName ], [ FolderName '/' DestinationName ] );
        end
    catch
        disp( [ 'Using the fallback download method. You may monitor progress by examining the size of the file: '  FilePath ] );
        urlwrite( URL, FilePath );
    end
end

