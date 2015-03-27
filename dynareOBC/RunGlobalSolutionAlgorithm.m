function dynareOBC = RunGlobalSolutionAlgorithm( basevarargin, SolveAlgo, FileLines, Indices, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, CurrentNumParams, CurrentNumVar, dynareOBC )

    skipline( );
    disp( 'Beginning to solve for the global polynomial approximation to the bounds.' );
    skipline( );
    
    dynareOBC.StateVariableAndShockCombinations = GenerateCombinations( length( dynareOBC.StateVariablesAndShocks ), dynareOBC.Order );
   
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
    newmodfile = fopen( 'dynareOBCtempG.mod', 'w' );
    fprintf( newmodfile, '%s', FileText );
    fclose( newmodfile );
    
    skipline( );
    disp( 'Calling dynare on the intermediate mod file.' );
    skipline( );

    dynare( 'dynareOBCtempG.mod', basevarargin{:} );   
    
    GlobalModelSolution;
    
end