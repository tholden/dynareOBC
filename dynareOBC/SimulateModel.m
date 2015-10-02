function Simulation = SimulateModel( ShockSequence, M, options, oo, dynareOBC, DisplayProgress, InitialFullState, SkipMLVSimulation )

    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
   
    SimulationLength = size( ShockSequence, 2 );
    
	if nargin < 6
        DisplayProgress = true;
	end
	if nargin < 7
        EndoZeroVec = zeros( M.endo_nbr, 1 );
        InitialFullState = struct;
        InitialFullState.bound = zeros( Ts * ns, 1 );
        InitialFullState.bound_offset = EndoZeroVec;
        InitialFullState.first = EndoZeroVec;
		if dynareOBC.Order >= 3
			InitialFullState.first_sigma_2 = EndoZeroVec;
		end
        if dynareOBC.Order >= 2
            InitialFullState.second = EndoZeroVec;
            if dynareOBC.Order >= 3
                InitialFullState.third = EndoZeroVec;
            end
        end
        InitialFullState.total = EndoZeroVec;
        InitialFullState.total_with_bounds = EndoZeroVec;
	else
        DisplayProgress = false;
		InitialFullState = orderfields( InitialFullState );
	end
	if nargin < 8
        SkipMLVSimulation = false;
	end
	if dynareOBC.UseSimulationCode && ( dynareOBC.CompileSimulationCode || dynareOBC.Estimation )
		try
			if dynareOBC.Estimation
				if dynareOBC.Sparse
					Simulation = dynareOBCTempCustomLanMeyerGohdePrunedSimulation( MakeFull( oo.dr ), full( ShockSequence ), int32( SimulationLength ), InitialFullState );
				else
					Simulation = dynareOBCTempCustomLanMeyerGohdePrunedSimulation( oo.dr, ShockSequence, int32( SimulationLength ), InitialFullState );
				end
			else
				if dynareOBC.Sparse
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
        Simulation = LanMeyerGohdePrunedSimulation( M, options, oo.dr, ShockSequence, SimulationLength, dynareOBC.Order, 1, InitialFullState, call_back, call_back_arg );
		if ~isempty( p )
			p.stop;
		end
	end
    % StructFieldNames = setdiff( fieldnames( Simulation ), 'constant' );
	StructFieldNames = fieldnames( Simulation );
    
    SelectState = dynareOBC.SelectState;
        
    Simulation.bound = zeros( Ts * ns, SimulationLength );
    Simulation.bound_offset = zeros( M.endo_nbr, SimulationLength );
    
    ShadowShockSequence = zeros( dynareOBC.FullNumVarExo, SimulationLength );
    NewExoSelect = (dynareOBC.OriginalNumVarExo+1) : dynareOBC.FullNumVarExo;
    
	ghx = oo.dr.ghx;
	pMat = dynareOBC.pMat;
	
    if dynareOBC.NumberOfMax > 0
		Bound = InitialFullState.bound;
		BoundOffsetOriginalOrder = InitialFullState.bound_offset;
		BoundOffsetDROrder = BoundOffsetOriginalOrder( oo.dr.order_var );
		BoundOffsetDROrderNext = pMat * Bound + ghx * BoundOffsetDROrder( SelectState );
		BoundOffsetOriginalOrderNext = BoundOffsetDROrderNext( oo.dr.inv_order_var );
		ReshapedBound = reshape( Bound, Ts, ns );
		BoundNext = [ ReshapedBound( 2:end, : ); zeros( 1, ns ) ];
		BoundNext = BoundNext(:);
		% TODO what is the impact of the shock hitting in boundoffsetdrordernext??
		
        if dynareOBC.Global
            TM2 = T - 2;
            pM1 = ( -1 : TM2 )';
            pWeight = 0.5 * ( 1 + cos( pi * max( 0, pM1 ) / TM2 ) );
            ErrorWeight = repmat( 1 - pWeight, 1, ns );
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
					CurrentFieldName = StructFieldNames{ i };
					if ~strcmp( CurrentFieldName, 'constant' )
						CurrentStateWithoutBound.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, t );
					end
                end
                CurrentStateWithoutBound.( OrderText ) = CurrentStateWithoutBound.( OrderText ) + BoundOffsetOriginalOrderNext;

                ReturnStruct = ExpectedReturn( CurrentStateWithoutBound, M, oo.dr, dynareOBC );
                ReturnPath = ReturnStruct.total;        

                pseudo_y = -Bound;
                for i = [ dynareOBC.VarIndices_ZeroLowerBounded dynareOBC.VarIndices_ZeroLowerBoundedLongRun ]
                    ReturnPath( i, : ) = ReturnPath( i, : ) + ( dynareOBC.MSubMatrices{ i }( 1:T, : ) * pseudo_y )';
                end

                UnconstrainedReturnPath = vec( ReturnPath( dynareOBC.VarIndices_ZeroLowerBounded, : )' );

                try
                    y = SolveBoundsProblem( UnconstrainedReturnPath, dynareOBC );
                    [ WarningMessages, WarningIDs, WarningPeriods ] = UpdateWarningList( t, WarningMessages, WarningIDs, WarningPeriods );

                    if ~dynareOBC.NoCubature
                        y = PerformCubature( y, UnconstrainedReturnPath, options, oo, dynareOBC, ReturnStruct.first );
                    end

                    if dynareOBC.Global
                        y = SolveGlobalBoundsProblem( y, UnconstrainedReturnPath,  ReturnPath( dynareOBC.VarIndices_ZeroLowerBoundedLongRun, : )', pWeight, ErrorWeight, dynareOBC );
                    end
                catch Error
                    if dynareOBC.Estimation || dynareOBC.IgnoreBoundFailures
                        y = -pseudo_y;
                        warning( 'dynareOBC:BoundFailureCaught', [ 'The following error was caught while solving the bounds problem:\n' Error.message '\nContinuing due to Estimation or IgnoreBoundFailures option.' ] );
                    else
                        rethrow( Error );
                    end
                end

				% orig_y = y;
                y = y + pseudo_y;

                BoundOffsetDROrder = BoundOffsetDROrderNext + pMat * y;
                % BoundOffsetDROrder = ghx * BoundOffsetDROrder( SelectState ) + pMat * orig_y;
                BoundOffsetDROrderNext = pMat * Bound + ghx * BoundOffsetDROrder( SelectState );
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
    
    Simulation.total_with_bounds = Simulation.total + Simulation.bound_offset;
    
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
                        CurrentFieldName = SimulationFieldNames{i};
						if ~strcmp( CurrentFieldName, 'constant' )
							InnerInitialFullState.( CurrentFieldName ) = Simulation.( CurrentFieldName )( :, t );
						end
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