function [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInInitVal, dynareOBC ] = InsertShadowEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInInitVal, MaxArgValues, CurrentNumVar, dynareOBC, GlobalApproximationParameters, AmpValues )

    %T = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    dynareOBC.VarIndices_ZeroLowerBounded = zeros( 1, ns );
    if dynareOBC.Global
        dynareOBC.VarIndices_ZeroLowerBoundedLongRun = zeros( 1, ns );
    else
        dynareOBC.VarIndices_ZeroLowerBoundedLongRun = [];
    end
    
    for i = 1 : ns
        string_i = int2str( i );
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
        
        ToInsertInModelAtEnd{ end + 1 } = [ BoundedVarName '=(1-dynareOBCFlipParameter' string_i ')*(dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ')+dynareOBCFlipParameter' string_i '*(dynareOBCMaxArg' MinLetter string_i '-dynareOBCMaxArg' MaxLetter string_i ');' ]; %#ok<*AGROW> % '+dynareOBCSum' string_i '_0;'
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
            ToInsertInModelAtEnd{ end + 1 } = [ LongRunBoundedVarName '=' int2str( AmpValues( i ) ) '*(dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ')' PolynomialApproximationString ';' ];% '+dynareOBCSum' string_i '_0;' ]; %#ok<*AGROW>
            ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e%s;', LongRunBoundedVarName, SteadyStateBoundedVar, regexprep( PolynomialApproximationString, '\([+-]?\d+\)', '' ) );
        end
       
        if dynareOBC.Global
            BoundedVarName = LongRunBoundedVarName;
        end
        
        FileLines{ dynareOBC.MaxFuncIndices( i ) } = [ '#dynareOBCMaxFunc' string_i '=(1-dynareOBCFlipParameter' string_i ')*dynareOBCMaxArg' MinLetter string_i '+dynareOBCFlipParameter' string_i '*dynareOBCMaxArg' MaxLetter string_i '+' BoundedVarName ';' ];
 
        varString = [ varString ';' ];
        ToInsertBeforeModel = [ ToInsertBeforeModel { varString } ];
    end
    
end
