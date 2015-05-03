function [ GlobalApproximationParameters, MaxArgValues ] = RunGlobalSolutionAlgorithm( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtStart, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC )
  
    skipline( );
    disp( 'Generating the intermediate mod file.' );
    skipline( );
    
    [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = ...
        InsertGlobalEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC );

    [ FileLines, Indices ] = PerformInsertion( ToInsertBeforeModel, Indices.ModelStart, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtStart, Indices.ModelStart + 1, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInModelAtEnd, Indices.ModelEnd, FileLines, Indices );
    [ FileLines, Indices ] = PerformInsertion( ToInsertInShocks, Indices.ShocksStart + 1, FileLines, Indices );
    [ FileLines, ~ ] = PerformInsertion( [ { 'initval;' } ToInsertInInitVal { 'end;' } ], Indices.ModelEnd + 1, FileLines, Indices );

    %Save the result

    FileText = strjoin( [ FileLines { [ 'stoch_simul(order=' int2str( dynareOBC.Order ) ',solve_algo=' int2str( SolveAlgo ) ',pruning,sylvester=fixed_point,irf=0,periods=0,nocorr,nofunctions,nomoments,nograph,nodisplay,noprint);' ] } ], '\n' ); % dr=cyclic_reduction,
    newmodfile = fopen( 'dynareOBCTempG.mod', 'w' );
    fprintf( newmodfile, '%s', FileText );
    fclose( newmodfile );
    
    skipline( );
    disp( 'Calling dynare on the intermediate mod file.' );
    skipline( );

    global options_
    options_.solve_tolf = eps;
    dynare( 'dynareOBCTempG.mod', basevarargin{:} );
    
    global M_ oo_
    MaxArgPattern = MaxArgValues( :, 1 ) < MaxArgValues( :, 2 );
    
    options_.solve_tolf = eps;
    [ GlobalApproximationParameters, M, oo ] = GlobalModelSolution( M_, options_, oo_, dynareOBC );
    
    Generate_dynareOBCTempGetMaxArgValues( dynareOBC.NumberOfMax, 'dynareOBCTempG_static' );
    MaxArgValues = dynareOBCTempGetMaxArgValues( oo.steady_state, [ oo.exo_steady_state; oo.exo_det_steady_state ], M.params );
    if any( MaxArgValues( :, 1 ) == MaxArgValues( :, 2 ) )
        error( 'dynareOBC:JustBinding', 'dynareOBC does not support cases in which the constraint just binds in steady-state.' );
    end
    
    NewMaxArgPattern = MaxArgValues( :, 1 ) < MaxArgValues( :, 2 );
    if any( NewMaxArgPattern ~= MaxArgPattern )
        error( 'dynareOBC:UnhandledCase', 'Please e-mail your .mod file to thomas.holden@gmail.com and I will write the code to handle this case.' );
        keyboard;
    end
    
end
