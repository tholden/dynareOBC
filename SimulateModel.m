function Simulation = SimulateModel( ShockSequence, M_, options_, oo_Internal, dynareOBC_, DisplayProgress, InitialFullState, SkipMLVSimulation )

    T = dynareOBC_.InternalIRFPeriods;
    
    SimulationLength = size( ShockSequence, 2 );
    
    global oo_
    oo_ = oo_Internal;
    if nargin < 6
        DisplayProgress = true;
    end
    if nargin < 7
        EndoZeroVec = zeros( M_.endo_nbr, 1 );
        InitialFullState = struct;
        InitialFullState.first = EndoZeroVec;
        if dynareOBC_.Order >= 2
            InitialFullState.second = EndoZeroVec;
            if dynareOBC_.Order >= 3
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
    Simulation = pruning_abounds( M_, options_, ShockSequence, SimulationLength, dynareOBC_.Order, 'lan_meyer-gohde', 1, InitialFullState );
    StructFieldNames = setdiff( fieldnames( Simulation ), 'constant' );
    
    ghx = dynareOBC_.HighestOrder_ghx;
    ghu = dynareOBC_.HighestOrder_ghu;
    SelectState = dynareOBC_.SelectState;
    
    BoundOffsetOriginalOrder = InitialFullState.bound;
    BoundOffsetDROrder = BoundOffsetOriginalOrder( oo_Internal.dr.order_var );
    BoundOffsetDROrderNext = ghx * BoundOffsetDROrder( SelectState );
    BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo_Internal.dr.inv_order_var );
    
    Simulation.bound = zeros( M_.endo_nbr, SimulationLength );
    
    ShadowShockSequence = zeros( dynareOBC_.FullNumVarExo, SimulationLength );
    NewExoSelect = (dynareOBC_.OriginalNumVarExo+1) : dynareOBC_.FullNumVarExo;
    
    if dynareOBC_.NumberOfMax > 0
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
                    CurrentStateWithoutBound.( StructFieldNames{ i } ) = Simulation.( StructFieldNames{ i } )( :, t );
                end
                CurrentStateWithoutBound.( OrderText ) = CurrentStateWithoutBound.( OrderText ) + BoundOffsetOriginalOrderNext;

                ReturnStruct = ExpectedReturn( CurrentStateWithoutBound, M_, oo_.dr, dynareOBC_ );
                ReturnPath = ReturnStruct.total;        

                pseudo_alpha = -ReturnPath( dynareOBC_.VarIndices_Sum(:), 1 ); % .* dynareOBC_.OriginalSigns(:);
                for i = dynareOBC_.VarIndices_ZeroLowerBounded
                    ReturnPath( i, : ) = ReturnPath( i, : ) + ( dynareOBC_.MSubMatrices{ i }( 1:T, : ) * pseudo_alpha )';
                end

                ZeroLowerBoundedReturnPath = vec( ReturnPath( dynareOBC_.VarIndices_ZeroLowerBounded, : )' );

                alpha = SolveBoundsProblem( ZeroLowerBoundedReturnPath, dynareOBC_ );
                [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );
                
                if dynareOBC_.Accuracy > 0
                    % tString = int2str( t );
                    alpha = PerformQuadrature( alpha, ZeroLowerBoundedReturnPath, options_, oo_Internal, dynareOBC_, ReturnStruct.first ); % [ 'Computing required integral in period ' tString ' of ' SimulationLengthString '. Please wait for around ' ], '. Progress: ', [ 'Computing required integral in period ' tString ' of ' SimulationLengthString '. Completed in ' ] );
                end
                
                alpha = dynareOBC_.OriginalSigns(:) .* ( pseudo_alpha + alpha );

                ShadowShockSequence( dynareOBC_.VarExoIndices_DummyShadowShocks(:), t ) = alpha ./ sqrt( eps ); % M_.params( dynareOBC_.ParameterIndices_ShadowShockCombinations_Slice(:) );

                BoundOffsetDROrder = BoundOffsetDROrderNext + ghu( :, NewExoSelect ) * ShadowShockSequence( NewExoSelect, t );
                BoundOffsetDROrderNext = ghx * BoundOffsetDROrder( SelectState );
                BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo_Internal.dr.inv_order_var );
                BoundOffsetOriginalOrder = BoundOffsetDROrder( oo_Internal.dr.inv_order_var, : );
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
    
    if dynareOBC_.MLVSimulationSamples > 0 && ( ~SkipMLVSimulation )
        Simulation.MLVs = struct;
        LagValues = InitialFullState.total_with_bounds;
        LagIndices = M_.lead_lag_incidence( 1, : ) > 0;
        CurrentIndices = M_.lead_lag_incidence( 2, : ) > 0;
        FutureValues = nan( M_.nsfwrd, 1 );
        
        if dynareOBC_.MLVSimulationSamples > 1
            LeadIndices = M_.lead_lag_incidence( 3, : ) > 0;
            PositiveVarianceShocks = setdiff( 1:dynareOBC_.OriginalNumVarExo, find( diag(M_.Sigma_e) == 0 ) );
            NumberOfPositiveVarianceShocks = length( PositiveVarianceShocks );
            CholSigma_e = chol( M_.Sigma_e( PositiveVarianceShocks, PositiveVarianceShocks ) );
            SimulationFieldNames = [ StructFieldNames; { 'bound'; 'total_with_bounds' } ];
            % temporary work around for warning in dates object.
            options_.initial_period = [];
            options_.dataset = [];
        end
        
        ParamVec = M_.params;
        SteadyState = oo_Internal.dr.ys;
        
        WarningMessages = { };
        WarningIDs = { };
        WarningPeriods = { };

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
                CurrentValues = Simulation.total_with_bounds( :, t );
                CurrentShock = ShockSequence( :, t )';
                LagValuesLagIndices = LagValues( LagIndices );
                CurrentValuesCurrentIndices = CurrentValues( CurrentIndices );
                MLVNames = dynareOBC_.MLVNames;
                nMLV = length( MLVNames );
                if dynareOBC_.MLVSimulationSamples > 1
                    FutureShocks = CholSigma_e' * randn( NumberOfPositiveVarianceShocks, dynareOBC_.MLVSimulationSamples );
                    InnerInitialFullState = struct;
                    for i = 1 : length( SimulationFieldNames )
                        SimulationFieldName = SimulationFieldNames{i};
                        InnerInitialFullState.( SimulationFieldName ) = Simulation.( SimulationFieldName )( :, t );
                    end
                    MLVValues = zeros( nMLV, 1 );
                    WarningGenerated = false;
                    parfor PointIndex = 1 : dynareOBC_.MLVSimulationSamples
                        lastwarn( '' );
                        ParallelWarningState = warning( 'off', 'all' );
                        try
                            InnerShockSequence = FutureShocks( :, PointIndex );
                            InnerSimulation = SimulateModel( InnerShockSequence, M_, options_, oo_Internal, dynareOBC_, false, InnerInitialFullState, true );
                            InnerFutureValues = InnerSimulation.total_with_bounds( :, 1 );
                            InnerMLVs = dynareOBCtemp3_GetMLVs( [ LagValuesLagIndices; CurrentValuesCurrentIndices; InnerFutureValues( LeadIndices ) ], CurrentShock, ParamVec, SteadyState, 1 );
                            NewMLVValues = zeros( nMLV, 1 );
                            for i = 1 : nMLV
                                NewMLVValues( i ) = InnerMLVs.( MLVNames{i} ); %#ok<PFBNS>
                            end
                            MLVValues = MLVValues + NewMLVValues;
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
                    MLVValues = MLVValues / dynareOBC_.MLVSimulationSamples;
                    for i = 1 : nMLV
                        Simulation.MLVs.( MLVNames{i} )( t ) = MLVValues( i );
                    end
               else
                    CurrentMLVs = dynareOBCtemp3_GetMLVs( [ LagValuesLagIndices; CurrentValuesCurrentIndices; FutureValues ], CurrentShock, ParamVec, SteadyState, 1 );
                    for i = 1 : nMLV
                        MLVName = MLVNames{i};
                        Simulation.MLVs.( MLVName )( t ) = CurrentMLVs.( MLVName );
                    end
                end
                LagValues = CurrentValues;
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