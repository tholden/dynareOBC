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

    warning( 'off', 'MATLAB:lang:cannotClearExecutingFunction' );
    dynare( InputFileName, run1varargin{:} );

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

    if dynareOBC.NumberOfMax == 0
        dynareOBC.NoCubature = true;
        dynareOBC.Global = false;
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
            dynareOBC.TimeToSolveParametrically = 0;
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
        dynareOBC.TimeToSolveParametrically = 0;
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

    fprintf( '\n' );
    disp( 'Performing second dynare run to get the steady-state.' );
    fprintf( '\n' );

    steadystatemfilename = [ dynareOBC.BaseFileName '_steadystate.m' ];
    if exist( steadystatemfilename, 'file' )
        copyfile( steadystatemfilename, 'dynareOBCTemp2_steadystate.m', 'f' );
    end

    global options_
    options_.solve_tolf = eps;
    options_.solve_tolx = eps;
    dynare( 'dynareOBCTemp2.mod', basevarargin{:} );
    global oo_ M_
    oo_.steady_state = oo_.dr.ys;

    Generate_dynareOBCTempGetMaxArgValues( dynareOBC.NumberOfMax, 'dynareOBCTemp2_static' );

    if LogLinear
        MaxArgValues = dynareOBCTempGetMaxArgValues( exp( oo_.steady_state ), [ oo_.exo_steady_state; oo_.exo_det_steady_state ], M_.params );
    else
        MaxArgValues = dynareOBCTempGetMaxArgValues( oo_.steady_state, [ oo_.exo_steady_state; oo_.exo_det_steady_state ], M_.params );
    end
    if any( MaxArgValues( :, 1 ) == MaxArgValues( :, 2 ) )
        error( 'dynareOBC:JustBinding', 'dynareOBC does not support cases in which the constraint just binds in steady-state.' );
    end

    if dynareOBC.MLVSimulationMode > 0
        fprintf( '\n' );
        disp( 'Generating code to recover MLVs.' );
        fprintf( '\n' );
        dynareOBC.OriginalLeadLagIncidence = M_.lead_lag_incidence;
        dynareOBC = Generate_dynareOBCTempGetMLVs( M_, dynareOBC, 'dynareOBCTemp2_dynamic' );
    else
        dynareOBC.MLVNames = {};
    end

    if M_.orig_endo_nbr ~= M_.endo_nbr
        error( 'dynareOBC:AuxiliaryVariables', 'dynareOBC is unsupported on models with lags or leads on exogenous variables, or lags or leads on endogenous variables greater than one period.\nPlease manually add additional variables for these lags and leads.\nFor example, to introduce lags of an exogenous variable e, define a new endogenous variable e_ENDO with equation e_ENDO = e, then replace e(-1) with e_ENDO(-1).\nAnd, to introduce a second lag of an endogenous variable x, introduce a new endogenous variable x_LAG with equation x_LAG = x(-1), then replace x(-2) with x_LAG(-1).' );
    end

    %% Preparation for the final runs
    
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
                    if ~isempty( strfind( lower( CurrentSubFieldName ), 'tol' ) )
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
        [ ToInsertInModelAtStart, FileLines ] = ConvertFromLogLinearToMLVs( FileLines, Indices, dynareOBC.EndoVariables, M_ );
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

    dynareOBC.OriginalNumParams = CurrentNumParams;
    if dynareOBC.ZeroParameterInserted
        dynareOBC.OriginalNumParams = dynareOBC.OriginalNumParams - 1;
    end

    dynareOBC.OriginalNumVar = CurrentNumVar;
    dynareOBC.OriginalNumVarExo = CurrentNumVarExo;

    %% Global polynomial approximation

    if dynareOBC.Global
        if dynareOBC.NoCubature
            error( 'dynareOBC:GlobalNoCubature', 'You cannot specify both the NoCubature and the Global options.' );
        end
        
        fprintf( '\n' );
        disp( 'Beginning to solve for the global polynomial approximation to the bounds.' );
        fprintf( '\n' );

        dynareOBC.StateVariableAndShockCombinations = GenerateCombinations( length( dynareOBC.StateVariablesAndShocks ), dynareOBC.Order );
        [ GlobalApproximationParameters, MaxArgValues, AmpValues ] = RunGlobalSolutionAlgorithm( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC );
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
    dynareOBC.InternalIRFPeriods = max( dynareOBC.TimeToEscapeBounds, dynareOBC.TimeToReturnToSteadyState );
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

    [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = ...
        InsertShadowEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumVar, dynareOBC, GlobalApproximationParameters, AmpValues );

    [ FileLines, Indices ] = PerformInsertion( ToInsertBeforeModel, Indices.ModelStart, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtStart, Indices.ModelStart + 1, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtEnd, Indices.ModelEnd, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInShocks, Indices.ShocksStart + 1, FileLines, Indices );
    [ FileLines, ~ ] = PerformInsertion( [ { SteadyStateBlockDeclaration } ToInsertInInitVal { 'end;' } ], Indices.ModelEnd + 1, FileLines, Indices );

    %Save the result

    FileText = strjoin( [ FileLines { [ 'stoch_simul(order=' int2str( dynareOBC.Order ) ',solve_algo=' int2str( SolveAlgo ) ',pruning,sylvester=fixed_point,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' ); % dr=cyclic_reduction,
    newmodfile = fopen( 'dynareOBCTemp3.mod', 'w' );
    fprintf( newmodfile, '%s', FileText );
    fclose( newmodfile );

    %% Solution

    fprintf( '\n' );
    disp( 'Making the final call to dynare, as a first step in solving the full model.' );
    fprintf( '\n' );

    options_.solve_tolf = eps;
    options_.solve_tolx = eps;
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

    if ( dynareOBC.Estimation || dynareOBC.Smoothing ) && any( any( M_.Sigma_e - eye( size( M_.Sigma_e ) ) ~= 0 ) )
        error( 'dynareOBC:UnsupportedCovariance', 'For estimation, all shocks must be given unit variance in the shocks block. If you want a non-unit variance, multiply the shock within the model block.' );
    end
    if dynareOBC.Estimation
        if dynareOBC.Global
            error( 'dynareOBC:UnsupportedGlobalEstimation', 'Estimation of models solved globally is not currently supported.' );
        end
        
        fprintf( '\n' );
        disp( 'Beginning the estimation of the model.' );
        fprintf( '\n' );
        
        dynareOBC.CalculateTheoreticalVariance = true;
        [ ~, dynareOBC.EstimationParameterSelect ] = ismember( dynareOBC.EstimationParameterNames, cellstr( M_.param_names ) );
        NumObservables = length( dynareOBC.VarList );
        NumEstimatedParams = length( dynareOBC.EstimationParameterSelect );
        LBTemp = dynareOBC.EstimationParameterBounds(1,:)';
        UBTemp = dynareOBC.EstimationParameterBounds(2,:)';
        LBTemp( ~isfinite( LBTemp ) ) = -Inf;
        UBTemp( ~isfinite( UBTemp ) ) = Inf;
        EstimatedParameters = [ M_.params( dynareOBC.EstimationParameterSelect ); 0.0001 * ones( NumObservables, 1 ) ];
        
        [ TwoNLogLikelihood, ~, M_, options_, oo_, dynareOBC ] = EstimationObjective( EstimatedParameters, M_, options_, oo_, dynareOBC, true, false );
        dynareOBC = orderfields( dynareOBC );
        OpenPool;
        StoreGlobals( M_, options_, oo_, dynareOBC );
        disp( 'Initial log-likelihood:' );
        disp( -0.5 * TwoNLogLikelihood );
        
        OptiFunction = @( p ) EstimationObjective( p, M_, options_, oo_, dynareOBC, false, false );
        OptiLB = [ LBTemp; zeros( NumObservables, 1 ) ];
        OptiUB = [ UBTemp; Inf( NumObservables, 1 ) ];
        MinimisationFunctions = strsplit( dynareOBC.MinimisationFunctions, { ',', ';', '#' } );
        for i = 1 : length( MinimisationFunctions )
            FMinEstimateFunctor = str2func( MinimisationFunctions{ i } );
            [ EstimatedParameters, TwoNLogLikelihood ] = FMinEstimateFunctor( OptiFunction, EstimatedParameters, OptiLB, OptiUB );
        end
        disp( 'Final log-likelihood:' );
        disp( -0.5 * TwoNLogLikelihood );
 
        
        [ TwoNLogLikelihood, ~, M_, options_, oo_, dynareOBC ] = EstimationObjective( EstimatedParameters, M_, options_, oo_, dynareOBC, true, false );
        dynareOBC = orderfields( dynareOBC );
        StoreGlobals( M_, options_, oo_, dynareOBC );
        disp( 'Paranoid verification of final log-likelihood:' );
        disp( -0.5 * TwoNLogLikelihood );
        
        if dynareOBC.SkipStandardErrors
            disp( 'Final parameter estimates:' );
            for i = 1 : NumEstimatedParams
                fprintf( '%s:\t\t%#.17g\n', strtrim( M_.param_names( dynareOBC.EstimationParameterSelect( i ), : ) ), EstimatedParameters( i ) );
            end
            fprintf( '\n' );
            disp( 'Final measurement error standard deviation estimates:' );
            for i = 1 : NumObservables
                fprintf( '%s:\t\t%#.17g\n', dynareOBC.VarList{ i }, EstimatedParameters( NumEstimatedParams + i ) );
            end
        else
            disp( 'Calculating standard errors.' );
            fprintf( '\n' );
            ObservationCount = size( dynareOBC.EstimationData, 1 );
            OneOverRootObservationCount = 1 / sqrt( ObservationCount );
            
            JacobianScoreVector = GetJacobian( @( p ) GetScoreVector( p, M_, options_, oo_, dynareOBC ), EstimatedParameters, ObservationCount );
            [ ~, TriaJacobianScoreVector ] = qr( JacobianScoreVector * OneOverRootObservationCount, 0 );
            
            HessianLogLikelihood = GetJacobian( @( p1 ) GetJacobian( @( p2 ) -0.5 * EstimationObjective( p2, M_, options_, oo_, dynareOBC, false, false ), p1, 1 )', EstimatedParameters, length( EstimatedParameters ) );
            HessianLogLikelihood = ( 0.5 / ObservationCount ) * ( HessianLogLikelihood + HessianLogLikelihood' );
            
            RootEstimatedParameterCovarianceMatrix = OneOverRootObservationCount * ( HessianLogLikelihood \ ( TriaJacobianScoreVector' ) );
            EstimatedParameterCovarianceMatrix = RootEstimatedParameterCovarianceMatrix * RootEstimatedParameterCovarianceMatrix';
            dynareOBC.EstimatedParameterCovarianceMatrix = EstimatedParameterCovarianceMatrix;
            EstimatedParameterStandardErrors = sqrt( diag( EstimatedParameterCovarianceMatrix ) );

            disp( 'Final parameter estimates:' );
            for i = 1 : NumEstimatedParams
                fprintf( '%s:\t\t%#.17g\t\t(%#.17g)\n', strtrim( M_.param_names( dynareOBC.EstimationParameterSelect( i ), : ) ), EstimatedParameters( i ), EstimatedParameterStandardErrors( i ) );
            end
            fprintf( '\n' );
            disp( 'Final measurement error standard deviation estimates:' );
            for i = 1 : NumObservables
                fprintf( '%s:\t\t%#.17g\t\t(%#.17g)\n', dynareOBC.VarList{ i }, EstimatedParameters( NumEstimatedParams + i ), EstimatedParameterStandardErrors( NumEstimatedParams + i ) );
            end
        end
        
        M_.params( dynareOBC.EstimationParameterSelect ) = EstimatedParameters( 1 : NumEstimatedParams );
    end

    [ Info, M_, options_, oo_ ,dynareOBC ] = ModelSolution( ~dynareOBC.Estimation, M_, options_, oo_, dynareOBC );

    if Info ~= 0
        error( 'dynareOBC:FailedToSolve', 'dynareOBC failed to find a solution to the model.' );
    end

    %% Simulating

    if dynareOBC.IRFPeriods > 0 || dynareOBC.SimulationPeriods > 0 || dynareOBC.Smoothing
    
        fprintf( '\n' );
        disp( 'Preparing to simulate the model.' );
        fprintf( '\n' );

        [ oo_, dynareOBC ] = SimulationPreparation( M_, oo_, dynareOBC );

        dynareOBC = orderfields( dynareOBC );

        if ~dynareOBC.NoCubature || dynareOBC.SlowIRFs || dynareOBC.MLVSimulationMode > 1
            OpenPool;
        end
        StoreGlobals( M_, options_, oo_, dynareOBC );

        if dynareOBC.IRFPeriods > 0
            fprintf( '\n' );
            disp( 'Simulating IRFs.' );
            fprintf( '\n' );

            if dynareOBC.SlowIRFs
                [ oo_, dynareOBC ] = SlowIRFs( M_, oo_, dynareOBC );
            else
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
            fprintf( '\n' );
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
end
