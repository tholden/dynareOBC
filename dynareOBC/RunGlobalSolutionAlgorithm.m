function [ GlobalApproximationParameters, MaxArgValues ] = RunGlobalSolutionAlgorithm( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC )
  
    global M_
    while true
        [ GlobalApproximationParameters, MaxArgValues, MaxArgPattern, PI ] = RunGlobalSolutionAlgorithmInternal( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC );
        
        NewMaxArgPattern = MaxArgValues( :, 1 ) < MaxArgValues( :, 2 );
        if any( NewMaxArgPattern ~= MaxArgPattern )
            GlobalApproximationParameters = bsxfun( @times, GlobalApproximationParameters, 1 - 2 * ( NewMaxArgPattern ~= MaxArgPattern )' );
            M_.params( PI ) = GlobalApproximationParameters(:);
        else
            break;
        end
    end
    
end

function [ GlobalApproximationParameters, MaxArgValues, MaxArgPattern, PI ] = RunGlobalSolutionAlgorithmInternal( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC )

        skipline( );
        disp( 'Generating the intermediate mod file.' );
        skipline( );

        [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = ...
            InsertGlobalEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC );

        [ FileLines, Indices ] = PerformInsertion( ToInsertBeforeModel, Indices.ModelStart, FileLines, Indices );
        [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtStart, Indices.ModelStart + 1, FileLines, Indices );
        [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtEnd, Indices.ModelEnd, FileLines, Indices );
        [ FileLines, Indices ] = PerformInsertion( ToInsertInShocks, Indices.ShocksStart + 1, FileLines, Indices );
        [ FileLines, ~ ] = PerformInsertion( [ { 'initval;' } ToInsertInInitVal { 'end;', 'load_params_and_steady_state( ''dynareOBCSteady.txt'' );' } ], Indices.ModelEnd + 1, FileLines, Indices );

        %Save the result

        FileText = strjoin( [ FileLines { [ 'stoch_simul(order=' int2str( dynareOBC.Order ) ',solve_algo=' int2str( SolveAlgo ) ',pruning,sylvester=fixed_point,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' ); % dr=cyclic_reduction,
        newmodfile = fopen( 'dynareOBCTempG.mod', 'w' );
        fprintf( newmodfile, '%s', FileText );
        fclose( newmodfile );

        skipline( );
        disp( 'Calling dynare on the intermediate mod file.' );
        skipline( );

        global M_ oo_ options_
        options_.solve_tolf = eps;
        dynare( 'dynareOBCTempG.mod', basevarargin{:} );

        MaxArgPattern = MaxArgValues( :, 1 ) < MaxArgValues( :, 2 );

        options_.solve_tolf = eps;
        [ GlobalApproximationParameters, M, oo ] = GlobalModelSolution( M_, options_, oo_, dynareOBC );
        old_M_ = M_;
        old_oo_ = oo_;
        M_ = M; %#ok<NASGU>
        oo_ = oo; %#ok<NASGU>
        save_params_and_steady_state( 'dynareOBCSteady.txt' );
        M_ = old_M_;
        oo_ = old_oo_;

        Generate_dynareOBCTempGetMaxArgValues( dynareOBC.NumberOfMax, 'dynareOBCTempG_static' );
        MaxArgValues = dynareOBCTempGetMaxArgValues( oo.steady_state, [ oo.exo_steady_state; oo.exo_det_steady_state ], M.params );
        if any( MaxArgValues( :, 1 ) == MaxArgValues( :, 2 ) )
            error( 'dynareOBC:JustBinding', 'dynareOBC does not support cases in which the constraint just binds in steady-state.' );
        end
        
        PI = dynareOBC.ParameterIndices_StateVariableAndShockCombinations(:);

end
