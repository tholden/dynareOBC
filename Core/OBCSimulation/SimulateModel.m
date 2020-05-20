function Simulation = SimulateModel( ShockSequence, DisplayProgress, InitialFullState, SkipMLVSimulation, DisableParFor )

    global M_ options_ oo_ dynareOBC_
        
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
   
    SimulationLength = size( ShockSequence, 2 );
    OriginalSimulationLength = SimulationLength;
    
    if nargin < 2
        DisplayProgress = true;
    end
    if nargin < 3 || isempty( InitialFullState )
        Mean_z = full( dynareOBC_.Mean_z );
        dr = oo_.dr;
        nEndo = M_.endo_nbr;
        nState = length( dynareOBC_.SelectState );
        InitialFullState = struct;
        InitialFullState.bound_offset = zeros( nEndo, 1 );
        InitialFullState.first = Mean_z( dr.inv_order_var );
        InitialFullState.total = bsxfun( @plus, InitialFullState.first, full( dynareOBC_.Constant ) );

        if dynareOBC_.Order > 1
            InitialFullState.second = Mean_z( nEndo + dr.inv_order_var );
            InitialFullState.total = InitialFullState.total + InitialFullState.second;
            if dynareOBC_.Order > 2
                InitialFullState.first_sigma_2 = Mean_z( 2 * nEndo + nState * nState + dr.inv_order_var );
                InitialFullState.third = Mean_z( 3 * nEndo + nState * nState + dr.inv_order_var );
                InitialFullState.total = InitialFullState.total + InitialFullState.first_sigma_2 + InitialFullState.third;
            end
        end
        InitialFullState.total_with_bounds = InitialFullState.total;
        InitialFullState = orderfields( InitialFullState );
    else
        % DisplayProgress = false;
        InitialFullState = orderfields( InitialFullState );
    end
    if nargin < 4
        SkipMLVSimulation = false;
    end
    if nargin < 5
        DisableParFor = ~DisplayProgress;
    end
    if nargin < 3 && dynareOBC_.SimulateOnGridPoints
        %% Grid simulation
        dynareOBC_.MLVSimulationSubSample = 2;
        
        GridOffsets = ShockSequence( 1:nEndo, 1:2:end );
        nExoOriginal = dynareOBC_.OriginalNumVarExo;
        ShockSequence( (nExoOriginal+1):end, : ) = [];
        ShockSequence( :, 1:2:end ) = 0;
        TempShockSequence = ShockSequence( :, 2:2:end );
        NumberOfGridPoints = size( GridOffsets, 2 );
        Simulation = InitialFullState;
        SimulationFieldNames = fieldnames( Simulation );
        for i = 1 : length( SimulationFieldNames )
            CurrentFieldName = SimulationFieldNames{ i };
            if ~strcmp( CurrentFieldName, 'constant' )
                Simulation.( CurrentFieldName ) = repmat( Simulation.( CurrentFieldName ), 1, SimulationLength );
            end
        end        
        Simulation.first( :, 1:2:end ) = Simulation.first( :, 1:2:end ) + GridOffsets;
        Simulation.total( :, 1:2:end ) = Simulation.total( :, 1:2:end ) + GridOffsets;
        Simulation.total_with_bounds( :, 1:2:end ) = Simulation.total_with_bounds( :, 1:2:end ) + GridOffsets;

        if DisplayProgress
            p = TimedProgressBar( NumberOfGridPoints, 50, 'Computing simulations on grid points. Predicted to finish within ', '. Progress: ', 'Computing simulations on grid points.               Completed in ' );
        else
            p = [];
        end
        WarningGenerated = false;
        GridSimulations = cell( NumberOfGridPoints, 1 );
        if DisableParFor
            for k = 1 : NumberOfGridPoints
                lastwarn( '' );
                ParallelWarningState = warning( 'off', 'all' );
                try
                    InnerInitialFullState = struct;
                    for i = 1 : length( SimulationFieldNames )
                        CurrentFieldName = SimulationFieldNames{i};
                        if ~strcmp( CurrentFieldName, 'constant' )
                            InnerInitialFullState.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, 2 * k - 1 );
                        end
                    end
                    GridSimulations{ k } = SimulateModel( TempShockSequence( :, k ), false, InnerInitialFullState, true, true );
                catch Error
                    warning( ParallelWarningState );
                    rethrow( Error );
                end
                warning( ParallelWarningState );
                WarningGenerated = WarningGenerated | ( ~isempty( lastwarn ) );
                if ~isempty( p )
                    p.progress;
                end
            end
        else
            parfor k = 1 : NumberOfGridPoints
                lastwarn( '' );
                ParallelWarningState = warning( 'off', 'all' );
                try
                    InnerInitialFullState = struct;
                    for i = 1 : length( SimulationFieldNames )
                        CurrentFieldName = SimulationFieldNames{i};
                        if ~strcmp( CurrentFieldName, 'constant' )
                            InnerInitialFullState.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, 2 * k - 1 ); %#ok<PFBNS>
                        end
                    end
                    GridSimulations{ k } = SimulateModel( TempShockSequence( :, k ), false, InnerInitialFullState, true, true );
                catch Error
                    warning( ParallelWarningState );
                    rethrow( Error );
                end
                warning( ParallelWarningState );
                WarningGenerated = WarningGenerated | ( ~isempty( lastwarn ) );
                if ~isempty( p )
                    p.progress;
                end
            end
        end
        if ~isempty( p )
            p.stop;
        end
        if WarningGenerated
            warning( 'dynareOBC:InnerGridWarning', 'Warnings were generated in the inner loop responsible for computing simulations on grid points.' );
        end
        for k = 1 : NumberOfGridPoints
            for i = 1 : length( SimulationFieldNames )
                CurrentFieldName = SimulationFieldNames{i};
                if ~strcmp( CurrentFieldName, 'constant' )
                    Simulation.( CurrentFieldName )( :, 2 * k ) = GridSimulations{ k }.( CurrentFieldName );
                end
            end
        end
    else
        %% Standard simulation
        if dynareOBC_.UseSimulationCode && ( dynareOBC_.CompileSimulationCode || dynareOBC_.Estimation || dynareOBC_.Smoothing )
            try
                if dynareOBC_.Estimation
                    if dynareOBC_.Sparse
                        Simulation = dynareOBCTempCustomLanMeyerGohdePrunedSimulation( MakeFull( oo_.dr ), full( ShockSequence ), int32( SimulationLength ), InitialFullState );
                    else
                        Simulation = dynareOBCTempCustomLanMeyerGohdePrunedSimulation( oo_.dr, ShockSequence, int32( SimulationLength ), InitialFullState );
                    end
                else
                    if dynareOBC_.Sparse
                        Simulation = dynareOBCTempCustomLanMeyerGohdePrunedSimulation( full( ShockSequence ), int32( SimulationLength ), InitialFullState );
                    else
                        Simulation = dynareOBCTempCustomLanMeyerGohdePrunedSimulation( ShockSequence, int32( SimulationLength ), InitialFullState );
                    end
                end
            catch Error
                warning( 'dynareOBC:ErrorInCompiledCustomLanMeyerGohdePrunedSimulation',  [ 'Not using the compiled version of the simulation code due to the error: ' Error.message ] );
                Simulation = [];
            end
        else
            Simulation = [];
        end
        if isempty( Simulation )
            if DisplayProgress
                if isempty( dynareOBC_.OtherMOD )
                    p = TimedProgressBar( ceil( SimulationLength / 10 ), 50, 'Computing base simulation. Predicted to finish within ', '. Progress: ', 'Computing base simulation.               Completed in ' );
                else
                    p = [];
                    disp( ' ' );
                    disp( 'Computing base simulation.' );
                    disp( ' ' );
                end
            else
                p = [];
            end
            if isempty( p )
                Simulation = LanMeyerGohdePrunedSimulation( M_, oo_.dr, ShockSequence, SimulationLength, dynareOBC_.Order, 1, InitialFullState );
            else
                Simulation = LanMeyerGohdePrunedSimulation( M_, oo_.dr, ShockSequence, SimulationLength, dynareOBC_.Order, 1, InitialFullState, @(x) x.progress, p, 100 );
            end
            if ~isempty( p )
                p.stop;
            end
        end
        
        % StructFieldNames = setdiff( fieldnames( Simulation ), 'constant' );
        StructFieldNames = fieldnames( Simulation );

        SelectState = dynareOBC_.SelectState;

        Simulation.bound_offset = zeros( M_.endo_nbr, SimulationLength );

        ghx = oo_.dr.ghx;
 
        if dynareOBC_.NumberOfMax > 0
            pMat = dynareOBC_.pMat;
           y = zeros( Ts * ns, 1 );

            BoundOffsetOriginalOrder = InitialFullState.bound_offset;
            BoundOffsetDROrder = BoundOffsetOriginalOrder( oo_.dr.order_var );

            BoundOffsetDROrderNext = ghx * BoundOffsetDROrder( SelectState );
            BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo_.dr.inv_order_var );

            Shock = zeros( M_.exo_nbr, 1 );

            OrderText = dynareOBC_.OrderText;

            % SimulationLengthString = int2str( SimulationLength );

            CurrentStateWithoutBound = struct;

            WarningMessages = { };
            WarningIDs = { };
            WarningPeriods = { };

            if DisplayProgress 
                if isempty( dynareOBC_.OtherMOD )
                    p = TimedProgressBar( ceil( SimulationLength / 10 ), 50, 'Computing simulation. Predicted to finish within ', '. Progress: ', 'Computing simulation.               Completed in ' );
                else
                    p = [];
                    disp( ' ' );
                    disp( 'Computing simulation.' );
                    disp( ' ' );
                end
            else
                p = [];
            end
            
            for t = 1 : SimulationLength
                if ~isempty( dynareOBC_.OtherMOD ) && dynareOBC_.OtherMODFileSwitchToProbability > realmin
                    Uniform = rand;
                    if Uniform <= dynareOBC_.OtherMODFileSwitchToProbability
                        SimulationLength = t - 1;
                        if DisplayProgress
                            disp( [ 'Exogenously switching steady states after ' int2str( t - 1 ) ' periods due to a random draw.' ] );
                        end
                        p = [];
                        break
                    end
                end
                
                lastwarn( '' );
                WarningState = warning( 'off', 'all' );
                try
                    Shock( :, 1 ) = ShockSequence( :, t );

                    for i = 1 : length( StructFieldNames )
                        CurrentFieldName = StructFieldNames{ i };
                        if ~strcmp( CurrentFieldName, 'constant' )
                            CurrentStateWithoutBound.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, t );
                        end
                    end
                    CurrentStateWithoutBound.( OrderText ) = CurrentStateWithoutBound.( OrderText ) + BoundOffsetOriginalOrderNext;

                    ReturnPathStruct = ExpectedReturn( CurrentStateWithoutBound, M_, oo_.dr, dynareOBC_ );
                    ReturnPath = ReturnPathStruct.total;        

                    UnconstrainedReturnPath = vec( ReturnPath( dynareOBC_.VarIndices_ZeroLowerBounded, : )' );

                    yOld = y;
                    try
                        if dynareOBC_.Cubature
                            [ y, GlobalVarianceShare ] = PerformCubature( UnconstrainedReturnPath, oo_, dynareOBC_, ReturnPathStruct.first, DisableParFor );
                            if dynareOBC_.Global
                                y = SolveGlobalBoundsProblem( y, GlobalVarianceShare, UnconstrainedReturnPath, ReturnPath( dynareOBC_.VarIndices_ZeroLowerBoundedLongRun, : )', dynareOBC_ );
                            end
                        else
                            y = SolveBoundsProblem( UnconstrainedReturnPath );
                        end
                        [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );
                    catch Error
                        if dynareOBC_.IgnoreBoundFailures
                            Reshaped_yOld = reshape( yOld, Ts, ns );
                            y = [ Reshaped_yOld( 2:end, : ); zeros( 1, ns ) ];
                            y = y(:);
                            warning( 'dynareOBC:BoundFailureCaught', [ 'The following error was caught while solving the bounds problem:\n' Error.message '\nContinuing due to IgnoreBoundFailures option.' ] );
                        elseif ~isempty( dynareOBC_.OtherMOD )
                            warning( WarningState );
                            SimulationLength = t - 1;
                            if DisplayProgress
                                disp( [ 'Endogenously switching steady states after ' int2str( t - 1 ) ' periods due to problem in simulation: ' Error.message ] );
                            end
                            p = [];
                            break
                        else
                            rethrow( Error );
                        end
                    end

                    BoundOffsetDROrder = BoundOffsetDROrderNext + pMat * y;
                    BoundOffsetOriginalOrder = BoundOffsetDROrder( oo_.dr.inv_order_var, : );

                    BoundOffsetDROrderNext = ghx * BoundOffsetDROrder( SelectState );
                    BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo_.dr.inv_order_var );

                    Simulation.bound_offset( :, t ) = BoundOffsetOriginalOrder;
                catch Error
                    warning( WarningState );
                    rethrow( Error );
                end

                [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );

                warning( WarningState );

                if ~isempty( p ) && rem( t, 10 ) == 0
                    p.progress;
                end

            end
            if ~isempty( p )
                p.stop;
            end

            for i = 1 : length( WarningIDs )
                WarningString = sprintf( 'The following warning(s) was generated during simulation in periods: %d', WarningPeriods{i}( 1 ) );
                for j = 2 : length( WarningPeriods{i} )
                    WarningString = sprintf( '%s, %d', WarningString, WarningPeriods{i}( j ) );
                end
                warning( 'dynareOBC:NestedWarning', '%s', WarningString );
                if ~isempty( WarningIDs{i} )
                    warning( WarningIDs{i}, WarningMessages{i} );
                else
                    warning( WarningMessages{i} );
                end
            end
        end

        Simulation.total_with_bounds = Simulation.total + Simulation.bound_offset;        
        SimulationFieldNames = [ StructFieldNames; { 'bound_offset'; 'total_with_bounds' } ];
    end
    
    %% Common
    if dynareOBC_.MLVSimulationMode > 0 && ( ~SkipMLVSimulation )
        MLVNames = dynareOBC_.MLVNames;
        nMLV = length( MLVNames );
        Simulation.MLVsWithBounds = struct;
        Simulation.MLVsWithoutBounds = struct;
        OriginalVarSelect = false( M_.endo_nbr, 1 );
        OriginalVarSelect( 1:dynareOBC_.OriginalNumVar ) = true;
        LagValuesWithBounds = InitialFullState.total_with_bounds( OriginalVarSelect );
        LagValuesWithoutBounds = InitialFullState.total( OriginalVarSelect );
               
        if dynareOBC_.OriginalMaximumEndoLag > 0
            LagIndices = dynareOBC_.OriginalLeadLagIncidence( dynareOBC_.OriginalMaximumEndoLag, : ) > 0;
        else
            LagIndices = [];
        end
        CurrentIndices = dynareOBC_.OriginalLeadLagIncidence( dynareOBC_.OriginalMaximumEndoLag + 1, : ) > 0;
        if size( dynareOBC_.OriginalLeadLagIncidence, 1 ) >= dynareOBC_.OriginalMaximumEndoLag + 2
            LeadIndices = dynareOBC_.OriginalLeadLagIncidence( dynareOBC_.OriginalMaximumEndoLag + 2, : ) > 0;
        else
            LeadIndices = [];
        end

        FutureValues = nan( sum( LeadIndices ), 1 );
        
        if dynareOBC_.MLVSimulationMode > 1
            PositiveVarianceShocks = setdiff( 1:dynareOBC_.OriginalNumVarExo, find( diag(M_.Sigma_e) == 0 ) );
            NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
            SqrtmSigma_e = spsqrtm( M_.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );
        end
        
        ParamVec = M_.params;
        SteadyState = full( oo_.dr.ys( 1:dynareOBC_.OriginalNumVar ) );
        
        WarningMessages = { };
        WarningIDs = { };
        WarningPeriods = { };

        if dynareOBC_.MLVSimulationMode > 1
            if DisplayProgress
                fprintf( '\nCalculating cubature points and weights.\n' );
            end
            if dynareOBC_.MLVSimulationMode == 2
                [ Weights, Points, NumPoints ] = fwtpts( NumberOfPositiveVarianceShocks, max( 0, ceil( 0.5 * ( dynareOBC_.MLVSimulationAccuracy - 1 ) ) ) );
            else
                NumPoints = 2^(1+dynareOBC_.MLVSimulationAccuracy)-1;
                Weights = ones( 1, NumPoints ) * ( 1 / NumPoints );
                Points = SobolSequence( NumberOfPositiveVarianceShocks, NumPoints );
            end
            FutureShocks = SqrtmSigma_e * Points;
            if DisplayProgress
                fprintf( 'Found a cubature rule with %d points.\n', NumPoints );
            end
        end
        
        if DisplayProgress
            if isempty( dynareOBC_.OtherMOD )
                p = TimedProgressBar( ceil( SimulationLength / 10 ), 50, 'Computing model local variable paths. Predicted to finish within ', '. Progress: ', 'Computing model local variable paths.               Completed in ' );
            else
                p = [];
                disp( ' ' );
                disp( 'Computing model local variable paths.' );
                disp( ' ' );
            end
        else
            p = [];
        end
        
        for i = 1 : nMLV
            MLVName = MLVNames{i};
            Simulation.MLVsWithBounds.( MLVName ) = NaN( 1, SimulationLength );
            Simulation.MLVsWithoutBounds.( MLVName ) = NaN( 1, SimulationLength );
        end
        
        for t = 1 : SimulationLength
            % clear the last warning
            lastwarn( '' );
            % temporarily disable warnings
            WarningState = warning( 'off', 'all' );
            % wrap in a try catch block to ensure they're re-enabled
            try
                CurrentValuesWithBounds = Simulation.total_with_bounds( OriginalVarSelect, t );
                CurrentValuesWithoutBounds = Simulation.total( OriginalVarSelect, t );
                if mod( t, dynareOBC_.MLVSimulationSubSample ) == 0
                    CurrentShock = ShockSequence( :, t );
                    LagValuesWithBoundsLagIndices = LagValuesWithBounds( LagIndices );
                    LagValuesWithoutBoundsLagIndices = LagValuesWithoutBounds( LagIndices );
                    CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
                    CurrentValuesWithoutBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
                    if dynareOBC_.MLVSimulationMode > 1
                        InnerInitialFullState = struct;
                        for i = 1 : length( SimulationFieldNames )
                            CurrentFieldName = SimulationFieldNames{i};
                            if ~strcmp( CurrentFieldName, 'constant' )
                                InnerInitialFullState.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, t );
                            end
                        end
                        MLVValuesWithBounds = zeros( nMLV, 1 );
                        MLVValuesWithoutBounds = zeros( nMLV, 1 );
                        WarningGenerated = false;
                        NumberOfMax = dynareOBC_.NumberOfMax;
                        if DisableParFor
                            for PointIndex = 1 : NumPoints
                                lastwarn( '' );
                                ParallelWarningState = warning( 'off', 'all' );
                                try
                                    InnerShockSequence = FutureShocks( :, PointIndex );
                                    InnerSimulation = SimulateModel( InnerShockSequence, false, InnerInitialFullState, true, true );
                                    InnerFutureValuesWithBounds = InnerSimulation.total_with_bounds( OriginalVarSelect, 1 );
                                    InnerFutureValuesWithoutBounds = InnerSimulation.total( OriginalVarSelect, 1 );
                                    NewMLVValuesWithBounds = dynareOBCTempGetMLVs( full( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; InnerFutureValuesWithBounds( LeadIndices ) ] ), CurrentShock, ParamVec, SteadyState );
                                    if NumberOfMax > 0
                                        NewMLVValuesWithoutBounds = dynareOBCTempGetMLVs( full( [ LagValuesWithoutBoundsLagIndices; CurrentValuesWithoutBoundsCurrentIndices; InnerFutureValuesWithoutBounds( LeadIndices ) ] ), CurrentShock, ParamVec, SteadyState );
                                    else
                                        NewMLVValuesWithoutBounds = NewMLVValuesWithBounds;
                                    end
                                    MLVValuesWithBounds = MLVValuesWithBounds + NewMLVValuesWithBounds * Weights( PointIndex );
                                    MLVValuesWithoutBounds = MLVValuesWithoutBounds + NewMLVValuesWithoutBounds * Weights( PointIndex );
                                catch Error
                                    warning( ParallelWarningState );
                                    rethrow( Error );
                                end
                                warning( ParallelWarningState );
                                WarningGenerated = WarningGenerated | ( ~isempty( lastwarn ) );
                            end
                        else
                            parfor PointIndex = 1 : NumPoints
                                lastwarn( '' );
                                ParallelWarningState = warning( 'off', 'all' );
                                try
                                    InnerShockSequence = FutureShocks( :, PointIndex );
                                    InnerSimulation = SimulateModel( InnerShockSequence, false, InnerInitialFullState, true, true );
                                    InnerFutureValuesWithBounds = InnerSimulation.total_with_bounds( OriginalVarSelect, 1 );
                                    InnerFutureValuesWithoutBounds = InnerSimulation.total( OriginalVarSelect, 1 );
                                    NewMLVValuesWithBounds = dynareOBCTempGetMLVs( full( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; InnerFutureValuesWithBounds( LeadIndices ) ] ), CurrentShock, ParamVec, SteadyState );
                                    if NumberOfMax > 0
                                        NewMLVValuesWithoutBounds = dynareOBCTempGetMLVs( full( [ LagValuesWithoutBoundsLagIndices; CurrentValuesWithoutBoundsCurrentIndices; InnerFutureValuesWithoutBounds( LeadIndices ) ] ), CurrentShock, ParamVec, SteadyState );
                                    else
                                        NewMLVValuesWithoutBounds = NewMLVValuesWithBounds;
                                    end
                                    MLVValuesWithBounds = MLVValuesWithBounds + NewMLVValuesWithBounds * Weights( PointIndex );
                                    MLVValuesWithoutBounds = MLVValuesWithoutBounds + NewMLVValuesWithoutBounds * Weights( PointIndex );
                                catch Error
                                    warning( ParallelWarningState );
                                    rethrow( Error );
                                end
                                warning( ParallelWarningState );
                                WarningGenerated = WarningGenerated | ( ~isempty( lastwarn ) );
                            end
                        end
                        if WarningGenerated
                            warning( 'dynareOBC:InnerMLVWarning', 'Warnings were generated in the inner loop responsible for evaluating expectations of model local variables.' );
                        end
                    else
                        MLVValuesWithBounds = dynareOBCTempGetMLVs( full( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ] ), CurrentShock, ParamVec, SteadyState );
                        if dynareOBC_.NumberOfMax > 0
                            MLVValuesWithoutBounds = dynareOBCTempGetMLVs( full( [ LagValuesWithoutBoundsLagIndices; CurrentValuesWithoutBoundsCurrentIndices; FutureValues ] ), CurrentShock, ParamVec, SteadyState );
                        else
                            MLVValuesWithoutBounds = MLVValuesWithBounds;
                        end
                    end
                    for i = 1 : nMLV
                        MLVName = MLVNames{i};
                        Simulation.MLVsWithBounds.( MLVName )( t ) = MLVValuesWithBounds( i );
                        Simulation.MLVsWithoutBounds.( MLVName )( t ) = MLVValuesWithoutBounds( i );
                    end
                end
                LagValuesWithBounds = CurrentValuesWithBounds;
                LagValuesWithoutBounds = CurrentValuesWithoutBounds;
            catch Error
                warning( WarningState );
                if ~isempty( dynareOBC_.OtherMOD )
                    SimulationLength = t - 1;
                    if DisplayProgress
                        disp( [ 'Switching steady states after ' int2str( t - 1 ) ' periods due to problem in MLV simulation: ' Error.message ] );
                    end
                    p = [];
                    break
                else
                    rethrow( Error );
                end
            end
            
            [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );

            warning( WarningState );
            
            if ~isempty( p ) && rem( t, 10 ) == 0
                p.progress;
            end
        end
        if ~isempty( p )
            p.stop;
        end
        for i = 1 : length( WarningIDs )
            WarningString = sprintf( 'The following warning(s) were generated during the computation of model local variable paths in periods: %d', WarningPeriods{i}( 1 ) );
            for j = 2 : length( WarningPeriods{i} )
                WarningString = sprintf( '%s, %d', WarningString, WarningPeriods{i}( j ) );
            end
            warning( 'dynareOBC:NestedWarning', '%s', WarningString );
            if ~isempty( WarningIDs{i} )
                warning( WarningIDs{i}, WarningMessages{i} );
            else
                warning( WarningMessages{i} );
            end
        end
    else
        MLVNames = {};
        nMLV     = 0;
    end
    
    if SimulationLength < OriginalSimulationLength
        
        assert( ~isempty( dynareOBC_.OtherMOD ) );
        assert( size( ShockSequence, 2 ) == OriginalSimulationLength );
        
        if SimulationLength > 0
            
            InitialFullState = struct;

            for i = 1 : length( SimulationFieldNames )
                CurrentFieldName = SimulationFieldNames{ i };
                if ~strcmp( CurrentFieldName, 'constant' )
                    InitialFullState.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, SimulationLength );
                end
            end
            
        end
        
        InitialFullState.first = InitialFullState.first + InitialFullState.bound_offset + full( dynareOBC_.Constant );
        InitialFullState.bound_offset = zeros( size( InitialFullState.bound_offset ) );

        Files = dir( '**/dynareOBCTemp*' );
        [ ~, FilesSortOrder ] = sort( cellfun( @length, { Files.folder } ), 'descend' );
        Files = Files( FilesSortOrder );
        for i = 1 : length( Files )
            File = Files( i );
            movefile( [ File.folder '/' File.name ], [ File.folder '/' strrep( File.name, 'dynareOBCTemp', 'dynareOBCAltOtherTemp' ) ], 'f' );
        end
        Files = dir( '**/dynareOBCOtherTemp*' );
        [ ~, FilesSortOrder ] = sort( cellfun( @length, { Files.folder } ), 'descend' );
        Files = Files( FilesSortOrder );
        for i = 1 : length( Files )
            File = Files( i );
            movefile( [ File.folder '/' File.name ], [ File.folder '/' strrep( File.name, 'dynareOBCOtherTemp', 'dynareOBCTemp' ) ], 'f' );
        end
        Files = dir( '**/dynareOBCAltOtherTemp*' );
        [ ~, FilesSortOrder ] = sort( cellfun( @length, { Files.folder } ), 'descend' );
        Files = Files( FilesSortOrder );
        for i = 1 : length( Files )
            File = Files( i );
            movefile( [ File.folder '/' File.name ], [ File.folder '/' strrep( File.name, 'dynareOBCAltOtherTemp', 'dynareOBCOtherTemp' ) ], 'f' );
        end
        rehash path;
       
        OtherMOD = dynareOBC_.OtherMOD;
        
        dynareOBC_.OtherMOD = [];
        
        OriginalMOD = struct;
        OriginalMOD.dynareOBC = dynareOBC_;
        OriginalMOD.M         = M_;
        OriginalMOD.options   = options_;
        OriginalMOD.oo        = oo_;
        
        dynareOBC_ = OtherMOD.dynareOBC;
        M_         = OtherMOD.M;
        options_   = OtherMOD.options;
        oo_        = OtherMOD.oo;
        
        dynareOBC_.OtherMOD = OriginalMOD;
        
        InitialFullState.first = InitialFullState.first - full( dynareOBC_.Constant );
        % InitialFullState.constant = full( dynareOBC_.Constant );
        
        NewSimulation = SimulateModel( ShockSequence( :, ( SimulationLength + 1 ) : end ), DisplayProgress, InitialFullState, SkipMLVSimulation, DisableParFor );
        
        for i = 1 : length( SimulationFieldNames )
            CurrentFieldName = SimulationFieldNames{ i };
            if ~strcmp( CurrentFieldName, 'constant' )
                Simulation.( CurrentFieldName )( :, ( SimulationLength + 1 ) : end ) = NewSimulation.( CurrentFieldName );
            end
        end
        
        for i = 1 : nMLV
            MLVName = MLVNames{i};
            Simulation.MLVsWithBounds.( MLVName )( ( SimulationLength + 1 ) : end )    = NewSimulation.MLVsWithBounds.( MLVName );
            Simulation.MLVsWithoutBounds.( MLVName )( ( SimulationLength + 1 ) : end ) = NewSimulation.MLVsWithoutBounds.( MLVName );
        end

    end

end

function [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods )
    [ WarningMessage, WarningID ] = lastwarn;
    if ~isempty( WarningMessage )
        IDMatches = ismember( WarningIDs, WarningID );
        MessageMatch = ismember( WarningMessages( IDMatches ), WarningMessage );
        if ~any( MessageMatch )
            WarningIDs{ end + 1 } = WarningID;
            WarningMessages{ end + 1 } = WarningMessage;
            WarningPeriods{ end + 1 } = t;
        else
            WarningPeriods{ MessageMatch } = unique( [ WarningPeriods{ MessageMatch } t ] );
        end
    end
    lastwarn( '' );
end