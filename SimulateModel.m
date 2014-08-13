function Simulation = SimulateModel( ShockSequence, M_, options_, oo_Internal, dynareOBC_, DisplayProgress, InitialFullState )

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
    else
        DisplayProgress = false;
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