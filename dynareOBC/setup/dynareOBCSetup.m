function dynareOBCSetup( OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin )
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

    %% Check if need to download new files
    Update = true;
    
    CurrentDay = now;
    if exist( [ dynareOBCPath '/LastDependencyUpdate.mat' ], 'file' ) == 2
        LastUpdateStructure = load( [ dynareOBCPath '/LastDependencyUpdate.mat' ] );
        if isfield( LastUpdateStructure, 'CurrentDay' )
            if CurrentDay - LastUpdateStructure.CurrentDay < 1
                Update = false;
            end
        end
    end

    %% Initialization

    addpath( [ dynareOBCPath '/dynareOBC/nlma/' ] );
    
    if return_dynare_version( dynare_version ) < 4.4
        error( 'dynareOBC:OldDynare', 'Your version of dynare is too old to use with dynareOBC. Please update dynare.' );
    end

    if ~ismember( 'noclearall', varargin )
        WarningState = warning( 'off', 'all' );
        try
            evalin( 'base', 'clear all;' );
        catch
        end
        try
            evalin( 'base', 'clear global;' );
        catch
        end
        try
            evalin( 'base', 'clearvars;' );
        catch
        end
        warning( WarningState );
    end
    
    addpath( [ dynareOBCPath '/dynareOBC/' ] );
    addpath( fileparts( which( 'dynare' ) ) );

    if Update
        CompileMEX( dynareOBCPath );
    end
    
    if strcmpi( InputFileName, 'addpath' )
        EnforceRequirementsAndGeneratePath( Update, OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin{:} );
        dynare_config;
        return;
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
        EnforceRequirementsAndGeneratePath( Update, OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin{:} );
        yalmiptest;
        if ~isempty( dynareOBC_.LPSolver )
            try
                yalmiptest( dynareOBC_.LPSolver );
            catch Error
                warning( 'dynareOBC:TestSolversError', Error.message );
            end
        end
        if ~isempty( dynareOBC_.MILPSolver )
            try
                yalmiptest( dynareOBC_.MILPSolver );
            catch Error
                warning( 'dynareOBC:TestSolversError', Error.message );
            end
        end
        if ~isempty( dynareOBC_.QPSolver )
            try
                yalmiptest( dynareOBC_.QPSolver );
            catch Error
                warning( 'dynareOBC:TestSolversError', Error.message );
            end
        end
        try
            opti_Install_Test;
        catch Error
            warning( 'dynareOBC:TestSolversError', Error.message );
        end
        return;
    end

    dynareOBC_ = dynareOBCCore( InputFileName, basevarargin, dynareOBC_, @() EnforceRequirementsAndGeneratePath( Update, OriginalPath, CurrentFolder, dynareOBCPath, InputFileName, varargin{:} ) );
    
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
