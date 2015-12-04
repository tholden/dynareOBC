function dynareOBC = InitialChecks( dynareOBC )
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    if ns == 0
        return
    end

    Ms = dynareOBC.MsMatrix;
    
    varsigma = sdpvar( 1, 1 );
    y = sdpvar( Ts * ns, 1 );
    
    MsScale = 1e4 ./ norm( Ms, Inf );
    scaledMs = MsScale * Ms;
    
    Constraints = [ 0 <= y, y <= 1, varsigma <= scaledMs * y ];
    Objective = -varsigma;
    Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );
    
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
    end
    
    vy = value( y );
    vy = max( 0, vy ./ max( 1, max( vy ) ) );
    new_varsigma = min( scaledMs * vy );

    AltConstraints = [ 0 <= y, y <= 1, y' * scaledMs <= 0 ];
    AltObjective = -ones( 1, Ts * ns ) * y;
    AltDiagnostics = optimize( AltConstraints, AltObjective, dynareOBC.LPOptions );

    if AltDiagnostics.problem ~= 0
        warning( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' AltDiagnostics.info ] );
        new_sum_y = 0;
    else
        vy = value( y );
        vy = max( 0, vy ./ max( 1, max( vy ) ) );
        new_sum_y = sum( vy );
    end
    
    ptestVal = 0;

    vvarsigma = value( varsigma );
    if new_varsigma > 0 % && new_sum_y <= 1e-6
        fprintf( 1, '\n' );
        disp( 'M is an S matrix, so the LCP is always feasible. This is a necessary condition for there to always be a solution.' );
        disp( 'varsigma bounds:' );
        disp( [ new_varsigma vvarsigma ] );
        disp( 'sum of y from the alternative problem:' );
        disp( new_sum_y );
        fprintf( 1, '\n' );
        SkipUpperBound = true;
    elseif new_varsigma <= 1e-6 && new_sum_y > 0
        fprintf( 1, '\n' );
        disp( 'M is not an S matrix, so there are some q for which the LCP (q,M) has no solution.' );
        disp( 'varsigma bounds:' );
        disp( [ new_varsigma vvarsigma ] );
        disp( 'sum of y from the alternative problem:' );
        disp( new_sum_y );
        fprintf( 1, '\n' );
        ptestVal = -1;
        if new_sum_y == 0
            warning( 'dynareOBC:InconsistentSResults', 'The alternative test suggests that M is an S matrix. Results cannot be trusted. This may be caused by numerical inaccuracies.' );
        end
        SkipUpperBound = false;
    else
        fprintf( 1, '\n' );
        disp( 'Due to numerical inaccuracies, we cannot tell if M is an S matrix.' );
        disp( 'varsigma bounds:' );
        disp( [ new_varsigma vvarsigma ] );
        disp( 'sum of y from the alternative problem:' );
        disp( new_sum_y );
        fprintf( 1, '\n' );
        SkipUpperBound = true;
    end

    if isempty( dynareOBC.d0s )
        disp( 'Skipping tests of feasibility with arbitrarily large T (TimeToEscapeBounds).' );
    else
        disp( 'Performing tests of feasibility with arbitrarily large T (TimeToEscapeBounds).' );
        disp( 'To skip this run dynareOBC with the FeasibilityTestGridSize=0 option.' );

        FTGC = dynareOBC.FeasibilityTestGridSize;
        
        NormInvIMinusF = dynareOBC.NormInvIMinusF;
        Norm_d0 = dynareOBC.Norm_d0;
        InvIMinusHd0s = dynareOBC.InvIMinusHd0s;
        InvIMinusHdPs = dynareOBC.InvIMinusHdPs;
        InvIMinusFdNs = dynareOBC.InvIMinusFdNs;
        dNs = dynareOBC.dNs;

        rhoF = dynareOBC.rhoF;
        rhoG = dynareOBC.rhoG;
        CF = dynareOBC.CF;
        CH = dynareOBC.CH;
        D = dynareOBC.D;

        yInf = sdpvar( ns, 1 );

        LBConstraints0 = [ 0 <= y, y <= 1, 0 <= yInf, yInf <= 1 ];
        UBConstraints0 = [ 0 <= y, y <= 1 ];

        tmp = ones( 1, ns ) * Ts;
        CellMs = mat2cell( Ms, tmp, tmp );
        
        LBInfiniteSCondition = false;
        UBInfiniteSCondition = false;

        for i = 1 : FTGC
            for j = 1 : FTGC
                rhoFC = rhoF( i );
                rhoGC = rhoG( j );
                CFC = CF( i );
                CHC = CH( i );
                DC = D( i, j );

                rhoFCv = rhoFC .^ ( ( 1:Ts )' );
                rhoGCv = rhoGC .^ ( ( 1:Ts )' );

                dSumIndices = bsxfun( @plus, ( 1:Ts )', (Ts-1):-1:0 );

                DenomFG = 1 ./ ( 1 - rhoFC * rhoGC );
                DenomF = 1 ./ ( 1 - rhoFC );
                DenomG = 1 ./ ( 1 - rhoGC );
                DenomFG_G = DenomFG * DenomG;

                LBConstraints = [];
                UBConstraints = [];
                for ConVar = 1 : ns % row index
                    LBMinimand1 = zeros( Ts, 1 );
                    LBMinimand2 = zeros( Ts, 1 );
                    LBMinimand3 = 0;
                    UBMinimand = zeros( Ts, 1 );
                    for ConShock = 1 : ns % column index
                        yC = y( ( 1:Ts ) + ( ConShock - 1 ) * Ts );
                        yInfC = yInf( ConShock );
                        Norm_d0C = Norm_d0( ConShock );
                        InvIMinusHd0sC = InvIMinusHd0s( ConVar, ConShock );
                        InvIMinusHdPsC = squeeze( InvIMinusHdPs( ConVar, ConShock, : ) );
                        InvIMinusFdNsC = squeeze( InvIMinusFdNs( ConVar, ConShock, : ) );
                        dNsC = squeeze( dNs( ConVar, ConShock, : ) );

                        LBMinimand1 = LBMinimand1 + CellMs{ ConVar, ConShock } * yC + InvIMinusHdPsC( Ts:-1:1 ) * yInfC - DC * rhoFCv * rhoGC * rhoGCv( end ) * DenomFG_G * yInfC;
                        LBMinimand2 = LBMinimand2 + ( dNsC( dSumIndices ) - DC / DenomFG * rhoFCv( end ) * rhoFCv * rhoGCv' ) * yC + ( InvIMinusFdNsC( 1 ) - InvIMinusFdNsC( 1:Ts ) ) * yInfC + InvIMinusHd0sC * yInfC - DC * rhoFCv * rhoFCv( end ) * rhoGC * rhoGCv( end ) * DenomFG_G * yInfC;
                        LBMinimand3 = LBMinimand3 - CFC * DenomF * rhoFC * rhoFCv( end ) * ( 1 - rhoFCv( end ) ) * Norm_d0C - CFC * rhoFC * rhoFCv( end ) * NormInvIMinusF * Norm_d0C * yInfC + InvIMinusFdNsC( 1 ) * yInfC + InvIMinusHd0sC * yInfC - DC * rhoFC * rhoFCv( end ) * rhoFCv( end ) * rhoGC * DenomFG_G;
                        
                        UBMinimand = UBMinimand + CellMs{ ConVar, ConShock } * yC + CHC * Norm_d0C * DenomG * rhoGCv( Ts:-1:1 ) + DC * rhoFCv * rhoGC * rhoGCv( end ) * DenomFG_G;
                    end
                    LBConstraints = [ LBConstraints; LBMinimand1; LBMinimand2; LBMinimand3 ]; %#ok<AGROW>
                    UBConstraints = [ UBConstraints; UBMinimand ]; %#ok<AGROW>
                end
                Diagnostics = optimize( [ LBConstraints0, varsigma <= LBConstraints ], Objective, dynareOBC.LPOptions );

                if Diagnostics.problem ~= 0
                    error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                end

                vvarsigma = value( varsigma );
                vy = value( y );
                vy = max( 0, vy ./ max( 1, max( vy ) ) );
                assign( y, vy );
                new_varsigma = min( value( LBConstraints ) );
                
                if new_varsigma > 0
                    fprintf( 1, '\n' );
                    disp( 'M is an S matrix for all sufficiently large T, so the LCP is always feasible for sufficiently large T.' );
                    disp( 'This is a necessary condition for there to always be a solution.' );
                    disp( 'phiF:' );
                    disp( rhoFC );
                    disp( 'phiG:' );
                    disp( rhoGC );
                    disp( 'varsigma lower bound, bounds:' );
                    disp( [ new_varsigma vvarsigma ] );
                    fprintf( 1, '\n' );
                    LBInfiniteSCondition = true;
                    break;
                end
                
                if ~SkipUpperBound
                    Diagnostics = optimize( [ UBConstraints0, varsigma <= UBConstraints ], Objective, dynareOBC.LPOptions );

                    if Diagnostics.problem ~= 0
                        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                    end

                    if value( varsigma ) <= 0
                        fprintf( 1, '\n' );
                        disp( 'M is neither an S matrix nor a P matrix for all sufficiently large T, so the LCP is sometimes non-feasible for sufficiently large T.' );
                        disp( 'The model does not always posess a solution.' );
                        disp( 'phiF:' );
                        disp( rhoFC );
                        disp( 'phiG:' );
                        disp( rhoGC );
                        disp( 'varsigma upper bound:' );
                        disp( value( varsigma ) );
                        fprintf( 1, '\n' );
                        UBInfiniteSCondition = true;
                        break;
                    end
                end
            end
            if LBInfiniteSCondition || UBInfiniteSCondition
                break;
            end
        end

        if ~LBInfiniteSCondition && ~UBInfiniteSCondition
            fprintf( 1, '\n' );
            disp( 'M did not pass either the sufficient condition to be an S matrix for all sufficiently large T, or the sufficient condition to not be an S matrix for all sufficiently large T.' );
            disp( 'To discover the properties of M, try reruning with higher TimeToEscapeBounds.' );
            fprintf( 1, '\n' );
        end
    end
    fprintf( 1, '\n' );
    
    
    global ptest_use_mex

    if ptestVal >= 0
        AbsArguments = abs( angle( eig( Ms ) ) );

        if all( AbsArguments < pi - pi / size( Ms, 1 ) )
            disp( 'Necessary condition for M to be a P-matrix is satisfied.' );
            disp( 'pi - pi / T - max( abs( angle( eig( M ) ) ) ):' );
            disp( pi - pi / size( Ms, 1 ) - max( AbsArguments ) );
            if dynareOBC.PTest == 0
                disp( 'Skipping the full P test, thus we cannot know whether there may be multiple solutions.' );
                disp( 'To run the full P test, run dynareOBC again with PTest=INTEGER where INTEGER>0.' );
            else
                TM = dynareOBC.PTest;

                T = min( TM, Ts );
                Indices = bsxfun( @plus, (1:T)', int64( 0 ):Ts:((ns-1)*Ts ) );
                Indices = Indices(:);
                M = dynareOBC.MMatrix( Indices, Indices );                
                if ptest_use_mex
                    disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the MEX version of ptest.' );
                    if ptest_mex( M )
                        ptestVal = 1;
                    else
                        ptestVal = -1;
                    end
                else
                    disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the non-MEX version of ptest.' );
                    if ptest( M )
                        ptestVal = 1;
                    else
                        ptestVal = -1;
                    end
                end
            end
        else
            disp( 'Necessary condition for M to be a P-matrix is not satisfied.' );
            disp( 'pi - pi / T - max( abs( angle( eig( M ) ) ) ):' );
            disp( pi - pi / size( Ms, 1 ) - max( AbsArguments ) );
            ptestVal = -1;
        end
    end
    if ptestVal > 0
        disp( [ 'M is a P-matrix. There is a unique solution to the model, conditional on the bound binding for at most ' int2str( dynareOBC.TimeToEscapeBounds ) ' periods.' ] );
        if ptest_use_mex
            DiagIsP = ptest_mex( dynareOBC.d0s );
        else
            DiagIsP = ptest( dynareOBC.d0s );
        end
        if DiagIsP
            disp( 'A weak necessary condition for M to be a P-matrix with arbitrarily large T (TimeToEscapeBounds) is satisfied.' );
        else
            disp( 'A weak necessary condition for M to be a P-matrix with arbitrarily large T (TimeToEscapeBounds) is not satisfied.' );
            disp( 'Thus, for sufficiently large T, M is not a P matrix. There are multiple solutions to the model in at least some states of the world.' );
            disp( 'However, due to your low choice of TimeToEscapeBounds, DynareOBC will only ever find one of these multiple solutions.' );
        end
    elseif ptestVal < 0
        disp( 'M is not a P-matrix. There are multiple solutions to the model in at least some states of the world.' );
        disp( 'The one returned will depend on the chosen value of omega.' );
    end
    fprintf( 1, '\n' );
    
    if dynareOBC.FullTest > 0
        fprintf( 1, '\n' );
        disp( 'Running full test to see if the requested sub-matrix of M is a P and/or (strictly) semi-monotone matrix.' );
        fprintf( 1, '\n' );
        [ MinimumDeterminant, MinimumS, MinimumS0 ] = FullTest( dynareOBC.FullTest, dynareOBC );
        if MinimumDeterminant >= 1e-8
            disp( [ MFTS ' is a P-matrix.' ] );
        else
            disp( [ MFTS ' is not a P-matrix.' ] );
        end
        if MinimumS >= 1e-8
            disp( [ MFTS ' is a strictly semi-monotone matrix.' ] );
        else
            disp( [ MFTS ' is not a strictly semi-monotone matrix.' ] );
        end
        if MinimumS0 >= 1e-8
            disp( [ MFTS ' is a semi-monotone matrix.' ] );
        else
            disp( [ MFTS ' is not a semi-monotone matrix.' ] );
        end        
    end
    
    dynareOBC.ssIndices = cell( Ts, 1 );
    dynareOBC.ParametricSolutionFound = zeros( Ts, 1 );
    SkipCalcs = false;

    OpenPool;
    for Tss = 1 : Ts
        ssIndices = vec( bsxfun( @plus, (1:Tss)', 0:Ts:((ns-1)*Ts) ) )';
        Mss = Ms( ssIndices, ssIndices );
        
        dynareOBC.ssIndices{ Tss } = ssIndices;

        if SkipCalcs || Tss > dynareOBC.TimeToSolveParametrically || min( eig( Mss + Mss' ) ) < sqrt( eps )
            SkipCalcs = true;
            continue;
        end
        
        PLCP = struct;
        PLCP.M = Mss;
        PLCP.q = zeros( Tss, 1 );
        PLCP.Q = eye( Tss );
        PLCP.Ath = [ eye( Tss ); -eye( Tss ) ];
        PLCP.bth = ones( 2 * Tss, 1 );

        fprintf( 1, '\n' );
        disp( 'Solving for a parametric solution over the requested domain.' );
        fprintf( 1, '\n' );
         try
            ParametricSolution = mpt_plcp( Opt( PLCP ) );
            if ParametricSolution.exitflag == 1
                try
                    ParametricSolution.xopt.toC( 'z', 'dynareOBCTempSolution' );
                    mex dynareOBCTempSolution_mex.c;
                    dynareOBC.ParametricSolutionFound( Tss ) = 2;
                catch
                    try
                        ParametricSolution.xopt.toMatlab( 'dynareOBCTempSolution', 'z', 'first-region' );
                        dynareOBC.ParametricSolutionFound( Tss ) = 1;
                    catch
                        SkipCalcs = true;
                        continue;
                    end
                end
            end
        catch
            SkipCalcs = true;
            continue;
        end
    end
    if sum( dynareOBC.ParametricSolutionFound ) > 0
        rehash;
    end
    
    yalmip( 'clear' );
end
