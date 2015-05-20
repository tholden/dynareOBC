function [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = InsertGlobalEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, MaxArgPattern, CurrentNumParams, CurrentNumVar, dynareOBC )
    
    ns = dynareOBC.NumberOfMax;
    nSVASC = size( dynareOBC.StateVariableAndShockCombinations, 1 );
    
    dynareOBC.ParameterIndices_StateVariableAndShockCombinations = zeros( nSVASC, ns );

    dynareOBC.VarIndices_ZeroLowerBoundedLongRun = zeros( 1, ns );
    dynareOBC.VarIndices_ZeroLowerBounded = zeros( 1, ns );
    dynareOBC.VarIndices_StateVariableAndShockCombinations = zeros( nSVASC, 1 );
    
    CombinationNames = cell( nSVASC, 1 );
       
    for k = 1 : nSVASC
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_StateVariableAndShockCombinations( k ) = CurrentNumVar;
        StateVariableAndShockCombination = dynareOBC.StateVariableAndShockCombinations( k, : );
        SVASCEquation = '=1';
        SVASCInit = '=1';
        CombinationName = '1';
        for l = 1 : length( StateVariableAndShockCombination )
            if StateVariableAndShockCombination( l ) > 0
                varCurrent = dynareOBC.StateVariablesAndShocks{ l };
                for m = 1 : StateVariableAndShockCombination( l )
                    SVASCEquation = [ SVASCEquation '*' varCurrent ];
                    varCurrentNow = regexprep( varCurrent, '\([+-]?\d+\)', '' );
                    CombinationName = [ CombinationName 'T' varCurrentNow ];
                    SVASCInit = [ SVASCInit '*' varCurrentNow ];
                end
            end
        end
        CombinationNames{k} = CombinationName;
        SVASCVarName = [ 'dynareOBCSVASC_' CombinationName ];
        ToInsertBeforeModel{ end + 1 } = [ 'var ' SVASCVarName ';' ];
        ToInsertInModelAtEnd{ end + 1 } = [ SVASCVarName SVASCEquation ';' ];
        ToInsertInInitVal{ end + 1 } = [ SVASCVarName SVASCInit ';' ];
    end
    
    for i = 1 : ns
        string_i = int2str( i );
        parametersString = '';
        parameterValues = { };
        Offset = 0;
        if MaxArgPattern( i )
            MaxLetter = 'A';
            MinLetter = 'B';
            SteadyStateBoundedVar = MaxArgValues( i, 1 ) - MaxArgValues( i, 2 );
            if MaxArgValues( i, 1 ) < MaxArgValues( i, 2 )
                Offset = -SteadyStateBoundedVar;
                SteadyStateBoundedVar = 0;
            end
        else
            MaxLetter = 'B';
            MinLetter = 'A';
            SteadyStateBoundedVar = MaxArgValues( i, 2 ) - MaxArgValues( i, 1 );
            if MaxArgValues( i, 1 ) > MaxArgValues( i, 2 )
                Offset = -SteadyStateBoundedVar;
                SteadyStateBoundedVar = 0;
            end
        end
        
        LongRunBoundedVarName = [ 'dynareOBCZeroLowerBoundedLongRun' string_i ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_ZeroLowerBoundedLongRun( i ) = CurrentNumVar;
        
        BoundedVarName = [ 'dynareOBCZeroLowerBounded' string_i ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_ZeroLowerBounded( i ) = CurrentNumVar;

        ZLBEquation = [ LongRunBoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ];

        for k = 1 : nSVASC
            parameterName = [ 'dynareOBCGlobalParam' string_i '_' CombinationNames{k} ];
            parametersString = [ parametersString ' ' parameterName ];
            CurrentNumParams = CurrentNumParams + 1;
            dynareOBC.ParameterIndices_StateVariableAndShockCombinations( k, i ) = CurrentNumParams;
            if k > 1
                parameterValues{ end + 1 } = sprintf( '%s=0;', parameterName );
            else
                parameterValues{ end + 1 } = sprintf( '%s=%.17e;', parameterName, Offset );
            end
            ZLBEquation = [ ZLBEquation '+' parameterName '*dynareOBCSVASC_' CombinationNames{k} ];
        end
        
        ToInsertInModelAtEnd{ end + 1 } = [ ZLBEquation ';' ]; %#ok<*AGROW>
        ToInsertInModelAtEnd{ end + 1 } = [ BoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ';' ]; %#ok<*AGROW>
        FileLines{ dynareOBC.MaxFuncIndices( i ) } = [ '#dynareOBCMaxFunc' string_i '=dynareOBCMaxArg' MinLetter string_i '+' LongRunBoundedVarName ';' ];
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e;', LongRunBoundedVarName, SteadyStateBoundedVar );
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e;', BoundedVarName, SteadyStateBoundedVar );

        varString = [ 'var ' LongRunBoundedVarName ' ' BoundedVarName ';' ];
        if isempty( parametersString )
            ToInsertBeforeModel = [ ToInsertBeforeModel { varString } ];
        else
            parametersString = [ 'parameters' parametersString ';' ];
            ToInsertBeforeModel = [ ToInsertBeforeModel { parametersString } parameterValues { varString } ];
        end
    end
    
end
