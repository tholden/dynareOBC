function Simulation = SimulateModel( ShockSequence, M, options, oo, dynareOBC, DisplayProgress, InitialFullState, SkipMLVSimulation )

    T = dynareOBC.InternalIRFPeriods;
    
    SimulationLength = size( ShockSequence, 2 );
    
    global oo_
    oo_ = oo;
    if nargin < 6
        DisplayProgress = true;
    end
    if nargin < 7
        EndoZeroVec = zeros( M.endo_nbr, 1 );
        InitialFullState = struct;
        InitialFullState.first = EndoZeroVec;
        if dynareOBC.Order >= 2
            InitialFullState.second = EndoZeroVec;
            if dynareOBC.Order >= 3
                InitialFullState.third = EndoZeroVec;
                InitialFullState.first_sigma_2 = EndoZeroVec;
            end
        end
        InitialFullState.bound = EndoZeroVec;
        InitialFullState.total = EndoZeroVec;
        InitialFullState.total_with_bounds = EndoZeroVec;
    else
        DisplayProgress = false;
    end
    if nargin < 8
        SkipMLVSimulation = false;
    end
    if DisplayProgress
        p = TimedProgressBar( SimulationLength * dynareOBC.Order, 50, 'Computing base simulation. Please wait for around ', '. Progress: ', 'Computing base simulation. Completed in ' );
    else
        p = [];
    end
    if isempty( p )
        call_back = @( x ) x;
        call_back_arg = 0;
    else
        call_back = @( x ) x.progress;
        call_back_arg = p;
    end
    try
        Simulation = pruning_abounds( M, options, ShockSequence, SimulationLength, dynareOBC.Order, 'lan_meyer-gohde', 1, InitialFullState, call_back, call_back_arg );
    catch
        Simulation = pruning_abounds( M, options, ShockSequence, SimulationLength, dynareOBC.Order, 'lan_meyer-gohde', 1, InitialFullState );
    end
    if ~isempty( p )
        p.stop;
    end
    StructFieldNames = setdiff( fieldnames( Simulation ), 'constant' );
    
    ghx = dynareOBC.HighestOrder_ghx;
    ghu = dynareOBC.HighestOrder_ghu;
    SelectState = dynareOBC.SelectState;
    
    BoundOffsetOriginalOrder = InitialFullState.bound;
    BoundOffsetDROrder = BoundOffsetOriginalOrder( oo.dr.order_var );
    BoundOffsetDROrderNext = ghx * BoundOffsetDROrder( SelectState );
    BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo.dr.inv_order_var );
    
    Simulation.bound = zeros( M.endo_nbr, SimulationLength );
    
    ShadowShockSequence = zeros( dynareOBC.FullNumVarExo, SimulationLength );
    NewExoSelect = (dynareOBC.OriginalNumVarExo+1) : dynareOBC.FullNumVarExo;
    
    if dynareOBC.NumberOfMax > 0
        if dynareOBC.Global
            TM2 = T - 2;
            pM1 = ( -1 : TM2 )';
            pWeight = 0.5 * ( 1 + cos( pi * max( 0, pM1 ) / TM2 ) );
        end

        Shock = zeros( M.exo_nbr, 1 );

        OrderText = dynareOBC.OrderText;

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
                    CurrentStateWithoutBound.( StructFieldNames{ i } ) = Simulation.( StructFieldNames{ i } )( :, t );
                end
                CurrentStateWithoutBound.( OrderText ) = CurrentStateWithoutBound.( OrderText ) + BoundOffsetOriginalOrderNext;

                ReturnStruct = ExpectedReturn( CurrentStateWithoutBound, M, oo_.dr, dynareOBC );
                ReturnPath = ReturnStruct.total;        

                pseudo_y = -ReturnPath( dynareOBC.VarIndices_Sum(:), 1 );
                for i = [ dynareOBC.VarIndices_ZeroLowerBounded dynareOBC.VarIndices_ZeroLowerBoundedShortRun ]
                    ReturnPath( i, : ) = ReturnPath( i, : ) + ( dynareOBC.MSubMatrices{ i }( 1:T, : ) * pseudo_y )';
                end

                UnconstrainedReturnPath = ReturnPath( dynareOBC.VarIndices_ZeroLowerBounded, : )';
                if dynareOBC.Global
                    NewUnconstrainedReturnPath = vec( bsxfun( @times, pWeight, ReturnPath( dynareOBC.VarIndices_ZeroLowerBoundedShortRun, : )' ) + bsxfun( @times, 1 - pWeight, UnconstrainedReturnPath ) );
                    yExtra = ( dynareOBC.MMatrix ) \ ( NewUnconstrainedReturnPath - vec( UnconstrainedReturnPath ) );
                    UnconstrainedReturnPath = NewUnconstrainedReturnPath;
                else
                    UnconstrainedReturnPath = vec( UnconstrainedReturnPath );
                end

                y = SolveBoundsProblem( UnconstrainedReturnPath, dynareOBC );
                [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );

                if ~dynareOBC.NoCubature
                    y = PerformCubature( y, UnconstrainedReturnPath, options, oo, dynareOBC, ReturnStruct.first );
                end
                
                if dynareOBC.Global
                    y = y + yExtra;
                end

                y = y + pseudo_y;

                ShadowShockSequence( dynareOBC.VarExoIndices_DummyShadowShocks(:), t ) = y ./ sqrt( eps ); % M_.params( dynareOBC_.ParameterIndices_ShadowShockCombinations_Slice(:) );

                BoundOffsetDROrder = BoundOffsetDROrderNext + ghu( :, NewExoSelect ) * ShadowShockSequence( NewExoSelect, t );
                BoundOffsetDROrderNext = ghx * BoundOffsetDROrder( SelectState );
                BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo.dr.inv_order_var );
                BoundOffsetOriginalOrder = BoundOffsetDROrder( oo.dr.inv_order_var, : );
                Simulation.bound( :, t ) = BoundOffsetOriginalOrder;
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
    
    Simulation.total_with_bounds = Simulation.total + Simulation.bound;
    Simulation.shadow_shocks = ShadowShockSequence( NewExoSelect, : );
    
    if dynareOBC.MLVSimulationMode > 0 && ( ~SkipMLVSimulation )
        MLVNames = dynareOBC.MLVNames;
        nMLV = length( MLVNames );
        Simulation.MLVsWithBounds = struct;
        Simulation.MLVsWithoutBounds = struct;
        OriginalVarSelect = false( M.endo_nbr );
        OriginalVarSelect( 1:dynareOBC.OriginalNumVar ) = true;
        LagValuesWithBounds = InitialFullState.total_with_bounds( OriginalVarSelect );
        LagValuesWithoutBounds = InitialFullState.total( OriginalVarSelect );
        LagIndices = dynareOBC.OriginalLeadLagIncidence( 1, : ) > 0;
        CurrentIndices = dynareOBC.OriginalLeadLagIncidence( 2, : ) > 0;
        LeadIndices = dynareOBC.OriginalLeadLagIncidence( 3, : ) > 0;
        FutureValues = nan( sum( LeadIndices ), 1 );
        
        if dynareOBC.MLVSimulationMode > 1
            PositiveVarianceShocks = setdiff( 1:dynareOBC.OriginalNumVarExo, find( diag(M.Sigma_e) == 0 ) );
            NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
            CholSigma_e = chol( M.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );
            SimulationFieldNames = [ StructFieldNames; { 'bound'; 'total_with_bounds' } ];
            % temporary work around for warning in dates object.
            options.initial_period = [];
            options.dataset = [];
        end
        
        ParamVec = M.params;
        SteadyState = oo.dr.ys;
        
        WarningMessages = { };
        WarningIDs = { };
        WarningPeriods = { };

        if dynareOBC.MLVSimulationMode == 2
            if DisplayProgress
                fprintf( '\nCalculating cubature points and weights.\n' );
            end
        	[ Weights, Points, NumPoints ] = fwtpts( NumberOfPositiveVarianceShocks, max( 0, ceil( 0.5 * ( dynareOBC.MLVSimulationCubatureDegree - 1 ) ) ) );
            if DisplayProgress
                fprintf( 'Found a cubature rule with %d points.\n', NumPoints );
            end
            FutureShocks = CholSigma_e' * Points;
        else
            NumPoints = dynareOBC.MLVSimulationSamples;
            Weights = ones( 1, NumPoints ) * ( 1 / NumPoints );
        end
        
        if DisplayProgress
            p = TimedProgressBar( SimulationLength, 50, 'Computing model local variable paths. Please wait for around ', '. Progress: ', 'Computing model local variable paths. Completed in ' );
        else
            p = [];
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
                CurrentShock = ShockSequence( :, t )';
                LagValuesWithBoundsLagIndices = LagValuesWithBounds( LagIndices );
                LagValuesWithoutBoundsLagIndices = LagValuesWithoutBounds( LagIndices );
                CurrentValuesWithBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
                CurrentValuesWithoutBoundsCurrentIndices = CurrentValuesWithBounds( CurrentIndices );
                if dynareOBC.MLVSimulationMode > 1
                    if dynareOBC.MLVSimulationMode == 3
                        Points = randn( NumberOfPositiveVarianceShocks, NumPoints );
                        FutureShocks = CholSigma_e' * Points;
                    end
                    
                    InnerInitialFullState = struct;
                    for i = 1 : length( SimulationFieldNames )
                        SimulationFieldName = SimulationFieldNames{i};
                        InnerInitialFullState.( SimulationFieldName ) = Simulation.( SimulationFieldName )( :, t );
                    end
                    MLVValuesWithBounds = zeros( nMLV, 1 );
                    MLVValuesWithoutBounds = zeros( nMLV, 1 );
                    WarningGenerated = false;
                    parfor PointIndex = 1 : NumPoints
                        lastwarn( '' );
                        ParallelWarningState = warning( 'off', 'all' );
                        try
                            InnerShockSequence = FutureShocks( :, PointIndex );
                            InnerSimulation = SimulateModel( InnerShockSequence, M, options, oo, dynareOBC, false, InnerInitialFullState, true );
                            InnerFutureValuesWithBounds = InnerSimulation.total_with_bounds( OriginalVarSelect, 1 );
                            InnerFutureValuesWithoutBounds = InnerSimulation.total( OriginalVarSelect, 1 );
                            InnerMLVsWithBounds = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; InnerFutureValuesWithBounds( LeadIndices ) ], CurrentShock, ParamVec, SteadyState, 1 );
                            if dynareOBC.NumberOfMax > 0
                                InnerMLVsWithoutBounds = dynareOBCTempGetMLVs( [ LagValuesWithoutBoundsLagIndices; CurrentValuesWithoutBoundsCurrentIndices; InnerFutureValuesWithoutBounds( LeadIndices ) ], CurrentShock, ParamVec, SteadyState, 1 );
                            else
                                InnerMLVsWithoutBounds = InnerMLVsWithBounds;
                            end
                            NewMLVWithBoundsValues = zeros( nMLV, 1 );
                            NewMLVWithoutBoundsValues = zeros( nMLV, 1 );
                            for i = 1 : nMLV
                                MLVName = MLVNames{i}; %#ok<PFBNS>
                                NewMLVWithBoundsValues( i ) = InnerMLVsWithBounds.( MLVName );
                                NewMLVWithoutBoundsValues( i ) = InnerMLVsWithoutBounds.( MLVName );
                            end
                            MLVValuesWithBounds = MLVValuesWithBounds + NewMLVWithBoundsValues * Weights( PointIndex );
                            MLVValuesWithoutBounds = MLVValuesWithoutBounds + NewMLVWithoutBoundsValues * Weights( PointIndex );
                        catch Error
                            warning( ParallelWarningState );
                            rethrow( Error );
                        end
                        warning( ParallelWarningState );
                        WarningGenerated = WarningGenerated | ( ~isempty( lastwarn ) );
                    end
                    if WarningGenerated
                        warning( 'dynareOBC:InnerMLVWarning', 'Warnings were generated in the inner loop responsible for evaluating expectations of model local variables.' );
                    end
                    for i = 1 : nMLV
                        Simulation.MLVsWithBounds.( MLVNames{i} )( t ) = MLVValuesWithBounds( i );
                        Simulation.MLVsWithoutBounds.( MLVNames{i} )( t ) = MLVValuesWithoutBounds( i );
                    end
               else
                    CurrentMLVsWithBounds = dynareOBCTempGetMLVs( [ LagValuesWithBoundsLagIndices; CurrentValuesWithBoundsCurrentIndices; FutureValues ], CurrentShock, ParamVec, SteadyState, 1 );
                    if dynareOBC.NumberOfMax > 0
                        CurrentMLVsWithoutBounds = dynareOBCTempGetMLVs( [ LagValuesWithoutBoundsLagIndices; CurrentValuesWithoutBoundsCurrentIndices; FutureValues ], CurrentShock, ParamVec, SteadyState, 1 );
                    else
                        CurrentMLVsWithoutBounds = CurrentMLVsWithBounds;
                    end
                    for i = 1 : nMLV
                        MLVName = MLVNames{i};
                        Simulation.MLVsWithBounds.( MLVName )( t ) = CurrentMLVsWithBounds.( MLVName );
                        Simulation.MLVsWithoutBounds.( MLVName )( t ) = CurrentMLVsWithoutBounds.( MLVName );
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