function Simulation = SimulateModel( ShockSequence, DisplayProgress, InitialFullState, SkipMLVSimulation, DisableParFor )

    global M_ oo_ dynareOBC_
        
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
   
    SimulationLength = size( ShockSequence, 2 );
    
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
        DisplayProgress = false;
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
            p = TimedProgressBar( NumberOfGridPoints, 50, 'Computing simulations on grid points. Please wait for around ', '. Progress: ', 'Computing simulations on grid points. Completed in ' );
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
                p = TimedProgressBar( SimulationLength, 50, 'Computing base simulation. Please wait for around ', '. Progress: ', 'Computing base simulation. Completed in ' );
            else
                p = [];
            end
            if isempty( p )
                call_back = @( x ) x;
            else
                call_back = @( x ) x.progress;
            end
            call_back_arg = p;
            Simulation = LanMeyerGohdePrunedSimulation( M_, oo_.dr, ShockSequence, SimulationLength, dynareOBC_.Order, 1, InitialFullState, call_back, call_back_arg );
            if ~isempty( p )
                p.stop;
            end
        end
        
        % StructFieldNames = setdiff( fieldnames( Simulation ), 'constant' );
        StructFieldNames = fieldnames( Simulation );

        SelectState = dynareOBC_.SelectState;

        Simulation.bound_offset = zeros( M_.endo_nbr, SimulationLength );

        ghx = oo_.dr.ghx;
        pMat = dynareOBC_.pMat;

        if dynareOBC_.NumberOfMax > 0
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
                p = TimedProgressBar( SimulationLength, 50, 'Computing simulation. Please wait for around ', '. Progress: ', 'Computing simulation. Completed in ' );
            else
                p = [];
            end
            for t = 1 : SimulationLength
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
                        y = SolveBoundsProblem( UnconstrainedReturnPath );
                        [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );

                        if ~dynareOBC_.NoCubature
                            [ y, GlobalVarianceShare ] = PerformCubature( y, UnconstrainedReturnPath, oo_, dynareOBC_, ReturnPathStruct.first, DisableParFor );
                            if dynareOBC_.Global
                                y = SolveGlobalBoundsProblem( y, GlobalVarianceShare, UnconstrainedReturnPath, ReturnPath( dynareOBC_.VarIndices_ZeroLowerBoundedLongRun, : )', dynareOBC_ );
                            end
                        end
                    catch Error
                        if dynareOBC_.IgnoreBoundFailures
                            Reshaped_yOld = reshape( yOld, Ts, ns );
                            y = [ Reshaped_yOld( 2:end, : ); zeros( 1, ns ) ];
                            y = y(:);
                            warning( 'dynareOBC:BoundFailureCaught', [ 'The following error was caught while solving the bounds problem:\n' Error.message '\nContinuing due to IgnoreBoundFailures option.' ] );
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

                if ~isempty( p )
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
        OriginalVarSelect = false( M_.endo_nbr );
        OriginalVarSelect( 1:dynareOBC_.OriginalNumVar ) = true;
        LagValuesWithBounds = InitialFullState.total_with_bounds( OriginalVarSelect );
        LagValuesWithoutBounds = InitialFullState.total( OriginalVarSelect );
        LagIndices = dynareOBC_.OriginalLeadLagIncidence( 1, : ) > 0;
        CurrentIndices = dynareOBC_.OriginalLeadLagIncidence( 2, : ) > 0;
        if size( dynareOBC_.OriginalLeadLagIncidence, 1 ) > 2
            LeadIndices = dynareOBC_.OriginalLeadLagIncidence( 3, : ) > 0;
        else
            LeadIndices = [];
        end
        FutureValues = nan( sum( LeadIndices ), 1 );
        
        if dynareOBC_.MLVSimulationMode > 1
            PositiveVarianceShocks = setdiff( 1:dynareOBC_.OriginalNumVarExo, find( diag(M_.Sigma_e) == 0 ) );
            NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
            CholSigma_e = chol( M_.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );
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
            FutureShocks = CholSigma_e' * Points;
            if DisplayProgress
                fprintf( 'Found a cubature rule with %d points.\n', NumPoints );
            end
        end
        
        if DisplayProgress
            p = TimedProgressBar( SimulationLength, 50, 'Computing model local variable paths. Please wait for around ', '. Progress: ', 'Computing model local variable paths. Completed in ' );
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
                rethrow( Error );
            end
            
            [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );

            warning( WarningState );
            
            if ~isempty( p )
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