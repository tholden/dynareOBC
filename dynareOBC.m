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

    CurrentFolder = pwd( );
    dynareOBCPath = fileparts( mfilename( 'fullpath' ) );

    if exist( [ dynareOBCPath '/dynareOBC/' ], 'dir' ) == 7
        disp( 'A major update to DynareOBC is available, which requires you to download the latest release from:' );
        disp( 'https://github.com/tholden/dynareOBC/releases' );
        disp( 'Once you have downloaded this release, please extract it into a clean directory.' );
        disp( 'Apologies for the inconvenience.' );
        return;
    end
    
    WarningState = warning( 'off', 'MATLAB:rmpath:DirNotFound' );
    rmpath( genpath( [ dynareOBCPath '/Core/' ] ) );
    warning( WarningState );
    
    addpath( dynareOBCPath );

    if nargin < 1 || strcmpi( InputFileName, 'help' ) || strcmpi( InputFileName, '-help' ) || strcmpi( InputFileName, '-h' ) || strcmpi( InputFileName, '/h' ) || strcmpi( InputFileName, '-?' ) || strcmpi( InputFileName, '/?' )
        fprintf( 1, '\n' );
        disp( fileread( [ dynareOBCPath '/README.md' ] ) );
        fprintf( 1, '\n' );
        return;
    end
    
    if strcmpi( InputFileName, 'rmpath' )
        return;
    end

    OriginalPath = path;
    
    addpath( [ dynareOBCPath '/Core/setup/' ] );
        
    ContinueExecution = true;
    
    Update = true;
    
    CurrentDay = now;
    if exist( [ dynareOBCPath '/LastUpdate.mat' ], 'file' ) == 2
        LastUpdateStructure = load( [ dynareOBCPath '/LastUpdate.mat' ] );
        if isfield( LastUpdateStructure, 'CurrentDay' )
            if CurrentDay - LastUpdateStructure.CurrentDay < 1
                Update = false;
            end
        end
    end
    
    global UpdateWarningStrings
    
    UpdateWarningStrings = cell( 0, 1 );
    
    if Update
        addpath( [ dynareOBCPath '/Core/JGit4MATLAB/' ] );
        WarningState = warning( 'off', 'jgit:noSSHpassphrase' );
        warning( 'off', 'jgit:noUserInfo' );
        try
            disp( 'Initializing JGit.' );
            jgit version;

            UpdateWarningStrings{1} = UpdateRepository( [ dynareOBCPath '/' ], [ dynareOBCPath '/.git/' ], 'https://github.com/tholden/dynareOBC.git' );

            GitModulesFile = fileread( [ dynareOBCPath '/.gitmodules' ] );
            ModuleIncides = find( GitModulesFile == ']' );
            NModules = length( ModuleIncides );
            ModuleIncides( end + 1 ) = length( GitModulesFile );
            for i = 1 : NModules
                CurrentBlock = GitModulesFile( ModuleIncides( i ) : ModuleIncides( i + 1 ) );
                ModulePath = regexp( CurrentBlock, '(?<=path\s*=\s*)\S+(?=\s*$)', 'once', 'match', 'lineanchors' );
                ModuleURL = regexp( CurrentBlock, '(?<=url\s*=\s*)\S+(?=\s*$)', 'once', 'match', 'lineanchors' );
                UpdateWarningStrings{i+1} = UpdateRepository( [ dynareOBCPath '/' ModulePath '/' ], [ dynareOBCPath '/.git/modules/' ModulePath '/' ] , ModuleURL );
            end
            save( [ dynareOBCPath '/LastUpdate.mat' ], 'CurrentDay' );
        catch JGitError
            if strcmp( JGitError.identifier, 'jgit:noJGit' )
                try
                    RestartMatlab( OriginalPath, CurrentFolder, InputFileName, varargin{:} );
                catch
                    disp( 'Automatically restarting MATLAB failed. Note that automatic restart is only supported on Windows.' );
                    disp( 'Please manually restart MATLAB now.' );
                    ContinueExecution = false;
                end
            else
                disp( [ 'The JGit error ' JGitError.identifier ' was caught. We will attempt to continue anyway.' ] );
                disp( 'Further details of the error follow:' );
                disp( JGitError.message );
                for i = 1 : length( JGitError.stack )
                    disp( JGitError.stack( i ) );
                end
            end
        end
        warning( WarningState );
        cd( CurrentFolder );
        rehash;
    end

    if ContinueExecution
        dynareOBCSetup( OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin{:} );
    end
    
end
