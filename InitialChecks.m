function dynareOBC_ = InitialChecks( dynareOBC_ )
    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
    
    dynareOBC_.ZeroVecS = sparse( Ts * ns, 1 );
    dynareOBC_.ZeroVecL = sparse( T * ns, 1 );
    dynareOBC_.OneVecS = ones( Ts * ns, 1 );
    dynareOBC_.OneVecL = ones( T * ns, 1 );
    dynareOBC_.TVecS = ( 1 : ( Ts * ns ) )';
    dynareOBC_.TVecL = ( 1 : ( T * ns ) )';
    dynareOBC_.EyeS = speye( Ts * ns, Ts * ns );
    dynareOBC_.ZeroMatrixS = sparse( Ts * ns, Ts * ns );

    dynareOBC_.RowType = repmat( 'L', 1, T );
    
    if ns == 0
        return
    end

    Tolerance = dynareOBC_.Tolerance;
    
    dynareOBC_ = SetDefaultOption( dynareOBC_, 'LinProgOptions',  optimset( 'display', 'off', 'Algorithm', 'simplex',        'MaxIter', 20 * Ts * ns, 'MaxFunEvals', 10 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance ) );
    dynareOBC_ = SetDefaultOption( dynareOBC_, 'QuadProgOptions', optimset( 'display', 'off', 'Algorithm', 'active-set',     'MaxIter', 40 * Ts * ns, 'MaxFunEvals', 20 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance ) ); % 'trust-region-reflective'
    dynareOBC_ = SetDefaultOption( dynareOBC_, 'FMinConOptions',  optimset( 'display', 'off', 'Algorithm', 'interior-point', 'MaxIter', 80 * Ts * ns, 'MaxFunEvals', 40 * Ts * ns, 'TolFun', Tolerance, 'TolX', Tolerance, 'TolCon', Tolerance, 'TolConSQP', Tolerance, 'DerivativeCheck', 'off', 'GradConstr', 'on', 'GradObj', 'on', 'Hessian', 'user-supplied' ) ); % 'sqp'
    
    CompVec = false( T * ns, 1 );
    GuaranteedHorizon = 0;
    dynareOBC_ = SetDefaultOption( dynareOBC_, 'AlphaStart', dynareOBC_.ZeroVecS );

    for GH = 1 : T
        CompVec( GH + ( 0:(ns-1) ) * T ) = true;
        WarningState = warning( 'off', 'all' );
        try
            AlphaStart = SolveLinearProgrammingProblem( -double( CompVec ), dynareOBC_, false, false );
        catch Error
            AlphaStart = dynareOBC_.AlphaStart;
            disp( Error );
        end
        warning( WarningState );
        if ( min( dynareOBC_.MMatrix( CompVec, : ) * AlphaStart ) < 1-Tolerance ) || ( min( dynareOBC_.MMatrix * AlphaStart ) < -Tolerance )
            FoundFromLPP = false;
        else
            FoundFromLPP = true;
            dynareOBC_.AlphaStart = AlphaStart;
            GuaranteedHorizon = GH;
        end
        WarningState = warning( 'off', 'all' );
        try
            AlphaStart = SolveBoundsProblem( -double( CompVec ), dynareOBC_ );
        catch Error
            AlphaStart = dynareOBC_.AlphaStart;
            disp( Error );
            for i = 1 : length( Error.stack )
                disp( Error.stack( i ) );
            end
        end
        warning( WarningState );
        if ( min( dynareOBC_.MMatrix( CompVec, : ) * AlphaStart ) < 1-Tolerance ) || ( min( dynareOBC_.MMatrix * AlphaStart ) < -Tolerance )
            if ~FoundFromLPP
                warning( 'dynareOBC:AlphaStart', [ 'There is only a guaranteed solution to the linear programming problem when the ZLB binds for at most ' int2str( GuaranteedHorizon ) ' periods.' ] );
                break;
            end
        else
            dynareOBC_.AlphaStart = AlphaStart;
            GuaranteedHorizon = GH;
        end
    end
    
    dynareOBC_.AlphaStart = full( dynareOBC_.AlphaStart );

    dynareOBC_.GuaranteedHorizon = GuaranteedHorizon;

    dynareOBC_.MinEigenValue = min( eig( dynareOBC_.MsMatrixSymmetric ) );
    if dynareOBC_.MinEigenValue > 0 && dynareOBC_.Algorithm > 1
        warning( 'dynareOBC:HighMinEigenValue', 'The minimum eigenvalue of M*+M*'' is positive, thus there is a unique solution to the model, so there is no need to use the slower options algorithm=2 or algorithm=3.' );
    end
    if dynareOBC_.MinEigenValue < 0 && dynareOBC_.Algorithm == 0
        warning( 'dynareOBC:LowMinEigenValue', 'The minimum eigenvalue of M*+M*'' is negative, thus there may be multiple solutions to the model. You should perhaps consider using algorithm=2 or algorithm=3 to pin down a particular solution.' );
    end
end

