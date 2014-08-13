function dynareOBC(fname, varargin)
%       This command runs dynare with specified model file in argument
%       Filename.
%       The name of model file begins with an alphabetic character, 
%       and has a filename extension of .mod or .dyn.
%       When extension is omitted, a model file with .mod extension
%       is processed.
%
% INPUTS
%   fname:      file name
%   varargin:   list of arguments following fname
%             
% OUTPUTS
%   none
%        
% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 2001-2014 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

%% Initialization

if nargin < 1 || strcmpi(fname,'help')
    DisplayHelp;
    return;
end

save dynareOBCtemp.mat fname varargin;

if ~ismember( 'noclearall', varargin )
    clear all;
end

load dynareOBCtemp.mat;
delete dynareOBCtemp.mat;

global dynareOBC_ spkron_use_mex;
if isempty( dynareOBC_ )
    dynareOBC_ = struct;
end

if license( 'test', 'coder' )
    if ~exist( 'spkron_internal_mex_mex', 'file' )
        try
            coder -build spkron.prj;
            spkron_use_mex = 1;
            if any(any( sprkon( eye( 2 ), eye( 3 ) ) ~= eye( 5 ) ) )
                spkron_use_mex = [];
            end
        catch
            spkron_use_mex = [];
        end
    else
        spkron_use_mex = 1;
    end
end

FNameDots = strfind( fname, '.' );
if isempty( FNameDots )
    dynareOBC_.BaseFileName = fname;
else
    dynareOBC_.BaseFileName = fname( 1:(FNameDots(end)-1) );
end

dynareOBC_ = SetDefaultOptions( dynareOBC_ );

basevarargin = cell( 1, 0 );
for i = 1:length( varargin )
    [ basevarargin, dynareOBC_ ] = ProcessArgument( varargin{ i }, basevarargin, dynareOBC_ );
end

if dynareOBC_.TimeToEscapeBounds <= 0
    error( 'dynareOBC:Arguments', 'timetoescapebounds must be strictly positive.' );
end
if dynareOBC_.FirstOrderAroundRSS1OrMean2 > 2
    error( 'dynareOBC:Arguments', 'You cannot select both firstorderaroundrss and firstorderaroundmean.' );
end
if ( dynareOBC_.Accuracy < 0 ) || ( dynareOBC_.Accuracy > 2 )
    error( 'dynareOBC:Arguments', 'accuracy should be between 0 and 2.' );
end
if ( dynareOBC_.Algorithm < 0 ) || ( dynareOBC_.Algorithm > 3 )
    error( 'dynareOBC:Arguments', 'algorithm should be between 0 and 3.' );
end
if ( dynareOBC_.Objective < 1 ) || ( dynareOBC_.Objective > 2 )
    error( 'dynareOBC:Arguments', 'objective should be between 1 and 2.' );
end
if ( dynareOBC_.Algorithm == 2 ) && ( dynareOBC_.UseFICOXpress == 1 )
    warning( 'dynareOBC:FicoHomoptopy', 'Using algorithm=1 with FICO Xpress is not recommended, as the Xpress solver will not be used for the quadratic programming. Try algorithm=2 instead.' );
end

basevarargin( end + 1 : end + 5 ) = { 'noclearall', 'nolinemacro', 'console', 'nograph', 'nointeractive' };

%% Dynare pre-processing

skipline( );
disp( 'Performing first dynare run to perform pre-processing.' );
skipline( );

run1varargin = basevarargin;
run1varargin( end + 1 : end + 2 ) = { 'savemacro=dynareOBCtemp1.mod', 'onlymacro' };

dynare( fname, run1varargin{:} );

%% Finding non-differentiable functions

skipline( );
disp( 'Search the pre-processed output for non-differentiable functions.' );
skipline( );

FileText = fileread( 'dynareOBCtemp1.mod' );
FileText = ProcessModFileText( FileText );

FileLines = StringSplit( FileText, { '\n', '\r' } );

[ FileLines, Indices, StochSimulCommand, dynareOBC_ ] = ProcessModFileLines( FileLines, dynareOBC_ );

[ LogLinear, dynareOBC_ ] = ProcessStochSimulCommand( StochSimulCommand, dynareOBC_ );

dynareOBC_ = orderfields( dynareOBC_ );

if dynareOBC_.SimulationDrop < 1
    error( 'dynareOBC:StochSimulCommand', 'drop must be at least 1.' );
end

if LogLinear
    LogLinearString = 'loglinear,';
else
    LogLinearString = '';
end

FileText = strjoin( [ FileLines { [ 'stoch_simul(' LogLinearString 'order=1,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' );
newmodfile = fopen( 'dynareOBCtemp2.mod', 'w' );
fprintf( newmodfile, '%s', FileText );
fclose( newmodfile );

%% Finding the steady-state

skipline( );
disp( 'Performing second dynare run to get the steady-state.' );
skipline( );

steadystatemfilename = [ dynareOBC_.BaseFileName '_steadystate.m' ];
if exist( steadystatemfilename, 'file' )
    copyfile( steadystatemfilename, 'dynareOBCtemp2_steadystate.m', 'f' );
end

dynare( 'dynareOBCtemp2.mod', basevarargin{:} );

Generate_dynareOBCtemp2_GetMaxArgValues( dynareOBC_.NumberOfMax );

global oo_ M_ options_
MaxArgValues = dynareOBCtemp2_GetMaxArgValues( oo_.steady_state, [oo_.exo_steady_state; oo_.exo_det_steady_state], M_.params);
if any( MaxArgValues( :, 1 ) == MaxArgValues( :, 2 ) )
    error( 'dynareOBC does not support cases in which the constraint just binds in steady-state.' );
end

%% Generating the final mod file

skipline( );
disp( 'Generating the final mod file.' );
skipline( );

dynareOBC_.InternalIRFPeriods = max( [ dynareOBC_.IRFPeriods, dynareOBC_.TimeToEscapeBounds, dynareOBC_.TimeToReturnToSteadyState ] );

% Find the state variables, endo variables and shocks
dynareOBC_.StateVariables = { };

dynareOBC_.EndoVariables = cellstr( M_.endo_names )';

for i = ( M_.nstatic + 1 ):( M_.nstatic + M_.nspred )
    dynareOBC_.StateVariables{ end + 1 } = [ dynareOBC_.EndoVariables{ oo_.dr.order_var(i) } '(-1)' ];
end

dynareOBC_.Shocks = cellstr( M_.exo_names )';

dynareOBC_ = SetDefaultOption( dynareOBC_, 'IRFShocks', dynareOBC_.Shocks );
dynareOBC_ = SetDefaultOption( dynareOBC_, 'VarList', dynareOBC_.EndoVariables );

dynareOBC_.StateVariablesAndShocks = [ {'1'} dynareOBC_.StateVariables dynareOBC_.Shocks ];

% Generate combinations
if dynareOBC_.FirstOrderAroundRSS1OrMean2 > 0 % dynareOBC_.Accuracy < 2 || 
    dynareOBC_.ShadowShockNumberMultiplier = 1;
else
    dynareOBC_ = SetDefaultOption( dynareOBC_, 'ShadowShockNumberMultiplier', dynareOBC_.Order );
end

% dynareOBC_.NumberOfShadowShockGroups = dynareOBC_.NumberOfMax * dynareOBC_.TimeToEscapeBounds;
% dynareOBC_.NumberOfShadowShocks = dynareOBC_.ShadowShockNumberMultiplier * dynareOBC_.NumberOfShadowShockGroups;

if dynareOBC_.FirstOrderAroundRSS1OrMean2 > 0
    dynareOBC_.ShadowOrder = 1;
    dynareOBC_.ShadowApproximatingOrder = 1;
else
    dynareOBC_.ShadowOrder = dynareOBC_.Order;
    dynareOBC_ = SetDefaultOption( dynareOBC_, 'ShadowApproximatingOrder', dynareOBC_.ShadowOrder );
end

if dynareOBC_.Accuracy < 2
    dynareOBC_.StateVariableAndShockCombinations = { };
    dynareOBC_.ShadowShockCombinations = { };
    dynareOBC_.ShadowShockNumberMultiplier = 0;
else
    dynareOBC_.StateVariableAndShockCombinations = GenerateCombinations( length( dynareOBC_.StateVariablesAndShocks ), dynareOBC_.ShadowApproximatingOrder );
    dynareOBC_.ShadowShockCombinations = GenerateCombinations( dynareOBC_.ShadowShockNumberMultiplier, dynareOBC_.ShadowOrder );
end


dynareOBC_ = orderfields( dynareOBC_ );

% Insert new variables and equations etc.
if LogLinear
    EndoLLPrefix = 'log_';
else
    EndoLLPrefix = '';
end
ToInsertInInitVal = { };
for i = 1 : length( dynareOBC_.EndoVariables )
    ToInsertInInitVal{ end + 1 } = sprintf( '%s%s=%.20e;', EndoLLPrefix, dynareOBC_.EndoVariables{ i }, oo_.dr.ys( i ) ); %#ok<AGROW>
end


if LogLinear
    [ ToInsertInModelAtStart, FileLines ] = ConvertFromLogLinearToMLVs( FileLines, dynareOBC_.EndoVariables, M_ );
    options_.loglinear = 0;
else
    ToInsertInModelAtStart = { };
end

[ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC_ ] = ...
    InsertShadowEquations( FileLines, ToInsertInInitVal, MaxArgValues, M_, dynareOBC_ );

[ FileLines, Indices ] = PerformDeletion( Indices.InitValStart, Indices.InitValEnd, FileLines, Indices );
[ FileLines, Indices ] = PerformDeletion( Indices.SteadyStateModelStart, Indices.SteadyStateModelEnd, FileLines, Indices );

[ FileLines, Indices ] = PerformInsertion( ToInsertBeforeModel, Indices.ModelStart, FileLines, Indices );
[ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtStart, Indices.ModelStart + 1, FileLines, Indices );
[ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtEnd, Indices.ModelEnd - 1, FileLines, Indices );
[ FileLines, Indices ] = PerformInsertion( ToInsertInShocks, Indices.ShocksStart + 1, FileLines, Indices );
[ FileLines, ~ ] = PerformInsertion( [ { 'initval;' } ToInsertInInitVal { 'end;' } ], Indices.ModelEnd + 1, FileLines, Indices );

%Save the result
FileText = strjoin( [ FileLines { [ 'stoch_simul(order=' int2str( dynareOBC_.Order ) ',pruning,sylvester=fixed_point,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' ); % dr=cyclic_reduction,
newmodfile = fopen( 'dynareOBCtemp3.mod', 'w' );
fprintf( newmodfile, '%s', FileText );
fclose( newmodfile );

%% Solution

skipline( );
disp( 'Making the final call to dynare, as a first step in solving the full model.' );
skipline( );

dynare( 'dynareOBCtemp3.mod', basevarargin{:} );

if dynareOBC_.MLVSimulationPoints > 0
    skipline( );
    disp( 'Generating code to recover MLVs.' );
    skipline( );
    Generate_dynareOBCtemp3_GetMLVs;
end

skipline( );
disp( 'Beginning to solve the model.' );
skipline( );

options_.noprint = 0;
options_.nomoments = dynareOBC_.NoMoments;
options_.nocorr = dynareOBC_.NoCorr;

if dynareOBC_.Accuracy < 2
    [ Info, M_, options_, oo_ ,dynareOBC_ ] = ModelSolution( 1, M_, options_, oo_ ,dynareOBC_ );
else
    [ Info, M_, options_, oo_ ,dynareOBC_ ] = GlobalModelSolution( M_, options_, oo_ ,dynareOBC_ );
end

dynareOBC_ = orderfields( dynareOBC_ );

if Info ~= 0
    error( 'dynareOBC:FailedToSolve', 'dynareOBC failed to find a solution to the model.' );
end

%% Simulating

skipline( );
disp( 'Preparing to simulate the model.' );
skipline( );

[ oo_, dynareOBC_ ] = SimulationPreparation( M_, oo_, dynareOBC_ );

skipline( );
disp( 'Simulating IRFs.' );
skipline( );

if dynareOBC_.FastIRFs
    [ oo_, dynareOBC_ ] = FastIRFs( M_, options_, oo_, dynareOBC_ );
else
    [ oo_, dynareOBC_ ] = SlowIRFs( M_, options_, oo_, dynareOBC_ );
end

if dynareOBC_.SimulationPeriods > 0
    skipline( );
    disp( 'Running stochastic simulation.' );
    skipline( );

    [ oo_, dynareOBC_ ] = RunStochasticSimulation( M_, options_, oo_, dynareOBC_ );
end

if ~dynareOBC_.NoGraph
    if dynareOBC_.IRFsAroundZero
        IRFOffsetFieldNames = fieldnames( dynareOBC_.IRFOffsets );
        for i = 1 : length( IRFOffsetFieldNames )
            dynareOBC_.IRFOffsets.( IRFOffsetFieldNames{i} ) = zeros( size( dynareOBC_.IRFOffsets.( IRFOffsetFieldNames{i} ) ) );
        end
    end
    PlotIRFs( M_, options_, oo_, dynareOBC_ );
end

dynareOBC_ = orderfields( dynareOBC_ );

%% Cleaning up

skipline( );
disp( 'Cleaning up.' );
skipline( );

if dynareOBC_.SaveMacro && ~isempty( dynareOBC_.SaveMacroName )
    copyfile( 'dynareOBCtemp1.mod', dynareOBC_.SaveMacroName, 'f' );
end
if ~dynareOBC_.NoCleanUp
    WarningState = warning( 'off', 'all' );
    try
        rmdir dynareOBCtemp* s
    catch
    end
    try
        delete dynareOBCtemp*.*;
    catch
    end
    try
        delete timedProgressbar*.*
    catch
    end
    warning( WarningState );
end

evalin( 'base', 'global dynareOBC_' );

