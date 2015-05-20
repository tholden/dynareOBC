function [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = InsertShadowEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumVar, CurrentNumVarExo, dynareOBC, GlobalApproximationParameters, AmpValues )
    seps_string = sprintf( '%.17e', sqrt( eps ) );

    T = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    dynareOBC.VarIndices_ZeroLowerBounded = zeros( 1, ns );
    if dynareOBC.Global
        dynareOBC.VarIndices_ZeroLowerBoundedLongRun = zeros( 1, ns );
    else
        dynareOBC.VarIndices_ZeroLowerBoundedLongRun = [];
    end
    dynareOBC.VarIndices_Sum = zeros( T, ns );
    dynareOBC.VarExoIndices_DummyShadowShocks  = zeros( T, ns );
    
    for i = 1 : ns
        string_i = int2str( i );
        varexoString = 'varexo';
        if MaxArgValues( i, 1 ) > MaxArgValues( i, 2 )
            MaxLetter = 'A';
            MinLetter = 'B';
            SteadyStateBoundedVar = MaxArgValues( i, 1 ) - MaxArgValues( i, 2 );
        else
            MaxLetter = 'B';
            MinLetter = 'A';
            SteadyStateBoundedVar = MaxArgValues( i, 2 ) - MaxArgValues( i, 1 );
        end
        
        BoundedVarName = [ 'dynareOBCZeroLowerBounded' string_i ];
        varString = [ 'var ' BoundedVarName ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_ZeroLowerBounded( i ) = CurrentNumVar;
        
        ToInsertInModelAtEnd{ end + 1 } = [ BoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i '+dynareOBCSum' string_i '_0;' ]; %#ok<*AGROW>
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e;', BoundedVarName, SteadyStateBoundedVar );

        if dynareOBC.Global
            LongRunBoundedVarName = [ 'dynareOBCZeroLowerBoundedLongRun' string_i ];
            varString = [ varString ' ' LongRunBoundedVarName ];
            CurrentNumVar = CurrentNumVar + 1;
            dynareOBC.VarIndices_ZeroLowerBoundedLongRun( i ) = CurrentNumVar;
            PolynomialApproximationString = '';
            for k = 1 : size( dynareOBC.StateVariableAndShockCombinations, 1 )
                StateVariableAndShockCombination = dynareOBC.StateVariableAndShockCombinations( k, : );
                PolynomialApproximationString = sprintf( '%s+%.17e', PolynomialApproximationString, GlobalApproximationParameters( k, i ) );
                for l = 1 : length( StateVariableAndShockCombination )
                    if StateVariableAndShockCombination( l ) > 0
                        varCurrent = dynareOBC.StateVariablesAndShocks{ l };
                        for m = 1 : StateVariableAndShockCombination( l )
                            PolynomialApproximationString = [ PolynomialApproximationString '*' varCurrent ];
                        end
                    end
                end
            end
            ToInsertInModelAtEnd{ end + 1 } = [ LongRunBoundedVarName '=' int2str( AmpValues( i ) ) '*(dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ')' PolynomialApproximationString '+dynareOBCSum' string_i '_0;' ]; %#ok<*AGROW>
            ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e%s;', LongRunBoundedVarName, SteadyStateBoundedVar, regexprep( PolynomialApproximationString, '\([+-]?\d+\)', '' ) );
        end
       
        if dynareOBC.Global
            BoundedVarName = LongRunBoundedVarName;
        end
        
        FileLines{ dynareOBC.MaxFuncIndices( i ) } = [ '#dynareOBCMaxFunc' string_i '=dynareOBCMaxArg' MinLetter string_i '+' BoundedVarName ';' ];
 
        for j = 0 : ( T - 1 )
            string_j = int2str( j );
            varName = [ 'dynareOBCSum' string_i '_' string_j ];
            varString = [ varString ' ' varName ];
            CurrentNumVar = CurrentNumVar + 1;
            dynareOBC.VarIndices_Sum( j + 1, i ) = CurrentNumVar;
            ToInsertInInitVal{ end + 1 } = [ varName '=0;' ];
            NewEq = [ varName '=0' ];
            if j < T - 1
                NewEq = [ NewEq '+dynareOBCSum' string_i '_' int2str( j+1 ) '(-1)' ];
            end
            varexoName = [ 'dynareOBCEps' string_i '_' string_j ];
            varexoString = [ varexoString ' ' varexoName ];
            CurrentNumVarExo = CurrentNumVarExo + 1;
            dynareOBC.VarExoIndices_DummyShadowShocks( j + 1, i ) = CurrentNumVarExo;
            ToInsertInShocks{ end + 1 } = [ 'var ' varexoName '=1;' ];
            ToInsertInInitVal{ end + 1 } = [ varexoName '=0;' ];
            NewEq = [ NewEq '+' seps_string '*(' varexoName '^' int2str( dynareOBC.ShadowOrder ) ');' ];
            ToInsertInModelAtEnd{ end + 1 } = NewEq;
        end
        varexoString = [ varexoString ';' ];
        varString = [ varString ';' ];
        ToInsertBeforeModel = [ ToInsertBeforeModel { varexoString, varString } ];
    end
end
