function [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC_ ] = InsertShadowEquations( FileLines, ToInsertInInitVal, MaxArgValues, M_, dynareOBC_ )
    seps_string = sprintf( '%.20e', sqrt( eps ) );

    T = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
    
    dynareOBC_.ParameterIndices_StateVariableAndShockCombinations = zeros( size( dynareOBC_.StateVariableAndShockCombinations, 1 ), T, ns );
    dynareOBC_.ParameterIndices_ShadowShockCombinations = zeros( size( dynareOBC_.ShadowShockCombinations, 1 ), T, ns );
    dynareOBC_.ParameterIndices_OtherShadowShockCombinations = eye( T * ns );
    
    dynareOBC_.VarIndices_ZeroLowerBounded = zeros( 1, ns );
    dynareOBC_.VarIndices_Sum = zeros( T, ns );
    dynareOBC_.VarExoIndices_DummyShadowShocks  = zeros( T, ns );
    
    dynareOBC_.VarExoIndices_ShadowShocks = zeros( dynareOBC_.ShadowShockNumberMultiplier, T, ns );
    
    CurrentNumParams = M_.param_nbr;
    CurrentNumVar = M_.endo_nbr;
    CurrentNumVarExo = M_.exo_nbr;
    
    dynareOBC_.OriginalNumParams = CurrentNumParams;
    dynareOBC_.OriginalNumVar = CurrentNumVar;
    dynareOBC_.OriginalNumVarExo = CurrentNumVarExo;
    
    ToInsertBeforeModel = { };
    ToInsertInModelAtEnd = { };
    ToInsertInShocks = { };
    
    LinearIndex = 0;
    
    for i = 1 : ns
        string_i = int2str( i );
        parametersString = '';
        parameterValues = { };
        varexoString = 'varexo';
        BoundedVarName = [ 'dynareOBCZeroLowerBounded' string_i ];
        varString = [ 'var ' BoundedVarName ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC_.VarIndices_ZeroLowerBounded( i ) = CurrentNumVar;
        if MaxArgValues( i, 1 ) > MaxArgValues( i, 2 )
            MaxLetter = 'A';
            MinLetter = 'B';
            SteadyStateBoundedVar = MaxArgValues( i, 1 ) - MaxArgValues( i, 2 );
        else
            MaxLetter = 'B';
            MinLetter = 'A';
            SteadyStateBoundedVar = MaxArgValues( i, 2 ) - MaxArgValues( i, 1 );
        end
        ToInsertInModelAtEnd{ end + 1 } = [ BoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i '+dynareOBCSum' string_i '_0;' ]; %#ok<*AGROW>
        FileLines{ dynareOBC_.MaxFuncIndices( i ) } = [ '#dynareOBCMaxFunc' string_i '=dynareOBCMaxArg' MinLetter string_i '+' BoundedVarName ';' ];
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.20e;', BoundedVarName, SteadyStateBoundedVar );

        for j = 0 : ( T - 1 )
            LinearIndex = LinearIndex + 1;
            string_LinearIndex = int2str( LinearIndex );
            string_j = int2str( j );
            varName = [ 'dynareOBCSum' string_i '_' string_j ];
            varString = [ varString ' ' varName ];
            CurrentNumVar = CurrentNumVar + 1;
            dynareOBC_.VarIndices_Sum( j + 1, i ) = CurrentNumVar;
            ToInsertInInitVal{ end + 1 } = [ varName '=0;' ];
            NewEq = [ varName '=0' ];
            if j < T - 1
                NewEq = [ NewEq '+dynareOBCSum' string_i '_' int2str( j+1 ) '(-1)' ];
            end
            for k = 1 : dynareOBC_.ShadowShockNumberMultiplier
                string_k = int2str( k );
                varexoName = [ 'dynareOBCEps' string_i '_' string_j '_' string_k ];
                varexoString = [ varexoString ' ' varexoName ];
                CurrentNumVarExo = CurrentNumVarExo + 1;
                dynareOBC_.VarExoIndices_ShadowShocks( k, j + 1, i ) = CurrentNumVarExo;
                ToInsertInShocks{ end + 1 } = [ 'var ' varexoName '=1;' ];
                ToInsertInInitVal{ end + 1 } = [ varexoName '=0;' ];
            end
            varexoName = [ 'dynareOBCEpsDummy' string_i '_' string_j ];
            varexoString = [ varexoString ' ' varexoName ];
            CurrentNumVarExo = CurrentNumVarExo + 1;
            dynareOBC_.VarExoIndices_DummyShadowShocks( j + 1, i ) = CurrentNumVarExo;
            ToInsertInShocks{ end + 1 } = [ 'var ' varexoName '=1;' ];
            ToInsertInInitVal{ end + 1 } = [ varexoName '=0;' ];
            for k = 1 : length( dynareOBC_.StateVariableAndShockCombinations )
                string_k = int2str( k );
                parameterName = [ varName '_model_' string_k ];
                parametersString = [ parametersString ' ' parameterName ];
                CurrentNumParams = CurrentNumParams + 1;
                dynareOBC_.ParameterIndices_StateVariableAndShockCombinations( k, j + 1, i ) = CurrentNumParams;
                StateVariableAndShockCombination = dynareOBC_.StateVariableAndShockCombinations( k, : );
                parameterValues{ end + 1 } = [ parameterName '=0;' ];
                NewEq = [ NewEq '+' parameterName ];
                for l = 1 : length( StateVariableAndShockCombination )
                    if StateVariableAndShockCombination( l ) > 0
                        varCurrent = dynareOBC_.StateVariablesAndShocks{ l };
                        for m = 1 : StateVariableAndShockCombination( l )
                            NewEq = [ NewEq '*' varCurrent ];
                        end
                    end
                end
            end
            if dynareOBC_.Accuracy > 1
                LinearIndex2 = 0;
                for i2 = 1 : i
                    string_i2 = int2str( i2 );
                    for j2 = 0 : ( T - 1 )
                        LinearIndex2 = LinearIndex2 + 1;
                        if( LinearIndex2 >= LinearIndex )
                            break;
                        end
                        string_LinearIndex2 = int2str( LinearIndex2 );
                        string_j2 = int2str( j2 );
                        varName2 = [ 'dynareOBCSum' string_i2 '_' string_j2 ];
                        parameterName = [ 'dynareOBCShadowShockLowerCholCovariance' string_LinearIndex '_' string_LinearIndex2 ];
                        parametersString = [ parametersString ' ' parameterName ];
                        CurrentNumParams = CurrentNumParams + 1;
                        dynareOBC_.ParameterIndices_OtherShadowShockCombinations( LinearIndex, LinearIndex2 ) = CurrentNumParams;
                        parameterValues{ end + 1 } = [ parameterName '=0;' ];
                        NewEq = [ NewEq '+' parameterName '*' varName2 '_ssc' ];
                    end
                end
            end
            ShadowShockCombinationName = [ varName '_ssc' ];
            NewEq = [ NewEq '+' ShadowShockCombinationName '+' seps_string '*(' varexoName '^' int2str( dynareOBC_.ShadowOrder ) ');' ];
            NewEq2 = [ '#' ShadowShockCombinationName '=0' ];
            for k = 1 : size( dynareOBC_.ShadowShockCombinations, 1 )
                string_k = int2str( k );
                parameterName = [ varName '_shadow_' string_k ];
                parametersString = [ parametersString ' ' parameterName ];
                CurrentNumParams = CurrentNumParams + 1;
                dynareOBC_.ParameterIndices_ShadowShockCombinations( k, j + 1, i ) = CurrentNumParams;
                ShadowShockCombination = dynareOBC_.ShadowShockCombinations( k, : );
                if sum( ShadowShockCombination > 0 ) == 1
                    parameterValues{ end + 1 } = [ parameterName '=' seps_string ';' ];
                else
                    parameterValues{ end + 1 } = [ parameterName '=0;' ];
                end
                NewEq2 = [ NewEq2 '+' parameterName ];
                ShockMeanOne = true;
                for l = 1 : length( ShadowShockCombination )
                    varexoCurrent = [ 'dynareOBCEps' string_i '_' string_j '_' int2str( l ) ];
                    ShockPower = ShadowShockCombination( l );
                    if mod( ShockPower, 2 ) == 1
                        ShockMeanOne = false;
                    end
                    for m = 1 : ShockPower
                        NewEq2 = [ NewEq2 '*' varexoCurrent ];
                    end
                end
                if ShockMeanOne
                    NewEq2 = [ NewEq2 '-' parameterName ];
                end
            end
            NewEq2 = [ NewEq2 ';' ];
            ToInsertInModelAtEnd{ end + 1 } = NewEq2;
            ToInsertInModelAtEnd{ end + 1 } = NewEq;
        end
        varexoString = [ varexoString ';' ];
        varString = [ varString ';' ];
        if isempty( parametersString )
            ToInsertBeforeModel = [ ToInsertBeforeModel parameterValues { varexoString, varString } ];
        else
            parametersString = [ 'parameters' parametersString ';' ];
            ToInsertBeforeModel = [ ToInsertBeforeModel { parametersString } parameterValues { varexoString, varString } ];
        end
    end
    
    % dynareOBC_.VarExoIndices_ShadowShocks_Slice = shiftdim( dynareOBC_.VarExoIndices_ShadowShocks( 1, :, : ), 1 );
    % dynareOBC_.ParameterIndices_ShadowShockCombinations_Slice = shiftdim( dynareOBC_.ParameterIndices_ShadowShockCombinations( 1, :, : ), 1 );
end
