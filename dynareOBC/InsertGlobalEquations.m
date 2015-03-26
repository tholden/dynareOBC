function [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = InsertGlobalEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC )
    
    ns = dynareOBC.NumberOfMax;
    nSVASC = size( dynareOBC.StateVariableAndShockCombinations, 1 );
    
    dynareOBC.ParameterIndices_StateVariableAndShockCombinations = zeros( nSVASC, ns );

    dynareOBC.VarIndices_ZeroLowerBounded = zeros( 1, ns );
       
    for i = 1 : ns
        string_i = int2str( i );
        parametersString = '';
        parameterValues = { };
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
        ExactBoundedVarName = [ 'dynareOBCExactZeroLowerBounded' string_i ];
        varString = [ 'var ' BoundedVarName ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_ZeroLowerBounded( i ) = CurrentNumVar;

        ZLBEquation = [ BoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ];

        for k = 1 : nSVASC
            string_k = int2str( k );
            parameterName = [ 'dynareOBCGlobalParam' string_i '_' string_k ];
            parametersString = [ parametersString ' ' parameterName ];
            CurrentNumParams = CurrentNumParams + 1;
            dynareOBC.ParameterIndices_StateVariableAndShockCombinations( k, i ) = CurrentNumParams;
            StateVariableAndShockCombination = dynareOBC.StateVariableAndShockCombinations( k, : );
            parameterValues{ end + 1 } = [ parameterName '=0;' ];
            ZLBEquation = [ ZLBEquation '+' parameterName ];
            for l = 1 : length( StateVariableAndShockCombination )
                if StateVariableAndShockCombination( l ) > 0
                    varCurrent = dynareOBC.StateVariablesAndShocks{ l };
                    for m = 1 : StateVariableAndShockCombination( l )
                        ZLBEquation = [ ZLBEquation '*' varCurrent ];
                    end
                end
            end
        end
        
        ToInsertInModelAtEnd{ end + 1 } = [ ZLBEquation ';' ]; %#ok<*AGROW>
        ToInsertInModelAtEnd{ end + 1 } = [ '#' ExactBoundedVarName '=max(0,dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ');' ]; %#ok<*AGROW>
        FileLines{ dynareOBC.MaxFuncIndices( i ) } = [ '#dynareOBCMaxFunc' string_i '=dynareOBCMaxArg' MinLetter string_i '+' BoundedVarName ';' ];
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e;', BoundedVarName, SteadyStateBoundedVar );

        varString = [ varString ';' ];
        if isempty( parametersString )
            ToInsertBeforeModel = [ ToInsertBeforeModel { varString } ];
        else
            parametersString = [ 'parameters' parametersString ';' ];
            ToInsertBeforeModel = [ ToInsertBeforeModel { parametersString } parameterValues { varString } ];
        end
    end
    
end
