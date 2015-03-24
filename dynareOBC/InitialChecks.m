function dynareOBC = InitialChecks( dynareOBC )
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    dynareOBC.ZeroVecS = sparse( Ts * ns, 1 );
    dynareOBC.ZeroVecL = sparse( T * ns, 1 );
    dynareOBC.OneVecS = ones( Ts * ns, 1 );
    dynareOBC.OneVecL = ones( T * ns, 1 );
    dynareOBC.TVecS = ( 1 : ( Ts * ns ) )';
    dynareOBC.TVecL = ( 1 : ( T * ns ) )';
    dynareOBC.EyeS = speye( Ts * ns, Ts * ns );
    dynareOBC.ZeroMatrixS = sparse( Ts * ns, Ts * ns );

    dynareOBC.RowType = repmat( 'L', 1, T );
    
    if ns == 0
        return
    end

    Tolerance = dynareOBC.Tolerance;
    
    dynareOBC = SetDefaultOption( dynareOBC, 'LinProgOptions',  optimset( 'display', 'off', 'Algorithm', 'simplex',        'MaxIter', 20 * Ts * ns, 'MaxFunEvals', 10 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance ) );
    dynareOBC = SetDefaultOption( dynareOBC, 'QuadProgOptions', optimset( 'display', 'off', 'Algorithm', 'active-set',     'MaxIter', 40 * Ts * ns, 'MaxFunEvals', 20 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance ) ); % 'trust-region-reflective'
    dynareOBC = SetDefaultOption( dynareOBC, 'LSqLinOptions',   optimset( 'display', 'off', 'Algorithm', 'active-set',     'MaxIter', 40 * Ts * ns, 'MaxFunEvals', 20 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance, 'LargeScale', 'off' ) ); % 'trust-region-reflective'
    dynareOBC = SetDefaultOption( dynareOBC, 'FMinConOptions',  optimset( 'display', 'off', 'Algorithm', 'interior-point', 'MaxIter', 80 * Ts * ns, 'MaxFunEvals', 40 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance, 'TolConSQP', Tolerance, 'DerivativeCheck', 'off', 'GradConstr', 'on', 'GradObj', 'on', 'Hessian', 'user-supplied' ) ); % 'sqp'
    
    CompVec = false( T * ns, 1 );
    GuaranteedHorizon = 0;
    dynareOBC = SetDefaultOption( dynareOBC, 'AlphaStart', dynareOBC.ZeroVecS );

    for GH = 1 : T
        CompVec( GH + ( 0:(ns-1) ) * T ) = true;
        WarningState = warning( 'off', 'all' );
        try
            AlphaStart = SolveLinearProgrammingProblem( -double( CompVec ), dynareOBC, false, false );
        catch Error
            AlphaStart = dynareOBC.AlphaStart;
            disp( Error );
        end
        warning( WarningState );
        if ( min( dynareOBC.MMatrix( CompVec, : ) * AlphaStart ) < 1-Tolerance ) || ( min( dynareOBC.MMatrix * AlphaStart ) < -Tolerance )
            FoundFromLPP = false;
        else
            FoundFromLPP = true;
            dynareOBC.AlphaStart = AlphaStart;
            GuaranteedHorizon = GH;
        end
        WarningState = warning( 'off', 'all' );
        try
            AlphaStart = SolveBoundsProblem( -double( CompVec ), dynareOBC );
        catch Error
            AlphaStart = dynareOBC.AlphaStart;
            disp( Error );
            for i = 1 : length( Error.stack )
                disp( Error.stack( i ) );
            end
        end
        warning( WarningState );
        if ( min( dynareOBC.MMatrix( CompVec, : ) * AlphaStart ) < 1-Tolerance ) || ( min( dynareOBC.MMatrix * AlphaStart ) < -Tolerance )
            if ~FoundFromLPP
                warning( 'dynareOBC:AlphaStart', [ 'There is only a guaranteed solution to the linear programming problem when the ZLB binds for at most ' int2str( GuaranteedHorizon ) ' periods.' ] );
                break;
            end
        else
            dynareOBC.AlphaStart = AlphaStart;
            GuaranteedHorizon = GH;
        end
    end
    
    dynareOBC.AlphaStart = full( dynareOBC.AlphaStart );

    dynareOBC.GuaranteedHorizon = GuaranteedHorizon;

    dynareOBC.MinEigenValue = min( eig( dynareOBC.MsMatrixSymmetric ) );
    if dynareOBC.MinEigenValue > 0 && dynareOBC.Algorithm > 1
        warning( 'dynareOBC:HighMinEigenValue', 'The minimum eigenvalue of M*+M*'' is positive, thus there is a unique solution to the model, so there is no need to use the slower options algorithm=2 or algorithm=3.' );
    end
    if dynareOBC.MinEigenValue < 0 && dynareOBC.Algorithm == 0
        warning( 'dynareOBC:LowMinEigenValue', 'The minimum eigenvalue of M*+M*'' is negative, thus there may be multiple solutions to the model. You should perhaps consider using algorithm=2 or algorithm=3 to pin down a particular solution.' );
    end
end

