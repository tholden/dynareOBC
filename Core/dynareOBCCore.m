function dynareOBC = dynareOBCCore( InputFileName, basevarargin, dynareOBC, EnforceRequirementsAndGeneratePathFunctor )
    %% Dynare pre-processing

    if exist( [ 'dynareOBCTempCustomLanMeyerGohdePrunedSimulation.' mexext ], 'file' )
        try
            delete( [ 'dynareOBCTempCustomLanMeyerGohdePrunedSimulation.' mexext ] );
        catch
            warning( 'dynareOBC:CouldNotDeleteCustomLanMeyerGohdePrunedSimulation', [ 'Could not delete dynareOBCTempCustomLanMeyerGohdePrunedSimulation.' mexext '. Disabling use of simulation code.' ] );
            dynareOBC.CompileSimulationCode = false;
            dynareOBC.UseSimulationCode = false;
        end
    end
    
    fprintf( '\n' );
    disp( 'Performing first dynare run to perform pre-processing.' );
    fprintf( '\n' );

    run1varargin = basevarargin;
    run1varargin( end + 1 : end + 2 ) = { 'savemacro=dynareOBCTemp1.mod', 'onlymacro' };

    [ ~, InputFileBaseName, ~ ] = fileparts( InputFileName );
    HookDisableClearWarning( InputFileBaseName );
    DynareError = [];
    try
        dynare( InputFileName, run1varargin{:} );
    catch DynareError
    end
    try
        rmdir( InputFileBaseName, 's' );
    catch
    end
    if ~isempty( DynareError )
        rethrow( DynareError );
    end

    %% Finding non-differentiable functions

    fprintf( '\n' );
    disp( 'Searching the pre-processed output for non-differentiable functions.' );
    fprintf( '\n' );

    try
        FileText = fileread( 'dynareOBCTemp1.mod' );
    catch ErrorStruct
        if strcmp( ErrorStruct.identifier, 'MATLAB:fileread:cannotOpenFile' )
            disp( 'Could not open Dynare''s output. This is most frequently caused by an incorrect command line option.' );
            disp( 'Please check your command line for typos, or commands not supported in the current version of Dynare or DynareOBC.' );
            error( 'dynareOBC:FailedReadingDynareOutput', 'Failed reading Dynare output. This is usually caused by an incorrect command line option.' );
        else
            rethrow( ErrorStruct );
        end
    end
    FileText = ProcessModFileText( FileText );

    FileLines = StringSplit( FileText, { '\n', '\r' } );

    [ FileLines, Indices, StochSimulCommand, dynareOBC ] = ProcessModFileLines( FileLines, dynareOBC );

    if dynareOBC.MaxCubatureDimension <= 0 || ( ( ~dynareOBC.FastCubature ) && ( dynareOBC.GaussianCubatureDegree <= 1 ) && ( dynareOBC.QuasiMonteCarloLevel <= 0 ) )
        dynareOBC.NoCubature = true;
        dynareOBC.PeriodsOfUncertainty = 0;
        dynareOBC.MaxCubatureDimension = 0;
    else
        dynareOBC.NoCubature = false;
    end

    if dynareOBC.NumberOfMax == 0
        dynareOBC.NoCubature = true;
        dynareOBC.Global = false;
        dynareOBC.FullHorizon = false;
    end
    
    if dynareOBC.ImportanceSamplingAccuracy == 0
        dynareOBC.ImportanceSampling = false;
    else
        dynareOBC.ImportanceSamplingAccuracy = max( [ dynareOBC.ImportanceSamplingAccuracy, dynareOBC.GaussianCubatureDegree + 2, dynareOBC.QuasiMonteCarloLevel + 2 ] );
    end
    
    [ LogLinear, dynareOBC ] = ProcessStochSimulCommand( StochSimulCommand, dynareOBC );
    if dynareOBC.OrderOverride > 0
        dynareOBC.Order = dynareOBC.OrderOverride;
    end

    dynareOBC = orderfields( dynareOBC );

    if dynareOBC.SimulationDrop < 1
        error( 'dynareOBC:StochSimulCommand', 'Drop must be at least 1.' );
    end

    if LogLinear
        LogLinearString = 'loglinear,';
    else
        LogLinearString = '';
    end

    if dynareOBC.Estimation || dynareOBC.Smoothing
        warning( 'dynareOBC:EstimationIsUnsupported', 'Estimation is currently in development. The current version is unsupported, and is not guaranteed to work in any circumstance. Use for experimentation only.' );
        if dynareOBC.DynamicNu && dynareOBC.NoTLikelihood
            error( 'dynareOBC:DynamicNuNoTLikelihoodIncompatible', 'You cannot select both NoTLikelihood and DynamicNu.' );
        end
        
        fprintf( '\n' );
        disp( 'Loading data for estimation and/or smoothing.' );
        fprintf( '\n' );    
        
        [ XLSStatus, XLSSheets ] = xlsfinfo( dynareOBC.DataFile );
        if isempty( XLSStatus )
            error( 'dynareOBC:UnsupportedSpreadsheet', 'The given estimation data is in a format that cannot be read.' );
        end
        if dynareOBC.Estimation
            if length( XLSSheets ) < 2
                error( 'dynareOBC:MissingSpreadsheet', 'The data file does not contain a spreadsheet with observations and a spreadsheet with parameters.' );
            end
            XLSParameterSheetName = XLSSheets{2};
            [ dynareOBC.EstimationParameterBounds, XLSText ] = xlsread( dynareOBC.DataFile, XLSParameterSheetName );
            dynareOBC.EstimationParameterNames = XLSText( 1, : );
            FixedParameters = strsplit( dynareOBC.FixedParameters, { ',', ';', '#' } );
            for i = 1 : length( FixedParameters )
                EFPIndex = find( strcmp( dynareOBC.EstimationParameterNames, FixedParameters( i ) ), 1 );
                if ~isempty( EFPIndex )
                    dynareOBC.EstimationParameterNames( EFPIndex ) = [];
                    dynareOBC.EstimationParameterBounds( :, EFPIndex ) = [];
                end
            end
            dynareOBC.PTest = 0;
            dynareOBC.MaxParametricSolutionDimension = 0;
        end
        if isfield( dynareOBC, 'VarList' ) && ~isempty( dynareOBC.VarList )
            warning( 'dynareOBC:OverwritingVarList', 'The variable list passed to stoch_simul will be replaced with the list of observable variables.' );
        end
        [ dynareOBC.EstimationData, XLSText ] = xlsread( dynareOBC.DataFile );
        dynareOBC.VarList = XLSText( 1, : );
        if dynareOBC.MLVSimulationMode > 1
            warning( 'dynareOBC:UnsupportedMLVSimulationModeWithEstimation', 'With estimation or smoothing, MLV simulation modes greater than 1 are not currently supported.' );
        end
        dynareOBC.MLVSimulationMode = 1;
        dynareOBC.Sparse = false;
        dynareOBC.PTest = 0;
        dynareOBC.MaxParametricSolutionDimension = 0;
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
    
    for i = 1 : dynareOBC.NumberOfMax
        [ FileLines, Indices ] = PerformInsertion( { [ 'parameters dynareOBCFlipParameter' int2str( i ) ';'] , [ 'dynareOBCFlipParameter' int2str( i ) '=0;' ] }, Indices.ModelStart, FileLines, Indices );
        dynareOBC.MaxFuncIndices = dynareOBC.MaxFuncIndices + 2;
    end

    FileText = strjoin( [ FileLines { [ 'stoch_simul(' LogLinearString 'order=1,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' );
    newmodfile = fopen( 'dynareOBCTemp2.mod', 'w' );
    fprintf( newmodfile, '%s', FileText );
    fclose( newmodfile );

    %% Finding the steady-state

    fprintf( '\n' );
    disp( 'Performing second dynare run to get the steady-state.' );
    fprintf( '\n' );

    SteadyStateMFileName = [ dynareOBC.BaseFileName '_steadystate.m' ];
    if exist( SteadyStateMFileName, 'file' )
        copyfile( SteadyStateMFileName, 'dynareOBCTemp2_steadystate.m', 'f' );
    end
    
    SteadyState2MFileName = [ dynareOBC.BaseFileName '_steadystate2.m' ];
    if exist( SteadyState2MFileName, 'file' )
        copyfile( SteadyState2MFileName, 'dynareOBCTemp2_steadystate2.m', 'f' );
    end
    
    global options_
    options_.solve_tolf = eps;
    options_.solve_tolx = eps;
    HookDisableClearWarning( 'dynareOBCTemp2' );
    dynare( 'dynareOBCTemp2.mod', basevarargin{:} );
    
    global oo_ M_
    oo_.steady_state = oo_.dr.ys;

    Generate_dynareOBCTempGetMaxArgValues( dynareOBC.DynareVersion, dynareOBC.NumberOfMax, 'dynareOBCTemp2' );

    if LogLinear
        MaxArgValues = dynareOBCTempGetMaxArgValues( exp( oo_.steady_state ), [ oo_.exo_steady_state; oo_.exo_det_steady_state ], M_.params );
    else
        MaxArgValues = dynareOBCTempGetMaxArgValues( oo_.steady_state, [ oo_.exo_steady_state; oo_.exo_det_steady_state ], M_.params );
    end
    if any( MaxArgValues( :, 1 ) == MaxArgValues( :, 2 ) )
        error( 'dynareOBC:JustBinding', 'DynareOBC does not support cases in which the constraint just binds in steady-state.' );
    end

    if dynareOBC.MLVSimulationMode > 0
        fprintf( '\n' );
        disp( 'Generating code to recover MLVs.' );
        fprintf( '\n' );
        dynareOBC.OriginalLeadLagIncidence = M_.lead_lag_incidence;
        dynareOBC.OriginalMaximumEndoLag = M_.maximum_endo_lag;
        dynareOBC = Generate_dynareOBCTempGetMLVs( M_, dynareOBC, 'dynareOBCTemp2_dynamic' );
    else
        dynareOBC.MLVNames = {};
    end

    if ( M_.orig_endo_nbr ~= M_.endo_nbr ) && ( dynareOBC.NumberOfMax > 0 ) && ( ~dynareOBC.Bypass )
        error( 'dynareOBC:AuxiliaryVariables', 'DynareOBC is unsupported on models with lags or leads on exogenous variables, or lags or leads on endogenous variables greater than one period.\nPlease manually add additional variables for these lags and leads.\nFor example, to introduce lags of an exogenous variable e, define a new endogenous variable e_ENDO with equation e_ENDO = e, then replace e(-1) with e_ENDO(-1).\nAnd, to introduce a second lag of an endogenous variable x, introduce a new endogenous variable x_LAG with equation x_LAG = x(-1), then replace x(-2) with x_LAG(-1).' );
    end

    %% Preparation for the final runs
    
    if dynareOBC.MedianIRFs
        dynareOBC.SlowIRFs = true;
    end
    
    if dynareOBC.NumberOfMax > 0
        EnforceRequirementsAndGeneratePathFunctor( );
        LPOptions = sdpsettings( 'verbose', 0, 'cachesolvers', 1, 'solver', dynareOBC.LPSolver );
        OptionsFieldNames = fieldnames( LPOptions );
        for i = 1 : length( OptionsFieldNames )
            CurrentField = LPOptions.( OptionsFieldNames{i} );
            if isstruct( CurrentField )
                OptionsSubFieldNames = fieldnames( CurrentField );
                for j = 1 : length( OptionsSubFieldNames )
                    CurrentSubFieldName = OptionsSubFieldNames{j};
                    if ~isempty( strfind( lower( CurrentSubFieldName ), 'tol' ) ) %#ok<STREMP>
                        CurrentSubField = CurrentField.( CurrentSubFieldName );
                        if numel( CurrentSubField ) == 1 && CurrentSubField > 0 && CurrentSubField <= 1e-4
                            CurrentField.( CurrentSubFieldName ) = min( sqrt( eps ), CurrentSubField );
                        end
                    end
                end
                LPOptions.( OptionsFieldNames{i} ) = CurrentField;
            end
        end
        LPOptions.gurobi.NumericFocus = 3;
        dynareOBC = SetDefaultOption( dynareOBC, 'LPOptions', LPOptions );
        dynareOBC = SetDefaultOption( dynareOBC, 'MILPOptions', sdpsettings( 'verbose', 0, 'cachesolvers', 1, 'solver', dynareOBC.MILPSolver ) );
        if dynareOBC.MultiThreadBoundsProblem || ( ~dynareOBC.Estimation && ~dynareOBC.Smoothing && ( ( dynareOBC.SimulationPeriods == 0 && dynareOBC.IRFPeriods == 0 ) || ( ~dynareOBC.SlowIRFs && dynareOBC.NoCubature && dynareOBC.MLVSimulationMode <= 1 ) ) )
            dynareOBC.MILPOptions.bintprog.UseParallel = 1;
            dynareOBC.MILPOptions.clp.numThreads = 0;
            dynareOBC.MILPOptions.fmincon.UseParallel = 1;
            dynareOBC.MILPOptions.gurobi.Threads = 0;
            dynareOBC.MILPOptions.knitro.UseParallel = 1;
            dynareOBC.MILPOptions.quadprogbb.use_single_processor = 0;
        else
            dynareOBC.MILPOptions.bintprog.UseParallel = 0;
            dynareOBC.MILPOptions.clp.numThreads = 1;
            dynareOBC.MILPOptions.fmincon.UseParallel = 0;
            dynareOBC.MILPOptions.gurobi.Threads = 1;
            dynareOBC.MILPOptions.knitro.UseParallel = 0;
            dynareOBC.MILPOptions.quadprogbb.use_single_processor = 1;
        end
    end
    dynareOBC = orderfields( dynareOBC );

    % Find the state variables, endo variables and shocks
    dynareOBC.StateVariables = { };

    dynareOBC.EndoVariables = cellstr( M_.endo_names )';
    dynareOBC = SetDefaultOption( dynareOBC, 'VarList', [ dynareOBC.EndoVariables dynareOBC.MLVNames ] );

    for i = ( M_.nstatic + 1 ):( M_.nstatic + M_.nspred )
        dynareOBC.StateVariables{ end + 1 } = [ dynareOBC.EndoVariables{ oo_.dr.order_var(i) } '(-1)' ];
    end

    if isfield( M_, 'exo_names' )
        dynareOBC.Shocks = cellstr( M_.exo_names )';
    else
        dynareOBC.Shocks = { };
        dynareOBC.NoCubature = true;
        dynareOBC.FastCubature = false;
        dynareOBC.GaussianCubatureDegree = 0;
        dynareOBC.QuasiMonteCarloLevel = 0;
        dynareOBC.HigherOrderSobolDegree = 0;
        dynareOBC.PeriodsOfUncertainty = 0;
        dynareOBC.MaxCubatureDimension = 0;
    end

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
        [ ToInsertInModelAtStart, FileLines ] = ConvertFromLogLinearToMLVs( FileLines, Indices, dynareOBC.EndoVariables, M_ );
        options_.loglinear = 0;
    else
        ToInsertInModelAtStart = { };
    end
    
    for i = 1 : dynareOBC.NumberOfMax
        dynareOBC.EndoVariables{ end + 1 } = [ 'dynareOBCZeroLowerBounded' int2str( i ) ];
    end

    % Common file changes

    [ FileLines, Indices ] = PerformDeletion( Indices.InitValStart, Indices.InitValEnd, FileLines, Indices );
    [ FileLines, Indices ] = PerformDeletion( Indices.SteadyStateModelStart, Indices.SteadyStateModelEnd, FileLines, Indices );
    
    ParamNames = strtrim( cellstr( M_.param_names ) );

    ToInsertBeforeModel = cell( 1, M_.param_nbr );
    for ParamIndex = 1 : M_.param_nbr
        ToInsertBeforeModel{ ParamIndex } = sprintf( '%s=%.17e;', ParamNames{ ParamIndex }, M_.params( ParamIndex ) );
    end

    ToInsertInModelAtEnd = { };
       
    % Other common set-up

    SolveAlgo = 0;

    if dynareOBC.FirstOrderAroundRSS1OrMean2 > 0
        dynareOBC.ShadowOrder = 1;
    else
        dynareOBC.ShadowOrder = dynareOBC.Order;
    end

    switch dynareOBC.ShadowOrder
        case 1
            dynareOBC.OrderText = 'first';
        case 2
            dynareOBC.OrderText = 'second';
        case 3
            dynareOBC.OrderText = 'third';
    end
    
    CurrentNumParams = M_.param_nbr;
    CurrentNumVar = M_.endo_nbr;
    CurrentNumVarExo = M_.exo_nbr;

    dynareOBC.OriginalNumParams = CurrentNumParams - dynareOBC.NumberOfMax;
    if dynareOBC.ZeroParameterInserted
        dynareOBC.OriginalNumParams = dynareOBC.OriginalNumParams - 1;
    end

    dynareOBC.OriginalNumVar = CurrentNumVar;
    dynareOBC.OriginalNumVarExo = CurrentNumVarExo;

    %% Global polynomial approximation

    if dynareOBC.Global
        if dynareOBC.NoCubature
            error( 'dynareOBC:GlobalNoCubature', 'If specifying the Global option, you must also specify a cubature mode.' );
        end
        
        fprintf( '\n' );
        disp( 'Beginning to solve for the global polynomial approximation to the bounds.' );
        fprintf( '\n' );

        dynareOBC.StateVariableAndShockCombinations = GenerateCombinations( length( dynareOBC.StateVariablesAndShocks ), dynareOBC.Order );
        [ GlobalApproximationParameters, MaxArgValues, AmpValues ] = RunGlobalSolutionAlgorithm( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC );
    else
        dynareOBC.StateVariableAndShockCombinations = { };
        GlobalApproximationParameters = [];
        AmpValues = ones( dynareOBC.NumberOfMax, 1 );
    end
    
    if dynareOBC.Global || dynareOBC.Estimation
        SteadyStateBlockDeclaration = 'initval;';
    else
        SteadyStateBlockDeclaration = 'steady_state_model;';
    end       

    %% Generating the final mod file

    fprintf( '\n' );
    disp( 'Generating the final mod file.' );
    fprintf( '\n' );
    
    dynareOBC.TimeToEscapeBounds = max( [ dynareOBC.TimeToEscapeBounds, dynareOBC.PTest, dynareOBC.AltPTest, dynareOBC.FullTest ] );
    if ~dynareOBC.NoCubature
        dynareOBC.TimeToEscapeBounds = max( [ dynareOBC.TimeToEscapeBounds, dynareOBC.PeriodsOfUncertainty ] );
    end
    dynareOBC.InternalIRFPeriods = max( dynareOBC.TimeToEscapeBounds + 1, dynareOBC.TimeToReturnToSteadyState );
    if ~dynareOBC.SlowIRFs
        dynareOBC.InternalIRFPeriods = max( dynareOBC.InternalIRFPeriods, dynareOBC.IRFPeriods );
    end
    if ~dynareOBC.NoCubature
        dynareOBC.InternalIRFPeriods = max( dynareOBC.InternalIRFPeriods, dynareOBC.PeriodsOfUncertainty + 1 );
    end
    
    if dynareOBC.Global
        dynareOBC.OriginalTimeToEscapeBounds = dynareOBC.TimeToEscapeBounds;
        dynareOBC.TimeToEscapeBounds = dynareOBC.InternalIRFPeriods;
    end

    dynareOBC = orderfields( dynareOBC );

    % Insert new variables and equations etc.

    [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInInitVal, dynareOBC ] = ...
        InsertShadowEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInInitVal, MaxArgValues, CurrentNumVar, dynareOBC, GlobalApproximationParameters, AmpValues );

    [ FileLines, Indices ] = PerformInsertion( ToInsertBeforeModel, Indices.ModelStart, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtStart, Indices.ModelStart + 1, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtEnd, Indices.ModelEnd, FileLines, Indices );
    [ FileLines, ~ ] = PerformInsertion( [ { SteadyStateBlockDeclaration } ToInsertInInitVal { 'end;' } ], Indices.ModelEnd + 1, FileLines, Indices );

    %Save the result

    if dynareOBC.Order == 3
        KOrderSolverString = ',k_order_solver';
    else
        KOrderSolverString = '';
    end
    
    FileText = strjoin( [ FileLines { [ 'stoch_simul(order=' int2str( dynareOBC.Order ) ',solve_algo=' int2str( SolveAlgo ) KOrderSolverString ',pruning,sylvester=fixed_point,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' ); % dr=cyclic_reduction,
    newmodfile = fopen( 'dynareOBCTemp3.mod', 'w' );
    fprintf( newmodfile, '%s', FileText );
    fclose( newmodfile );

    %% Solution

    fprintf( '\n' );
    disp( 'Making the final call to dynare, as a first step in solving the full model.' );
    fprintf( '\n' );

    options_.solve_tolf = eps;
    options_.solve_tolx = eps;
    HookDisableClearWarning( 'dynareOBCTemp3' );
    dynare( 'dynareOBCTemp3.mod', basevarargin{:} );

    fprintf( '\n' );
    disp( 'Beginning to solve the model.' );
    fprintf( '\n' );

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

    global spkronUseMex
    
    if dynareOBC.Estimation
        if dynareOBC.Global
            error( 'dynareOBC:UnsupportedGlobalEstimation', 'Estimation of models solved globally is not currently supported.' );
        end
        
        fprintf( '\n' );
        disp( 'Beginning the estimation of the model.' );
        fprintf( '\n' );
        
        EstimationOptions = struct;
        
        EstimationOptions.DynamicNu = dynareOBC.DynamicNu;
        EstimationOptions.FilterCubatureDegree = dynareOBC.FilterCubatureDegree;
        EstimationOptions.MaximisationFunctions = StringSplit( dynareOBC.MaximisationFunctions, { ',', ';', '#' } );
        EstimationOptions.NoSkewLikelihood = dynareOBC.NoSkewLikelihood;
        EstimationOptions.NoTLikelihood = dynareOBC.NoTLikelihood;
        EstimationOptions.Prior = dynareOBC.Prior;
        EstimationOptions.SkipStandardErrors = dynareOBC.SkipStandardErrors;
        EstimationOptions.StationaryDistAccuracy = dynareOBC.StationaryDistAccuracy;
        EstimationOptions.StationaryDistDrop = dynareOBC.StationaryDistDrop;
        EstimationOptions.StdDevThreshold = dynareOBC.StdDevThreshold;
        
        [ ~, dynareOBC.EstimationParameterSelect ] = ismember( dynareOBC.EstimationParameterNames, cellstr( M_.param_names ) );
        EstimationOptions.ParameterNames = cellstr( M_.param_names( dynareOBC.EstimationParameterSelect, : ) );
        EstimationOptions.VariableNames = dynareOBC.VarList;
        
        EstimationOptions.Data = dynareOBC.EstimationData';
        EstimationOptions.Solve = @EstimationSolution;
        EstimationOptions.Simulate = @EstimationSimulation;
        
        NExo = dynareOBC.OriginalNumVarExo;
        EstimationOptions.ExoCovariance = M_.Sigma_e( 1:NExo, 1:NExo );

        LBTemp = dynareOBC.EstimationParameterBounds(1,:)';
        UBTemp = dynareOBC.EstimationParameterBounds(2,:)';
        LBTemp( ~isfinite( LBTemp ) ) = -Inf;
        UBTemp( ~isfinite( UBTemp ) ) = Inf;

        EstimationOptions.LB = LBTemp;
        EstimationOptions.UB = UBTemp;

        EstimatedParameters = M_.params( dynareOBC.EstimationParameterSelect );
        
        OpenPool;
        dynareOBC = orderfields( dynareOBC );
        EstimationPersistentState = struct( 'M', M_, 'options', options_, 'oo', oo_, 'dynareOBC', dynareOBC, 'spkronUseMex', spkronUseMex, 'InitialRun', true );
        
        [ EstimatedParameters, EstimationPersistentState ] = RunEstimation( EstimatedParameters, EstimationOptions, EstimationPersistentState );
        
        M_ = EstimationPersistentState.M;
        options_ = EstimationPersistentState.options;
        oo_ = EstimationPersistentState.oo;
        dynareOBC = orderfields( EstimationPersistentState.dynareOBC );
        
        M_.params( dynareOBC.EstimationParameterSelect ) = EstimatedParameters( 1 : length( dynareOBC.EstimationParameterSelect ) );
    end

    CurrentFlip = false( 1, dynareOBC.NumberOfMax );
    FlipsTried = CurrentFlip;
    RepeatModelSolution = true;
    while RepeatModelSolution
        RepeatModelSolution = false;
        [ Info, M_, options_, oo_ , dynareOBC ] = ModelSolution( ( ~dynareOBC.Estimation ) && ( size( FlipsTried, 1 ) == 1 ), M_, options_, oo_, dynareOBC );
        if Info == 19090714
            if dynareOBC.Global
                error( 'dynareOBC:GlobalConstantWrongSign', 'Global approximation does not currently support cases in which the risky steady state of one of the zero lower bounded variables has an unexpected sign.' );
            end
            fprintf( '\n' );
            disp( 'The risky steady state of one of the zero lower bounded variables had an unexpected sign.' );
            disp( 'Attempting to approximate around an alternative point.' );
            fprintf( '\n' );
            RepeatModelSolution = true;
            BadElements = dynareOBC.Constant( ( end - dynareOBC.NumberOfMax + 1 ) : end ) < 0;
            BadElements = BadElements(:).';
            NewFlip = xor( CurrentFlip, BadElements );
            if ismember( NewFlip, FlipsTried, 'rows' )
                error( 'dynareOBC:NonConvergenceConstantWrongSign', 'DynareOBC could not find a point to approximate around at which the risky steady states of the zero lower bounded variables were positive.' );
            end
            if isoctave || user_has_matlab_license( 'optimization_toolbox' )
                options_.solve_algo = 0;
            else
                options_.solve_algo = 4;
            end
            options_.maxit = 100;
            options_.steadystate_flag = 0;
            [ M_, oo_, info ] = homotopy3( [ 4 * ones( dynareOBC.NumberOfMax, 1 ), ( M_.param_nbr - dynareOBC.NumberOfMax ) + ( 1 : dynareOBC.NumberOfMax ).', CurrentFlip.', NewFlip.' ], 10000, M_, options_, oo_ );
            if info(1) ~= 0
                error( 'dynareOBC:FlipAlternativeSteadyState', 'DynareOBC failed to find the steady-state of the model with the constraint(s) flipped.' );
            end
            CurrentFlip = NewFlip;
            FlipsTried = [ FlipsTried; CurrentFlip ]; %#ok<AGROW>
        end
    end

    if Info ~= 0
        error( 'dynareOBC:FailedToSolve', 'DynareOBC failed to find a solution to the model.' );
    end

    %% Simulating

    if dynareOBC.IRFPeriods > 0 || dynareOBC.SimulationPeriods > 0 || dynareOBC.Smoothing
    
        fprintf( '\n' );
        disp( 'Preparing to simulate the model.' );
        fprintf( '\n' );

        rng( 'default' );

        if ~isempty( dynareOBC.IRFShocks )
            [ ~, dynareOBC.ShockSelect ] = ismember( dynareOBC.IRFShocks, cellstr( M_.exo_names ) );
        else
            dynareOBC.ShockSelect = 1 : dynareOBC.OriginalNumVarExo;
        end
        if ~isfield( oo_, 'irfs' ) || isempty( oo_.irfs )
            oo_.irfs = struct;
        end

        dynareOBC = orderfields( dynareOBC );
        
        if ~isempty( dynareOBC.IRFsForceAtBoundIndices ) || ~isempty( dynareOBC.IRFsForceNotAtBoundIndices )
            if dynareOBC.SlowIRFs
                fprintf( '\n' );
                disp( 'Ignoring IRFsForceAtBoundIndices and IRFsForceNotAtBoundIndices due to SlowIRFs option.' );
                fprintf( '\n' );
                dynareOBC.IRFsForceAtBoundIndices = [];
                dynareOBC.IRFsForceNotAtBoundIndices = [];
            elseif ~dynareOBC.NoCubature
                fprintf( '\n' );
                disp( 'Ignoring IRFsForceAtBoundIndices and IRFsForceNotAtBoundIndices due to cubature being enabled.' );
                fprintf( '\n' );
                dynareOBC.IRFsForceAtBoundIndices = [];
                dynareOBC.IRFsForceNotAtBoundIndices = [];
            else
                if isempty( dynareOBC.IRFsForceAtBoundIndices )
                    dynareOBC.IRFsForceAtBoundIndices = [];
                elseif ~isnumeric( dynareOBC.IRFsForceAtBoundIndices )
                    if dynareOBC.IRFsForceAtBoundIndices( 1 ) ~= '['
                        dynareOBC.IRFsForceAtBoundIndices = [ '[' dynareOBC.IRFsForceAtBoundIndices ];
                    end
                    if dynareOBC.IRFsForceAtBoundIndices( end ) ~= ']'
                        dynareOBC.IRFsForceAtBoundIndices = [ dynareOBC.IRFsForceAtBoundIndices ']' ];
                    end
                    dynareOBC.IRFsForceAtBoundIndices = eval( dynareOBC.IRFsForceAtBoundIndices );
                end
                if isempty( dynareOBC.IRFsForceNotAtBoundIndices )
                    dynareOBC.IRFsForceNotAtBoundIndices = [];
                elseif ~isnumeric( dynareOBC.IRFsForceNotAtBoundIndices )
                    if dynareOBC.IRFsForceNotAtBoundIndices( 1 ) ~= '['
                        dynareOBC.IRFsForceNotAtBoundIndices = [ '[' dynareOBC.IRFsForceNotAtBoundIndices ];
                    end
                    if dynareOBC.IRFsForceNotAtBoundIndices( end ) ~= ']'
                        dynareOBC.IRFsForceNotAtBoundIndices = [ dynareOBC.IRFsForceNotAtBoundIndices ']' ];
                    end
                    dynareOBC.IRFsForceNotAtBoundIndices = eval( dynareOBC.IRFsForceNotAtBoundIndices );
                end
            end
        else
            dynareOBC.IRFsForceAtBoundIndices = [];
            dynareOBC.IRFsForceNotAtBoundIndices = [];
        end

        if ~dynareOBC.NoCubature || dynareOBC.SlowIRFs || dynareOBC.MLVSimulationMode > 1 || dynareOBC.SimulateOnGridPoints
            OpenPool;
        end
        StoreGlobals( M_, options_, oo_, dynareOBC );

        if dynareOBC.IRFPeriods > 0
            fprintf( '\n' );
            disp( 'Simulating IRFs.' );
            fprintf( '\n' );

            if dynareOBC.SlowIRFs
                if dynareOBC.MedianIRFs && ~dynareOBC.IRFsAroundZero
                    fprintf( '\n' );
                    disp( 'Note that due to the non-linearity of the median, the level of median IRFs is somewhat artificial, so the resulting IRFs may appear to violate the bound.' );
                    disp( 'To remove the appearance of bound violation, using the IRFsAroundZero option may be sensible.' );
                    fprintf( '\n' );
                end
                [ oo_, dynareOBC ] = SlowIRFs( M_, oo_, dynareOBC );
            else
                if dynareOBC.Order > 1 || ~dynareOBC.NoCubature
                    fprintf( '\n' );
                    disp( 'Note that IRFs generated with FastIRFs are an approximation to the true average IRF.' );
                    if ~dynareOBC.IRFsAroundZero
                        disp( 'The level of FastIRFs is particularly artificial, so FastIRFs may appear to violate the bound.' );
                        disp( 'To remove the appearance of bound violation, using the IRFsAroundZero option may be sensible.' );
                    end
                    disp( 'You should always invoke DynareOBC with the SlowIRFs or MedianIRFs options when producing the final set of graphs for a paper.' );
                    fprintf( '\n' );
                end
                [ oo_, dynareOBC ] = FastIRFs( M_, oo_, dynareOBC );
            end
        end

        if dynareOBC.SimulationPeriods > 0
            fprintf( '\n' );
            disp( 'Running stochastic simulation.' );
            fprintf( '\n' );

            [ oo_, dynareOBC ] = RunStochasticSimulation( M_, options_, oo_, dynareOBC );
        end
        
        if dynareOBC.Smoothing
            error( 'Smoothing is disabled in this version. A new release featuring smoothing is coming soon.' );
            
            fprintf( '\n' ); %#ok<UNRCH>
            disp( 'Running smoothing.' );
            fprintf( '\n' );

            [ oo_, dynareOBC ] = RunSmoothing( M_, options_, oo_, dynareOBC );
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
    
    end

    dynareOBC = orderfields( dynareOBC );
    
    for i = 1 : M_.param_nbr
        assignin( 'base', ParamNames{ i }, M_.params( i ) );
    end
    evalin( 'base', 'dynareOBCTempPostScript;' );
end
