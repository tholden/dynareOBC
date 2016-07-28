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
    
    SafeRemoveDir( dynareOBCPath, '/dynareOBC/' );

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
        try
            fprintf( '\n' );
            ReadMeText = fileread( [ dynareOBCPath '/README.md' ] );
            ReadMeLines = strsplit( ReadMeText, { '\f', '\n', '\r', '\v' }, 'CollapseDelimiters', false );
            for StrIdx = 1 : length( ReadMeLines )
                ReadMeLine = ReadMeLines{ StrIdx };
                SpaceString = regexp( ReadMeLine, '^\s*(\*\s*|\d+\.\s*)?', 'emptymatch', 'once', 'match' );
                SpaceLength = length( SpaceString );
                ReadMeLineWords = strsplit( ReadMeLine( SpaceLength+1:end ), { ' ', '\t' } );
                fprintf( '%s', SpaceString );
                LinePosition = SpaceLength;
                for WrdIdx = 1 : length( ReadMeLineWords )
                    ReadMeLineWord = ReadMeLineWords{ WrdIdx };
                    ReadMeLineWordLength = length( ReadMeLineWord );
                    if LinePosition + 1 + ReadMeLineWordLength > 100
                        SpaceString = regexprep( SpaceString, '\S', ' ' );
                        fprintf( '\n%s', SpaceString );
                        LinePosition = SpaceLength;
                    end
                    fprintf( '%s ', ReadMeLineWord );
                    LinePosition = LinePosition + 1 + ReadMeLineWordLength;
                end
                fprintf( '\n' );
            end
            fprintf( '\n' );
        catch
            error( 'dynareOBC:ReadMeDisplay', 'Error displaying read-me.' );
        end
        return;
    end
    
    if strcmpi( InputFileName, 'rmpath' )
        return;
    end

    OriginalPath = path;
    addpath( [ dynareOBCPath '/Core/setup/' ] );
    
    fprintf( '\n' );
    try
        if exist( [ dynareOBCPath '/CurrentVersionURL.txt' ], 'file' ) == 2
            CurrentVersionURL = strtrim( regexprep( fileread( [ dynareOBCPath '/CurrentVersionURL.txt' ] ), '\s+', ' ' ) );
        else
            CurrentVersionURL = '';
        end

        DownloadURL = regexp( urlread( 'https://api.github.com/repos/tholden/dynareOBC/releases/latest' ), 'https://github.com/tholden/dynareOBC/releases/download/[^\"]+\.zip', 'once', 'ignorecase', 'match' );
        if strcmp( DownloadURL, CurrentVersionURL )
            disp( 'You have the latest DynareOBC release.' );
        else
            disp( 'A new DynareOBC release is available. Do you wish to update?' );
            UpdateSelection = input( 'Please type y to update, or n to skip for now: ', 's' );
            fprintf( '\n' );

            if lower( strtrim( UpdateSelection( 1 ) ) ) == 'y'
                fprintf( '\n' );
                disp( 'Downloading the latest release.' );
                disp( 'This may take several minutes even on fast university connections.' );
                fprintf( '\n' );
                aria_urlwrite( dynareOBCPath, DownloadURL, [ dynareOBCPath '/CurrentRelease.zip' ] )
                fprintf( '\n' );
                CurrentVersionURL = '';
                disp( 'Deleting old DynareOBC files.' );
                fprintf( '\n' );
                WarningState = warning( 'off', 'all' );
                SafeClear( 'all' );
                SafeClear( 'classes' );
                SafeClear( 'functions' );
                SafeClear( 'import' );
                SafeClear( 'java' );
                SafeClear( 'mex' );
                SafeRemoveDir( dynareOBCPath, '/.git/' );
                SafeRemoveDir( dynareOBCPath, '/codegen/' );
                SafeRemoveDir( dynareOBCPath, '/DevTools/' );
                SafeRemoveDir( dynareOBCPath, '/Examples/' );
                SafeRemoveDir( dynareOBCPath, '/Tests/' );
                SafeRemoveDir( dynareOBCPath, '/Core/aria2/' );
                SafeRemoveDir( dynareOBCPath, '/Core/clobber/' );
                SafeRemoveDir( dynareOBCPath, '/Core/eigtool/' );
                SafeRemoveDir( dynareOBCPath, '/Core/glpkmex/' );
                SafeRemoveDir( dynareOBCPath, '/Core/nlma/' );
                SafeRemoveDir( dynareOBCPath, '/Core/setup/' );
                SafeRemoveDir( dynareOBCPath, '/Core/YALMIP/' );
                SafeDeleteFiles( dynareOBCPath, '/.git*' );
                SafeDeleteFiles( dynareOBCPath, '/*.pdf' );
                SafeDeleteFiles( dynareOBCPath, '/*.m' );
                SafeDeleteFiles( dynareOBCPath, '/*.asv' );
                SafeDeleteFiles( dynareOBCPath, '/*.md' );
                SafeDeleteFiles( dynareOBCPath, '/*.txt' );
                SafeDeleteFiles( dynareOBCPath, '/*.mat' );
                SafeDeleteFiles( dynareOBCPath, '/*.bak' );
                SafeDeleteFiles( dynareOBCPath, '/LICENSE' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.m' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.asv' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.mex*' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.prj' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.txt' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.mat' );
                SafeDeleteFiles( dynareOBCPath, '/Core/*.bak' );
                warning( WarningState );
                disp( 'Extracting files from the downloaded release.' );
                fprintf( '\n' );
                unzip(  [ dynareOBCPath '/CurrentRelease.zip' ], dynareOBCPath );
                addpath( [ dynareOBCPath '/Core/setup/' ] );
                rehash;
                CurrentVersionURL = DownloadURL;
            end

        end
    catch UpdateError
        fprintf( '\n' );
        disp( 'The error below was thrown while updating or checking for updates.' );
        disp( 'Manually updating from https://github.com/tholden/dynareOBC/releases is recommended.' );
        disp( UpdateError.message );
    end

    fprintf( '\n' );
    if ~isempty( CurrentVersionURL )
        dynareOBCSetup( OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin{:} );
    else
        disp( 'Since it does not appear that a valid DynareOBC version is installed, DynareOBC will not proceed.' );
        disp( 'Manually updating from https://github.com/tholden/dynareOBC/releases is recommended.' );
    end
    
end

function SafeRemoveDir( dynareOBCPath, Directory )
    try
        rmdir( [ dynareOBCPath Directory ], 's' );
    catch
    end
end

function SafeDeleteFiles( dynareOBCPath, Files )
    try
        delete( [ dynareOBCPath Files ] );
    catch
    end
end

function SafeClear( ToClear )
    try
        evalin( 'base', [ 'clear ' ToClear ';' ] );
    catch
    end
end
