function dynareOBC = dynareOBCCore( InputFileName, basevarargin, dynareOBC, EnforceRequirementsAndGeneratePathFunctor )
	%% Dynare pre-processing

	skipline( );
	disp( 'Performing first dynare run to perform pre-processing.' );
	skipline( );

	run1varargin = basevarargin;
	run1varargin( end + 1 : end + 2 ) = { 'savemacro=dynareOBCTemp1.mod', 'onlymacro' };

	dynare( InputFileName, run1varargin{:} );

	%% Finding non-differentiable functions

	skipline( );
	disp( 'Searching the pre-processed output for non-differentiable functions.' );
	skipline( );

	FileText = fileread( 'dynareOBCTemp1.mod' );
	FileText = ProcessModFileText( FileText );

	FileLines = StringSplit( FileText, { '\n', '\r' } );

	[ FileLines, Indices, StochSimulCommand, dynareOBC ] = ProcessModFileLines( FileLines, dynareOBC );

	[ LogLinear, dynareOBC ] = ProcessStochSimulCommand( StochSimulCommand, dynareOBC );

	dynareOBC = orderfields( dynareOBC );

	if dynareOBC.SimulationDrop < 1
		error( 'dynareOBC:StochSimulCommand', 'Drop must be at least 1.' );
	end

	if LogLinear
		LogLinearString = 'loglinear,';
	else
		LogLinearString = '';
	end

	if dynareOBC.Estimation
		skipline( );
		disp( 'Loading data for estimation.' );
		skipline( );    
		
		[ XLSStatus, XLSSheets ] = xlsfinfo( dynareOBC.EstimationDataFile );
		if isempty( XLSStatus )
			error( 'dynareOBC:UnsupportedSpreadsheet', 'The given estimation data is in a format that cannot be read.' );
		end
		if length( XLSSheets ) < 2
			error( 'dynareOBC:MissingSpreadsheet', 'The data file does not contain a spreadsheet with observations and a spreadsheet with parameters.' );
		end
		XLSParameterSheetName = XLSSheets{2};
		[ dynareOBC.EstimationParameterBounds, XLSText ] = xlsread( dynareOBC.EstimationDataFile, XLSParameterSheetName );
		dynareOBC.EstimationParameterNames = XLSText( 1, : );
		if isfield( dynareOBC, 'VarList' ) && ~isempty( dynareOBC.VarList )
			warning( 'dynareOBC:OverwritingVarList', 'The variable list passed to stoch_simul will be replaced with the list of observable variables.' );
		end
		[ dynareOBC.EstimationData, XLSText ] = xlsread( dynareOBC.EstimationDataFile );
		dynareOBC.VarList = XLSText( 1, : );
		if dynareOBC.MLVSimulationMode > 1
			warning( 'dynareOBC:UnsupportedMLVSimulationModeWithEstimation', 'With estimation, MLV simulation modes greater than 1 are not currently supported.' );
		end
		dynareOBC.MLVSimulationMode = 1;
	end

	if dynareOBC.MLVSimulationMode > 0 && isfield( dynareOBC, 'VarList' ) && ~isempty( dynareOBC.VarList )
		[ FileLines, Indices ] = PerformInsertion( { 'parameters dynareOBCZeroParameter;', 'dynareOBCZeroParameter=0;' }, Indices.ModelStart, FileLines, Indices );
		dynareOBC.MaxFuncIndices = dynareOBC.MaxFuncIndices + 2;
		for i = ( Indices.ModelEnd - 1 ): -1 : ( Indices.ModelStart + 1 )
			if FileLines{i}(1) ~= '#'
				LastEquation = FileLines{i};
				FileLines( i:( Indices.ModelEnd - 2 ) ) = FileLines( ( i + 1 ):( Indices.ModelEnd - 1 ) );
				LastEquation = [ LastEquation( 1 : ( end - 1 ) ) '+dynareOBCZeroParameter*(' strjoin( dynareOBC.VarList, '+' ) ');' ];
				FileLines{ Indices.ModelEnd - 1 } = LastEquation;
				break;
			end
		end
		dynareOBC.ZeroParameterInserted = true;
	else
		dynareOBC.ZeroParameterInserted = false;
	end

	FileText = strjoin( [ FileLines { [ 'stoch_simul(' LogLinearString 'order=1,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' );
	newmodfile = fopen( 'dynareOBCTemp2.mod', 'w' );
	fprintf( newmodfile, '%s', FileText );
	fclose( newmodfile );

	%% Finding the steady-state

	skipline( );
	disp( 'Performing second dynare run to get the steady-state.' );
	skipline( );

	steadystatemfilename = [ dynareOBC.BaseFileName '_steadystate.m' ];
    if exist( steadystatemfilename, 'file' )
        copyfile( steadystatemfilename, 'dynareOBCTemp2_steadystate.m', 'f' );
    end

    global options_
    options_.solve_tolf = eps;
	dynare( 'dynareOBCTemp2.mod', basevarargin{:} );

	Generate_dynareOBCTemp2_GetMaxArgValues( dynareOBC.NumberOfMax );

	global oo_ M_
	MaxArgValues = dynareOBCTemp2_GetMaxArgValues( oo_.steady_state, [ oo_.exo_steady_state; oo_.exo_det_steady_state ], M_.params );
	if any( MaxArgValues( :, 1 ) == MaxArgValues( :, 2 ) )
        keyboard;
		error( 'dynareOBC:JustBinding', 'dynareOBC does not support cases in which the constraint just binds in steady-state.' );
	end

	if dynareOBC.MLVSimulationMode > 0
		skipline( );
		disp( 'Generating code to recover MLVs.' );
		skipline( );
		dynareOBC = Generate_dynareOBCTemp2_GetMLVs( M_, dynareOBC );
		dynareOBC.OriginalLeadLagIncidence = M_.lead_lag_incidence;
	else
		dynareOBC.MLVNames = {};
	end

	if M_.orig_endo_nbr ~= M_.endo_nbr
		warning( 'dynareOBC:AuxiliaryVariables', 'dynareOBC is untested on models with lags or leads on exogenous variables, or lags or leads on endogenous variables greater than one period.\nConsider manually adding additional variables for these lags and leads.' );
	end

	%% Preparation for the final runs
    
    if dynareOBC.NumberOfMax > 0
        EnforceRequirementsAndGeneratePathFunctor( );
        dynareOBC = SetDefaultOption( dynareOBC, 'MILPOptions', sdpsettings( 'verbose', 0, 'cachesolvers', 1, 'solver', dynareOBC.MILPSolver ) );
    end
    dynareOBC = orderfields( dynareOBC );

	% Find the state variables, endo variables and shocks
	dynareOBC.StateVariables = { };

	dynareOBC.EndoVariables = cellstr( M_.endo_names )';
	dynareOBC = SetDefaultOption( dynareOBC, 'VarList', [ dynareOBC.EndoVariables dynareOBC.MLVNames ] );

	for i = ( M_.nstatic + 1 ):( M_.nstatic + M_.nspred )
		dynareOBC.StateVariables{ end + 1 } = [ dynareOBC.EndoVariables{ oo_.dr.order_var(i) } '(-1)' ];
	end

	dynareOBC.Shocks = cellstr( M_.exo_names )';

	dynareOBC = SetDefaultOption( dynareOBC, 'IRFShocks', dynareOBC.Shocks );

	dynareOBC.StateVariablesAndShocks = [ {'1'} dynareOBC.StateVariables dynareOBC.Shocks ];

	dynareOBC = orderfields( dynareOBC );

	% Extra processing for log-linear models

	if LogLinear
		EndoLLPrefix = 'log_';
	else
		EndoLLPrefix = '';
	end
	ToInsertInInitVal = { };
	for i = 1 : M_.orig_endo_nbr
		ToInsertInInitVal{ end + 1 } = sprintf( '%s%s=%.17e;', EndoLLPrefix, dynareOBC.EndoVariables{ i }, oo_.dr.ys( i ) ); %#ok<AGROW>
	end

	if LogLinear
		[ ToInsertInModelAtStart, FileLines ] = ConvertFromLogLinearToMLVs( FileLines, dynareOBC.EndoVariables, M_ );
		options_.loglinear = 0;
	else
		ToInsertInModelAtStart = { };
	end

	% Common file changes

	[ FileLines, Indices ] = PerformDeletion( Indices.InitValStart, Indices.InitValEnd, FileLines, Indices );
	[ FileLines, Indices ] = PerformDeletion( Indices.SteadyStateModelStart, Indices.SteadyStateModelEnd, FileLines, Indices );

	ToInsertBeforeModel = { };
	ToInsertInModelAtEnd = { };
	ToInsertInShocks = { };
	   
	% Other common set-up

	if ~( isoctave || user_has_matlab_license( 'optimization_toolbox' ) )
        error( 'dynareOBC:MissingOptimizationToolbox', 'The optimization toolbox is required.' );
	end
	SolveAlgo = 0;

	if dynareOBC.FirstOrderAroundRSS1OrMean2 > 0
		dynareOBC.ShadowOrder = 1;
	else
		dynareOBC.ShadowOrder = dynareOBC.Order;
	end

	CurrentNumParams = M_.param_nbr;
	CurrentNumVar = M_.endo_nbr;
	CurrentNumVarExo = M_.exo_nbr;

	dynareOBC.OriginalNumParams = CurrentNumParams;
	if dynareOBC.ZeroParameterInserted
		dynareOBC.OriginalNumParams = dynareOBC.OriginalNumParams - 1;
	end

	dynareOBC.OriginalNumVar = CurrentNumVar;
	dynareOBC.OriginalNumVarExo = CurrentNumVarExo;

	%% Global polynomial approximation

    if dynareOBC.NumberOfMax <= 0
        dynareOBC.Global = false;
    end
	if dynareOBC.Global
        skipline( );
        disp( 'Beginning to solve for the global polynomial approximation to the bounds.' );
        skipline( );

        dynareOBC.StateVariableAndShockCombinations = GenerateCombinations( length( dynareOBC.StateVariablesAndShocks ), dynareOBC.Order );
        GlobalApproximationParameters = RunGlobalSolutionAlgorithm( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC );
	else
		dynareOBC.StateVariableAndShockCombinations = { };
		GlobalApproximationParameters = [];
	end

	%% Generating the final mod file

	skipline( );
	disp( 'Generating the final mod file.' );
	skipline( );

	dynareOBC.InternalIRFPeriods = max( [ dynareOBC.IRFPeriods, dynareOBC.TimeToEscapeBounds, dynareOBC.TimeToReturnToSteadyState ] );
	dynareOBC = orderfields( dynareOBC );

	% Insert new variables and equations etc.

	[ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = ...
		InsertShadowEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumVar, CurrentNumVarExo, dynareOBC, GlobalApproximationParameters );

	[ FileLines, Indices ] = PerformInsertion( ToInsertBeforeModel, Indices.ModelStart, FileLines, Indices );
	[ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtStart, Indices.ModelStart + 1, FileLines, Indices );
	[ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtEnd, Indices.ModelEnd, FileLines, Indices );
	[ FileLines, Indices ] = PerformInsertion( ToInsertInShocks, Indices.ShocksStart + 1, FileLines, Indices );
	[ FileLines, ~ ] = PerformInsertion( [ { 'initval;' } ToInsertInInitVal { 'end;' } ], Indices.ModelEnd + 1, FileLines, Indices );

	%Save the result

	FileText = strjoin( [ FileLines { [ 'stoch_simul(order=' int2str( dynareOBC.Order ) ',solve_algo=' int2str( SolveAlgo ) ',pruning,sylvester=fixed_point,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' ); % dr=cyclic_reduction,
	newmodfile = fopen( 'dynareOBCTemp3.mod', 'w' );
	fprintf( newmodfile, '%s', FileText );
	fclose( newmodfile );

	%% Solution

	skipline( );
	disp( 'Making the final call to dynare, as a first step in solving the full model.' );
	skipline( );

    options_.solve_tolf = eps;
	dynare( 'dynareOBCTemp3.mod', basevarargin{:} );

	skipline( );
	disp( 'Beginning to solve the model.' );
	skipline( );

	options_.noprint = 0;
	options_.nomoments = dynareOBC.NoMoments;
	options_.nocorr = dynareOBC.NoCorr;

	if ~isempty( dynareOBC.VarList )
		[ ~, dynareOBC.VariableSelect ] = ismember( dynareOBC.VarList, cellstr( M_.endo_names ) );
		dynareOBC.VariableSelect( dynareOBC.VariableSelect == 0 ) = [];
		[ ~, dynareOBC.MLVSelect ] = ismember( dynareOBC.VarList, dynareOBC.MLVNames );
		dynareOBC.MLVSelect( dynareOBC.MLVSelect == 0 ) = [];
	else
		dynareOBC.VariableSelect = 1 : dynareOBC.OriginalNumVar;
		dynareOBC.MLVSelect = 1 : length( dynareOBC.MLVNames );
	end

	if dynareOBC.Estimation
		if dynareOBC.Global
			error( 'dynareOBC:UnsupportedGlobalEstimation', 'Estimation of models solved globally is not currently supported.' );
		end
		if any( any( M_.Sigma_e - eye( size( M_.Sigma_e ) ) ~= 0 ) )
			error( 'dynareOBC:UnsupportedCovariance', 'For estimation, all shocks must be given unit variance in the shocks block. If you want a non-unit variance, multiply the shock within the model block.' );
		end
		
		skipline( );
		disp( 'Beginning the estimation of the model.' );
		skipline( );
		
		dynareOBC.CalculateTheoreticalVariance = true;
		[ ~, dynareOBC.EstimationParameterSelect ] = ismember( dynareOBC.EstimationParameterNames, cellstr( M_.param_names ) );
		NumObservables = length( dynareOBC.VarList );
		NumEstimatedParams = length( dynareOBC.EstimationParameterSelect );
		LBTemp = dynareOBC.EstimationParameterBounds(1,:)';
		UBTemp = dynareOBC.EstimationParameterBounds(2,:)';
		LBTemp( ~isfinite( LBTemp ) ) = -Inf;
		UBTemp( ~isfinite( UBTemp ) ) = Inf;
		OpenPool;
		[ TwoNLogLikelihood, EndoSelectWithControls, EndoSelect ] = EstimationObjective( [ M_.params( dynareOBC.EstimationParameterSelect ); 0.01 * ones( NumObservables, 1 ) ], M_, options_, oo_, dynareOBC );
		disp( 'Initial log-likelihood:' );
		disp( -0.5 * TwoNLogLikelihood );
        OptiFunction = @( p ) EstimationObjective( p, M_, options_, oo_, dynareOBC, EndoSelectWithControls, EndoSelect );
        OptiLB = [ LBTemp; zeros( NumObservables, 1 ) ];
        OptiUB = [ UBTemp; Inf( NumObservables, 1 ) ];
        OptiX0 = [ M_.params( dynareOBC.EstimationParameterSelect ); 0.01 * ones( NumObservables, 1 ) ];
        [ ResTemp, TwoNLogLikelihood ] = dynareOBC.FMinFunctor( OptiFunction, OptiX0, OptiLB, OptiUB );
		disp( 'Final log-likelihood:' );
		disp( -0.5 * TwoNLogLikelihood );
		M_.params( dynareOBC.EstimationParameterSelect ) = ResTemp( 1 : NumEstimatedParams );
		disp( 'Final parameter estimates:' );
		for i = 1 : NumEstimatedParams
			fprintf( '%s:\t\t%.17e\n', strtrim( M_.param_names( dynareOBC.EstimationParameterSelect( i ), : ) ), M_.params( dynareOBC.EstimationParameterSelect( i ) ) );
		end
		skipline( );
		disp( 'Final measurement error standard deviation estimates:' );
		for i = 1 : NumObservables
			fprintf( '%s:\t\t%.17e\n', dynareOBC.VarList{ i }, ResTemp( NumEstimatedParams + i ) );
		end
	end

	[ Info, M_, options_, oo_ ,dynareOBC ] = ModelSolution( 1, M_, options_, oo_, dynareOBC );

	dynareOBC = orderfields( dynareOBC );

	if Info ~= 0
		error( 'dynareOBC:FailedToSolve', 'dynareOBC failed to find a solution to the model.' );
	end

	%% Simulating

	skipline( );
	disp( 'Preparing to simulate the model.' );
	skipline( );

	[ oo_, dynareOBC ] = SimulationPreparation( M_, oo_, dynareOBC );

	if dynareOBC.IRFPeriods > 0
		skipline( );
		disp( 'Simulating IRFs.' );
		skipline( );

		if dynareOBC.SlowIRFs
			[ oo_, dynareOBC ] = SlowIRFs( M_, options_, oo_, dynareOBC );
		else
			[ oo_, dynareOBC ] = FastIRFs( M_, options_, oo_, dynareOBC );
		end
	end

	if dynareOBC.SimulationPeriods > 0
		skipline( );
		disp( 'Running stochastic simulation.' );
		skipline( );

		[ oo_, dynareOBC ] = RunStochasticSimulation( M_, options_, oo_, dynareOBC );
	end

	if ( dynareOBC.IRFPeriods > 0 ) && ( ~dynareOBC.NoGraph )
		if dynareOBC.IRFsAroundZero
			IRFOffsetFieldNames = fieldnames( dynareOBC.IRFOffsets );
			for i = 1 : length( IRFOffsetFieldNames )
				dynareOBC.IRFOffsets.( IRFOffsetFieldNames{i} ) = zeros( size( dynareOBC.IRFOffsets.( IRFOffsetFieldNames{i} ) ) );
			end
		end
		PlotIRFs( M_, options_, oo_, dynareOBC );
	end

	dynareOBC = orderfields( dynareOBC );
end
